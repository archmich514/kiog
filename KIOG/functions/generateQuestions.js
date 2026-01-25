const admin = require("firebase-admin");
const { generateAIQuestion } = require("./generateAIQuestion");

// 遅延初期化（index.jsでinitializeApp()が呼ばれた後に使用される）
function getDb() {
  return admin.firestore();
}

// 全UNITに質問を生成
async function generateQuestionsForAllUnits(timeSlot) {
  console.log(`Generating ${timeSlot} questions for all units...`);

  // アクティブなUNITを取得
  const unitsSnapshot = await getDb().collection("units").get();

  for (const unitDoc of unitsSnapshot.docs) {
    const unitId = unitDoc.id;
    const memberIds = unitDoc.data().members || [];

    try {
      // 質問を生成
      const questions = await generateQuestionsForUnit(unitId, timeSlot);

      // currentQuestionsに保存
      await getDb().collection("currentQuestions").doc(unitId).set({
        questions: questions,
        timeSlot: timeSlot,
        date: getToday(),
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      // 通知送信
      await sendQuestionNotification(memberIds);

      console.log(`Questions generated for unit ${unitId}`);
    } catch (error) {
      console.error(`Failed to generate questions for unit ${unitId}:`, error);
    }
  }
}

// 特定UNITの質問を生成
async function generateQuestionsForUnit(unitId, timeSlot) {
  const questions = [];

  // マスターから2問選出
  const masterQuestions = await selectFromMaster(unitId, timeSlot, 2);
  questions.push(...masterQuestions);

  // 前日のレポートを確認
  const yesterdayReport = await getYesterdayReport(unitId);

  if (yesterdayReport) {
    try {
      // AIで1問生成
      const aiQuestionText = await generateAIQuestion(yesterdayReport.content, timeSlot);
      questions.push({
        id: null,
        text: aiQuestionText,
        isAI: true
      });
      console.log(`AI question generated for unit ${unitId}`);
    } catch (error) {
      console.error(`Failed to generate AI question for unit ${unitId}:`, error);
    }
  }

  return questions;
}

// マスターから質問を選出
async function selectFromMaster(unitId, timeSlot, count) {
  // 該当時間帯の質問を取得
  const questionsSnapshot = await getDb().collection("questions")
    .where("timeSlot", "==", timeSlot)
    .get();

  // 表示回数を取得
  const statsDoc = await getDb().collection("questionStats").doc(unitId).get();
  const stats = statsDoc.exists ? statsDoc.data()[timeSlot] || {} : {};

  // 表示回数が少ない順にソート
  const sortedQuestions = questionsSnapshot.docs
    .map(doc => ({
      id: doc.id,
      text: doc.data().text,
      count: stats[doc.id] || 0
    }))
    .sort((a, b) => a.count - b.count);

  // 上位から選出
  const selected = sortedQuestions.slice(0, count).map(q => ({
    id: q.id,
    text: q.text,
    isAI: false
  }));

  // 表示回数を更新
  const updates = {};
  selected.forEach(q => {
    updates[`${timeSlot}.${q.id}`] = (stats[q.id] || 0) + 1;
  });

  // 20問を1周したかチェック
  const allShown = sortedQuestions.every(q => (stats[q.id] || 0) >= 1);
  if (allShown) {
    // カウントをリセット
    const resetUpdates = {};
    sortedQuestions.forEach(q => {
      resetUpdates[`${timeSlot}.${q.id}`] = 0;
    });
    // 選出した質問のカウントは1に
    selected.forEach(q => {
      resetUpdates[`${timeSlot}.${q.id}`] = 1;
    });
    await getDb().collection("questionStats").doc(unitId).set(resetUpdates, { merge: true });
  } else {
    await getDb().collection("questionStats").doc(unitId).set(updates, { merge: true });
  }

  return selected;
}

// 前日のレポートを取得
async function getYesterdayReport(unitId) {
  const yesterday = getYesterday();

  const reportSnapshot = await getDb().collection("reports")
    .where("unitId", "==", unitId)
    .where("date", "==", yesterday)
    .limit(1)
    .get();

  if (reportSnapshot.empty) {
    return null;
  }

  return reportSnapshot.docs[0].data();
}

// 通知送信
async function sendQuestionNotification(memberIds) {
  for (const memberId of memberIds) {
    try {
      const userDoc = await getDb().collection("users").doc(memberId).get();
      const fcmToken = userDoc.data()?.fcmToken;

      if (fcmToken) {
        await admin.messaging().send({
          notification: {
            title: "QUEの時間だよ"
          },
          token: fcmToken
        });
      }
    } catch (error) {
      console.error(`Failed to send notification to ${memberId}:`, error);
    }
  }
}

// 今日の日付を取得（YYYY-MM-DD形式）
function getToday() {
  const now = new Date();
  const jst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  return jst.toISOString().split("T")[0];
}

// 昨日の日付を取得（YYYY-MM-DD形式）
function getYesterday() {
  const now = new Date();
  const jst = new Date(now.getTime() + 9 * 60 * 60 * 1000);
  jst.setDate(jst.getDate() - 1);
  return jst.toISOString().split("T")[0];
}

module.exports = {
  generateQuestionsForAllUnits,
  generateQuestionsForUnit,
  selectFromMaster,
  getYesterdayReport
};
