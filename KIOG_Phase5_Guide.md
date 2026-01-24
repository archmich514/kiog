# KIOG Phase 5: 質問・回答機能（QUE）依頼書

## 1. 概要

Phase 4で実装した文字起こし・レポート生成に、質問・回答機能を追加する。

### 今回のゴール
- 8時/15時/22時に質問を生成してUNITメンバーに通知
- ホーム画面で質問に回答できる
- パートナーの回答を「予想」してから見る機能
- 質問への回答をレポートに反映

---

## 2. 機能概要

### QUE（質問）とは
- QUE = 気づき
- 相手のことを知る・気づくための質問
- 1日3回（8時/15時/22時）届く

### フロー
```
【8時/15時/22時】質問生成ジョブ
    └─ 2〜3問の質問を生成 → UNIT全員に通知

【ユーザーA】
    └─ ホーム画面のQUEセクションで質問を見る
    └─ 1つ選んで回答
    └─ パートナー（B）に通知

【ユーザーB】
    └─ ホーム画面のANSセクションにAの回答が届く
    └─ 「Aは何と答えた？」を予想入力
    └─ 予想入力後、Aの実際の回答が見れる
```

---

## 3. 質問の仕様

### 3.1 質問数
- 各時間帯で **2〜3問** 表示
- 前日のレポートあり → 3問（マスター2問 + AI生成1問）
- 前日のレポートなし → 2問（マスター2問のみ）

### 3.2 質問マスター（60問）

**8時（朝）- 20問**

| ジャンル | 質問 |
|----------|------|
| 今日の予定 | 今日の予定で一番楽しみなことは？ |
| 今日の予定 | 今日やらなきゃいけないことは？ |
| 今日の予定 | 今日誰かに会う予定ある？ |
| 今日の予定 | 今日何時頃に帰ってくる？ |
| 気分・体調 | 今日の調子は何点？（10点満点） |
| 気分・体調 | 今朝の目覚めはどうだった？ |
| 気分・体調 | 今日のやる気を一言で表すと？ |
| 気分・体調 | 昨日ちゃんと眠れた？ |
| 今日の目標 | 今日ひとつだけ達成するなら何？ |
| 今日の目標 | 今日意識したいことは？ |
| 今日の目標 | 今日の仕事や家事で頑張りたいことは？ |
| 今日の目標 | 今日の自分に一言かけるなら？ |
| 食べたいもの | 今日の夜ごはん何がいい？ |
| 食べたいもの | 今日のランチ何食べる予定？ |
| 食べたいもの | 今食べたいものは？ |
| 食べたいもの | 今日のおやつ何がいい？ |
| パートナーへの感謝 | 最近パートナーにありがとうって思ったことは？ |
| パートナーへの感謝 | パートナーの好きなところをひとつ挙げるなら？ |
| パートナーへの感謝 | 最近パートナーがしてくれて嬉しかったことは？ |
| パートナーへの感謝 | パートナーに「さすが」って思ったことは？ |

**15時（午後）- 20問**

| ジャンル | 質問 |
|----------|------|
| 今の気分 | 今どんな気分？ |
| 今の気分 | 午後の疲れ具合は何点？（10点満点） |
| 今の気分 | 今のテンションを天気で表すと？ |
| 今の気分 | 今一番考えてることは？ |
| 息抜き | 今一番したいことは？ |
| 息抜き | 今すぐ休めるなら何する？ |
| 息抜き | 今飲みたいものは？ |
| 息抜き | あと何時間で仕事終わる？ |
| 妄想・願望 | 今すぐどこでもドアがあったらどこ行く？ |
| 妄想・願望 | 100万円もらったら何に使う？ |
| 妄想・願望 | 明日仕事休みになったら何する？ |
| 妄想・願望 | 今の気分で選ぶなら海と山どっち？ |
| 近い未来 | 次の休みにしたいことは？ |
| 近い未来 | 今週末どう過ごしたい？ |
| 近い未来 | 近いうちに食べに行きたいものは？ |
| 近い未来 | 次の連休どこか行きたい？ |
| 雑談ネタ | 最近気になってるものある？ |
| 雑談ネタ | 最近ハマってることは？ |
| 雑談ネタ | 今日あった小さな出来事は？ |
| 雑談ネタ | 最近見た動画や記事で面白かったのある？ |

**22時（夜）- 20問**

| ジャンル | 質問 |
|----------|------|
| 今日の小さな幸せ | 今日ちょっと嬉しかったことは？ |
| 今日の小さな幸せ | 今日「良かった」って思った瞬間は？ |
| 今日の小さな幸せ | 今日自分を褒めるなら何？ |
| 今日の小さな幸せ | 今日の小さなラッキーは？ |
| 五感・感覚系 | 好きな香りは？ |
| 五感・感覚系 | 落ち着く音は？ |
| 五感・感覚系 | 触り心地が好きなものは？ |
| 五感・感覚系 | 見てると癒されるものは？ |
| 今夜のこと | 寝る前に何する？ |
| 今夜のこと | 今夜見たい夢は？ |
| 今夜のこと | 今夜何時に寝る？ |
| 今夜のこと | 寝る前に食べたいものある？ |
| 好きなもの | 最近ハマってるお菓子は？ |
| 好きなもの | 最近ハマってるアイスは？ |
| 好きなもの | リラックスする時に何する？ |
| 好きなもの | 家で最近ハマってる場所は？ |
| 子供時代 | 子供の頃好きだった遊びは？ |
| 子供時代 | 子供の頃好きだった食べ物は？ |
| 子供時代 | 子供の頃の夢は何だった？ |
| 子供時代 | 子供の頃よく見てたテレビは？ |

### 3.3 質問選出ロジック
1. 時間帯に対応する質問マスターから選出
2. 表示回数が少ないものを優先
3. 20問を1周したらカウントリセット
4. 前日レポートがあれば、AIが1問追加生成

### 3.4 AI生成質問
- 前日のレポート内容を参照
- 会話の中から引用して質問を作成
- 例：「昨日『カレー食べたい』って言ってたけど、今日は何食べたい？」

---

## 4. データ構造

### 4.1 Firestore

```
firestore/
├── questions/                      # 質問マスタ（60問）
│   └── {questionId}/
│       ├── text: String            # 質問文
│       ├── timeSlot: String        # "morning" / "afternoon" / "evening"
│       └── category: String        # ジャンル名
│
├── questionStats/                  # 表示回数追跡（UNITごと）
│   └── {unitId}/
│       ├── morning: Map            # { questionId: 表示回数 }
│       ├── afternoon: Map
│       └── evening: Map
│
├── currentQuestions/               # 現在の質問（UNITごと）
│   └── {unitId}/
│       ├── questions: [            # 2〜3問
│       │     {
│       │       id: String | null,  # AI生成の場合はnull
│       │       text: String,
│       │       isAI: Boolean
│       │     }
│       │   ]
│       ├── timeSlot: String        # "morning" / "afternoon" / "evening"
│       ├── date: String            # "2026-01-24"
│       └── createdAt: Timestamp
│
├── answers/                        # 回答
│   └── {answerId}/
│       ├── unitId: String
│       ├── date: String
│       ├── timeSlot: String
│       ├── questionId: String?     # AI生成の場合はnull
│       ├── questionText: String
│       ├── userId: String          # 回答者
│       ├── userName: String
│       ├── answer: String
│       ├── isAIQuestion: Boolean
│       ├── createdAt: Timestamp
│       │
│       │  # 予想関連
│       ├── predictions: [
│       │     {
│       │       oderId: String,
│       │       predictorName: String,
│       │       prediction: String,
│       │       predictedAt: Timestamp
│       │     }
│       │   ]
│       └── viewedBy: [String]      # 予想入力済みのユーザーID
│
└── reports/                        # レポート（既存に追加）
    └── {reportId}/
        ├── ...（既存フィールド）
        └── questionAnswers: [      # 質問回答セクション用
              {
                questionText: String,
                answers: [
                  {
                    userName: String,
                    answer: String,
                    predictions: [
                      {
                        predictorName: String,
                        prediction: String
                      }
                    ]
                  }
                ]
              }
            ]
```

---

## 5. Cloud Functions

### 5.1 質問生成ジョブ（3つ）

**ファイル: `functions/generateQuestions.js`**

```javascript
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
```

### 5.2 質問生成ロジック

```javascript
async function generateQuestionsForAllUnits(timeSlot) {
  // 1. アクティブなUNITを取得
  const unitsSnapshot = await db.collection("units").get();
  
  for (const unitDoc of unitsSnapshot.docs) {
    const unitId = unitDoc.id;
    const memberIds = unitDoc.data().members || [];
    
    // 2. 質問を生成
    const questions = await generateQuestionsForUnit(unitId, timeSlot);
    
    // 3. currentQuestionsに保存
    await db.collection("currentQuestions").doc(unitId).set({
      questions: questions,
      timeSlot: timeSlot,
      date: getToday(),
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    // 4. 通知送信
    await sendQuestionNotification(memberIds);
  }
}

async function generateQuestionsForUnit(unitId, timeSlot) {
  const questions = [];
  
  // マスターから2問選出
  const masterQuestions = await selectFromMaster(unitId, timeSlot, 2);
  questions.push(...masterQuestions);
  
  // 前日のレポートを確認
  const yesterdayReport = await getYesterdayReport(unitId);
  
  if (yesterdayReport) {
    // AIで1問生成
    const aiQuestion = await generateAIQuestion(yesterdayReport.content, timeSlot);
    questions.push({
      id: null,
      text: aiQuestion,
      isAI: true
    });
  }
  
  return questions;
}

async function selectFromMaster(unitId, timeSlot, count) {
  // 1. 該当時間帯の質問を取得
  const questionsSnapshot = await db.collection("questions")
    .where("timeSlot", "==", timeSlot)
    .get();
  
  // 2. 表示回数を取得
  const statsDoc = await db.collection("questionStats").doc(unitId).get();
  const stats = statsDoc.exists ? statsDoc.data()[timeSlot] || {} : {};
  
  // 3. 表示回数が少ない順にソート
  const sortedQuestions = questionsSnapshot.docs
    .map(doc => ({
      id: doc.id,
      text: doc.data().text,
      count: stats[doc.id] || 0
    }))
    .sort((a, b) => a.count - b.count);
  
  // 4. 上位から選出
  const selected = sortedQuestions.slice(0, count).map(q => ({
    id: q.id,
    text: q.text,
    isAI: false
  }));
  
  // 5. 表示回数を更新
  const updates = {};
  selected.forEach(q => {
    updates[`${timeSlot}.${q.id}`] = (stats[q.id] || 0) + 1;
  });
  await db.collection("questionStats").doc(unitId).set(updates, { merge: true });
  
  return selected;
}
```

### 5.3 AI質問生成

**ファイル: `functions/generateAIQuestion.js`**

```javascript
const Anthropic = require("@anthropic-ai/sdk");

async function generateAIQuestion(reportContent, timeSlot) {
  const client = new Anthropic.default({
    apiKey: process.env.CLAUDE_API_KEY
  });

  const timeContext = {
    morning: "朝の質問です。今日一日の始まりに関連する質問にしてください。",
    afternoon: "午後の質問です。リフレッシュや息抜きに関連する質問にしてください。",
    evening: "夜の質問です。リラックスできる軽い質問にしてください。"
  };

  const prompt = `
あなたは同棲カップルの会話から質問を生成するアシスタントです。

## 前日の会話レポート
${reportContent}

## 条件
- ${timeContext[timeSlot]}
- 前日の会話の内容を引用した質問を1つ作成してください
- 会話に出てきた具体的な話題や発言を参照してください
- 短く、答えやすい質問にしてください
- 「？」で終わる質問文のみを出力してください

## 出力形式
質問文のみを出力（説明不要）
`;

  const response = await client.messages.create({
    model: "claude-sonnet-4-20250514",
    max_tokens: 100,
    messages: [{ role: "user", content: prompt }]
  });

  return response.content[0].text.trim();
}

module.exports = { generateAIQuestion };
```

### 5.4 回答保存時のトリガー

**ファイル: `functions/onAnswerCreated.js`**

```javascript
exports.onAnswerCreated = functions.firestore
  .document("answers/{answerId}")
  .onCreate(async (snap, context) => {
    const answer = snap.data();
    const unitId = answer.unitId;
    const answerUserId = answer.userId;
    const answererName = answer.userName;
    
    // UNITのメンバーを取得
    const unitDoc = await db.collection("units").doc(unitId).get();
    const memberIds = unitDoc.data().members || [];
    
    // 回答者以外のメンバーに通知
    const otherMembers = memberIds.filter(id => id !== answerUserId);
    
    for (const memberId of otherMembers) {
      const userDoc = await db.collection("users").doc(memberId).get();
      const fcmToken = userDoc.data()?.fcmToken;
      
      if (fcmToken) {
        await admin.messaging().send({
          notification: {
            title: `${answererName}さんがQUEに答えたよ`
          },
          token: fcmToken
        });
      }
    }
  });
```

---

## 6. 通知

| タイミング | タイトル | 本文 |
|------------|----------|------|
| 質問が届いた（8時/15時/22時） | QUEの時間だよ | なし |
| パートナーが回答 | ○○さんがQUEに答えたよ | なし |
| レポート完成（23時） | 今日のKIOGができたよ | なし |

---

## 7. iOS実装

### 7.1 LivingScreen の更新

```swift
struct LivingScreen: View {
    @State private var currentQuestions: [QuestionItem] = []
    @State private var pendingAnswers: [AnswerItem] = []  // 予想待ちの回答
    @State private var hasAnswered = false
    
    var body: some View {
        // ... 既存のヘッダー・KIOGセクション
        
        // QUEセクション（未回答の場合のみ表示）
        if !hasAnswered && !currentQuestions.isEmpty {
            queSection
        }
        
        // ANSセクション（予想待ちの回答がある場合）
        if !pendingAnswers.isEmpty {
            ansSection
        }
        
        // ... 既存のフッター
    }
    
    private var queSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("QUE")
                .font(.system(size: 24, weight: .bold))
            
            ForEach(currentQuestions) { question in
                QuestionCard(questionText: question.text) {
                    // 回答入力画面へ
                    showAnswerInput(for: question)
                }
            }
        }
    }
    
    private var ansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ANS")
                .font(.system(size: 24, weight: .bold))
            
            ForEach(pendingAnswers) { answer in
                AnswerCard(
                    name: answer.userName,
                    question: answer.questionText
                ) {
                    // 予想入力画面へ
                    showPredictionInput(for: answer)
                }
            }
        }
    }
}
```

### 7.2 回答入力画面

```swift
struct AnswerInputView: View {
    let question: QuestionItem
    @State private var answerText = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text(question.text)
                .font(.headline)
            
            TextField("回答を入力", text: $answerText)
                .textFieldStyle(.roundedBorder)
            
            Button("回答する") {
                submitAnswer()
            }
            .disabled(answerText.isEmpty)
        }
        .padding()
    }
    
    private func submitAnswer() {
        Task {
            try await AnswerService.shared.submitAnswer(
                question: question,
                answer: answerText
            )
            dismiss()
        }
    }
}
```

### 7.3 予想入力画面

```swift
struct PredictionInputView: View {
    let answer: AnswerItem
    @State private var predictionText = ""
    @State private var showActualAnswer = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text(answer.questionText)
                .font(.headline)
            
            Text("\(answer.userName)さんは何と答えた？")
                .font(.subheadline)
            
            if !showActualAnswer {
                TextField("予想を入力", text: $predictionText)
                    .textFieldStyle(.roundedBorder)
                
                Button("予想する") {
                    submitPrediction()
                }
                .disabled(predictionText.isEmpty)
            } else {
                // 予想入力後、実際の回答を表示
                VStack(spacing: 16) {
                    Text("あなたの予想")
                        .font(.caption)
                    Text(predictionText)
                    
                    Divider()
                    
                    Text("\(answer.userName)さんの回答")
                        .font(.caption)
                    Text(answer.answer)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Button("閉じる") {
                    dismiss()
                }
            }
        }
        .padding()
    }
    
    private func submitPrediction() {
        Task {
            try await AnswerService.shared.submitPrediction(
                answerId: answer.id,
                prediction: predictionText
            )
            showActualAnswer = true
        }
    }
}
```

### 7.4 AnswerService

**ファイル: `Services/AnswerService.swift`**

```swift
class AnswerService: ObservableObject {
    static let shared = AnswerService()
    private let db = Firestore.firestore()
    
    // 回答を送信
    func submitAnswer(question: QuestionItem, answer: String) async throws {
        guard let userId = AuthService.shared.userId else { return }
        let userData = try await UserService.shared.fetchUser(userId: userId)
        
        let answerData: [String: Any] = [
            "unitId": NavigationManager.shared.unitId,
            "date": getToday(),
            "timeSlot": getCurrentTimeSlot(),
            "questionId": question.id as Any,
            "questionText": question.text,
            "userId": userId,
            "userName": userData?.name ?? "",
            "answer": answer,
            "isAIQuestion": question.isAI,
            "createdAt": FieldValue.serverTimestamp(),
            "predictions": [],
            "viewedBy": []
        ]
        
        try await db.collection("answers").addDocument(data: answerData)
    }
    
    // 予想を送信
    func submitPrediction(answerId: String, prediction: String) async throws {
        guard let userId = AuthService.shared.userId else { return }
        let userData = try await UserService.shared.fetchUser(userId: userId)
        
        let predictionData: [String: Any] = [
            "predictorId": userId,
            "predictorName": userData?.name ?? "",
            "prediction": prediction,
            "predictedAt": FieldValue.serverTimestamp()
        ]
        
        let answerRef = db.collection("answers").document(answerId)
        try await answerRef.updateData([
            "predictions": FieldValue.arrayUnion([predictionData]),
            "viewedBy": FieldValue.arrayUnion([userId])
        ])
    }
    
    // 現在の質問を取得
    func fetchCurrentQuestions(unitId: String) async throws -> [QuestionItem] {
        let doc = try await db.collection("currentQuestions").document(unitId).getDocument()
        guard let data = doc.data(),
              let questions = data["questions"] as? [[String: Any]] else {
            return []
        }
        
        return questions.map { q in
            QuestionItem(
                id: q["id"] as? String,
                text: q["text"] as? String ?? "",
                isAI: q["isAI"] as? Bool ?? false
            )
        }
    }
    
    // 予想待ちの回答を取得
    func fetchPendingAnswers(unitId: String, userId: String) async throws -> [AnswerItem] {
        let today = getToday()
        
        let snapshot = try await db.collection("answers")
            .whereField("unitId", isEqualTo: unitId)
            .whereField("date", isEqualTo: today)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> AnswerItem? in
            let data = doc.data()
            let answererUserId = data["userId"] as? String ?? ""
            let viewedBy = data["viewedBy"] as? [String] ?? []
            
            // 自分の回答は除外、既に予想済みも除外
            if answererUserId == userId || viewedBy.contains(userId) {
                return nil
            }
            
            return AnswerItem(
                id: doc.documentID,
                userName: data["userName"] as? String ?? "",
                questionText: data["questionText"] as? String ?? "",
                answer: data["answer"] as? String ?? ""
            )
        }
    }
}
```

---

## 8. レポートへの反映

### 8.1 generateReport.js の更新

レポート生成時に、当日の質問回答を取得してレポートに含める。

```javascript
async function generateReportForUnit(unitId, isDebug) {
  // ... 既存の文字起こし・レポート生成処理
  
  // 当日の質問回答を取得
  const today = getToday();
  const answersSnapshot = await db.collection("answers")
    .where("unitId", "==", unitId)
    .where("date", "==", today)
    .get();
  
  const questionAnswers = formatQuestionAnswers(answersSnapshot.docs);
  
  // レポート保存
  await reportRef.set({
    // ... 既存フィールド
    questionAnswers: questionAnswers
  });
}

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
```

### 8.2 レポート表示形式

```
■ 今日の質問への回答

【質問】好きなお菓子は？

Aさんの予想: チョコレート
Bさんの回答: グミ

Bさんの予想: ポテチ
Aさんの回答: チョコ

---

【質問】子供の頃好きだった遊びは？

Bさんの回答: かくれんぼ
（Aさんの予想なし）

---

■ 今日の会話
（以下、既存のレポート内容）
```

---

## 9. 質問マスターの初期投入

Firestoreに60問を投入するスクリプト。

**ファイル: `functions/seedQuestions.js`**

```javascript
const admin = require("firebase-admin");

const questions = [
  // 朝（morning）- 20問
  { text: "今日の予定で一番楽しみなことは？", timeSlot: "morning", category: "今日の予定" },
  { text: "今日やらなきゃいけないことは？", timeSlot: "morning", category: "今日の予定" },
  // ... 全60問
];

async function seedQuestions() {
  const db = admin.firestore();
  const batch = db.batch();
  
  questions.forEach((q, index) => {
    const ref = db.collection("questions").doc(`q${String(index + 1).padStart(3, "0")}`);
    batch.set(ref, q);
  });
  
  await batch.commit();
  console.log("60 questions seeded successfully");
}
```

---

## 10. テスト確認項目

### 10.1 質問生成
- [ ] 8時/15時/22時に質問が生成される
- [ ] 前日レポートありの場合、3問生成される
- [ ] 前日レポートなしの場合、2問生成される
- [ ] 表示回数が少ない質問が優先される
- [ ] 通知「QUEの時間だよ」が届く

### 10.2 回答
- [ ] QUEセクションに質問が表示される
- [ ] 質問をタップして回答入力できる
- [ ] 回答後、QUEセクションが非表示になる
- [ ] パートナーに通知「○○さんがQUEに答えたよ」が届く

### 10.3 予想
- [ ] ANSセクションにパートナーの回答が表示される
- [ ] 予想を入力しないと実際の回答が見れない
- [ ] 予想入力後、実際の回答が表示される
- [ ] 次の質問タイミングでANSセクションがリセットされる

### 10.4 レポート
- [ ] 質問回答がレポートに含まれる
- [ ] 予想と回答が正しく表示される
- [ ] 予想なしの場合は回答のみ表示される

---

## 11. ファイル構成（Phase 5完了後）

```
KIOG/
├── Views/
│   ├── LivingScreen.swift（更新）
│   ├── AnswerInputView.swift（新規）
│   └── PredictionInputView.swift（新規）
├── Models/
│   ├── QuestionItem.swift（新規）
│   └── AnswerItem.swift（新規）
├── Services/
│   └── AnswerService.swift（新規）
└── ...

functions/
├── index.js（更新）
├── generateQuestions.js（新規）
├── generateAIQuestion.js（新規）
├── onAnswerCreated.js（新規）
├── seedQuestions.js（新規）
└── ...
```

---

## 12. 依頼内容まとめ

### 実装してほしいこと

1. 質問マスター60問をFirestoreに投入
2. 質問生成Cloud Functions（3つ）の実装
3. AI質問生成機能の実装
4. 回答保存時の通知トリガー実装
5. iOS側のQUE/ANSセクション実装
6. 回答入力・予想入力画面の実装
7. レポートへの質問回答反映
8. 通知文言の更新

### 成果物

- 質問・回答機能が動作するXcodeプロジェクト
- 8時/15時/22時に質問が届く
- 回答・予想機能が動作する
- レポートに質問回答が反映される
