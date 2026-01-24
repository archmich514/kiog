const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { transcribeAudio } = require("./transcribe");
const { generateReport } = require("./generateReport");
const { sendReportNotification } = require("./notify");
const { generateQuestionsForAllUnits } = require("./generateQuestions");
const { handleAnswerCreated } = require("./onAnswerCreated");

admin.initializeApp();

const db = admin.firestore();
const storage = admin.storage();

// 毎日23時に実行（日本時間）
exports.scheduledGenerateReport = functions
  .runWith({
    secrets: ["GEMINI_API_KEY", "CLAUDE_API_KEY"],
    timeoutSeconds: 540,
    memory: "1GB"
  })
  .pubsub.schedule("0 23 * * *")
  .timeZone("Asia/Tokyo")
  .onRun(async (context) => {
    await generateDailyReports();
    return null;
  });

// デバッグ用：即時実行（HTTPトリガー）
exports.debugGenerateReport = functions
  .runWith({
    secrets: ["GEMINI_API_KEY", "CLAUDE_API_KEY"],
    timeoutSeconds: 540,
    memory: "1GB"
  })
  .https.onCall(async (data, context) => {
    const { unitId } = data;

    if (!unitId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "unitId is required"
      );
    }

    await generateReportForUnit(unitId, true);
    return { success: true };
  });

// 全UNITのレポート生成
async function generateDailyReports() {
  const today = getToday();

  // 今日アップロードされた録音があるUNITを取得
  const recordingsSnapshot = await db
    .collection("recordings")
    .where("status", "==", "uploaded")
    .get();

  const unitIds = [...new Set(
    recordingsSnapshot.docs.map(doc => doc.data().unitId)
  )];

  console.log(`Found ${unitIds.length} units with recordings`);

  for (const unitId of unitIds) {
    try {
      await generateReportForUnit(unitId, false);
    } catch (error) {
      console.error(`Failed to generate report for unit ${unitId}:`, error);
    }
  }
}

// 特定UNITのレポート生成
async function generateReportForUnit(unitId, isDebug) {
  const today = getToday();

  // 当日の未処理録音を取得
  const recordingsSnapshot = await db
    .collection("recordings")
    .where("unitId", "==", unitId)
    .where("status", "==", "uploaded")
    .get();

  if (recordingsSnapshot.empty) {
    console.log(`No recordings for unit ${unitId}`);
    return;
  }

  console.log(`Processing ${recordingsSnapshot.size} recordings for unit ${unitId}`);

  // UNIT情報取得
  const unitDoc = await db.collection("units").doc(unitId).get();
  if (!unitDoc.exists) {
    console.error(`Unit ${unitId} not found`);
    return;
  }

  const unitData = unitDoc.data();
  const memberIds = unitData.members || [];

  // メンバー情報取得
  const members = [];
  for (const memberId of memberIds) {
    const userDoc = await db.collection("users").doc(memberId).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      members.push({
        id: memberId,
        name: userData.name || "不明",
        gender: userData.gender || "不明"
      });
    }
  }

  if (members.length === 0) {
    console.error(`No members found for unit ${unitId}`);
    return;
  }

  // 各録音を文字起こし
  const transcripts = [];
  const recordingIds = [];

  for (const doc of recordingsSnapshot.docs) {
    const recording = doc.data();
    recordingIds.push(doc.id);

    try {
      // Storage から音声ファイル取得
      const bucket = storage.bucket();
      const file = bucket.file(`recordings/${unitId}/${doc.id}.m4a`);
      const [audioBuffer] = await file.download();

      console.log(`Transcribing recording ${doc.id}...`);

      // Gemini で文字起こし
      const transcript = await transcribeAudio(audioBuffer, members);
      transcripts.push(transcript);

      // ステータス更新
      await doc.ref.update({
        status: "transcribed",
        transcript: transcript
      });

      console.log(`Transcription completed for ${doc.id}`);
    } catch (error) {
      console.error(`Failed to transcribe recording ${doc.id}:`, error);
      // エラーが発生しても続行
    }
  }

  if (transcripts.length === 0) {
    console.error(`No transcripts generated for unit ${unitId}`);
    return;
  }

  // 全文字起こしを結合
  const combinedTranscript = transcripts.join("\n\n---\n\n");

  console.log(`Generating report for unit ${unitId}...`);

  // 当日の質問回答を取得
  const answersSnapshot = await db.collection("answers")
    .where("unitId", "==", unitId)
    .where("date", "==", today)
    .get();

  const questionAnswers = formatQuestionAnswers(answersSnapshot.docs);

  // Claude でレポート生成
  const report = await generateReport(combinedTranscript, members);

  // レポート保存
  const reportRef = db.collection("reports").doc();
  await reportRef.set({
    unitId: unitId,
    date: today,
    content: report.content,
    tags: report.tags || [],
    recordingIds: recordingIds,
    questionAnswers: questionAnswers,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // 録音ステータスを reported に更新
  for (const recordingId of recordingIds) {
    await db.collection("recordings").doc(recordingId).update({
      status: "reported"
    });
  }

  // プッシュ通知送信
  await sendReportNotification(unitId, memberIds);

  // 通知日時を記録
  await reportRef.update({
    notifiedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  console.log(`Report generated successfully for unit ${unitId}`);
}

function getToday() {
  const now = new Date();
  const jst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  return jst.toISOString().split("T")[0];
}

// 質問回答をフォーマット
function formatQuestionAnswers(answerDocs) {
  // 質問ごとにグループ化
  const grouped = {};

  answerDocs.forEach(doc => {
    const data = doc.data();
    const questionText = data.questionText;

    if (!grouped[questionText]) {
      grouped[questionText] = {
        questionText: questionText,
        answers: []
      };
    }

    grouped[questionText].answers.push({
      userName: data.userName,
      answer: data.answer,
      predictions: data.predictions || []
    });
  });

  return Object.values(grouped);
}

// ============================================
// 質問生成 Cloud Functions（Phase 5）
// ============================================

// 朝の質問生成（8時）
exports.scheduledMorningQuestions = functions
  .runWith({
    secrets: ["CLAUDE_API_KEY"],
    timeoutSeconds: 300
  })
  .pubsub.schedule("0 8 * * *")
  .timeZone("Asia/Tokyo")
  .onRun(async (context) => {
    await generateQuestionsForAllUnits("morning");
    return null;
  });

// 午後の質問生成（15時）
exports.scheduledAfternoonQuestions = functions
  .runWith({
    secrets: ["CLAUDE_API_KEY"],
    timeoutSeconds: 300
  })
  .pubsub.schedule("0 15 * * *")
  .timeZone("Asia/Tokyo")
  .onRun(async (context) => {
    await generateQuestionsForAllUnits("afternoon");
    return null;
  });

// 夜の質問生成（22時）
exports.scheduledEveningQuestions = functions
  .runWith({
    secrets: ["CLAUDE_API_KEY"],
    timeoutSeconds: 300
  })
  .pubsub.schedule("0 22 * * *")
  .timeZone("Asia/Tokyo")
  .onRun(async (context) => {
    await generateQuestionsForAllUnits("evening");
    return null;
  });

// 回答作成時のトリガー
exports.onAnswerCreated = functions.firestore
  .document("answers/{answerId}")
  .onCreate(async (snap, context) => {
    await handleAnswerCreated(snap, context);
  });

// デバッグ用：質問生成を即時実行
exports.debugGenerateQuestions = functions
  .runWith({
    secrets: ["CLAUDE_API_KEY"],
    timeoutSeconds: 300
  })
  .https.onCall(async (data, context) => {
    const { timeSlot } = data;

    if (!timeSlot || !["morning", "afternoon", "evening"].includes(timeSlot)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "timeSlot must be 'morning', 'afternoon', or 'evening'"
      );
    }

    await generateQuestionsForAllUnits(timeSlot);
    return { success: true };
  });
