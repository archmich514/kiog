const admin = require("firebase-admin");

const questions = [
  // 朝（morning）- 20問
  // 今日の予定
  { text: "今日の予定で一番楽しみなことは？", timeSlot: "morning", category: "今日の予定" },
  { text: "今日やらなきゃいけないことは？", timeSlot: "morning", category: "今日の予定" },
  { text: "今日誰かに会う予定ある？", timeSlot: "morning", category: "今日の予定" },
  { text: "今日何時頃に帰ってくる？", timeSlot: "morning", category: "今日の予定" },
  // 気分・体調
  { text: "今日の調子は何点？（10点満点）", timeSlot: "morning", category: "気分・体調" },
  { text: "今朝の目覚めはどうだった？", timeSlot: "morning", category: "気分・体調" },
  { text: "今日のやる気を一言で表すと？", timeSlot: "morning", category: "気分・体調" },
  { text: "昨日ちゃんと眠れた？", timeSlot: "morning", category: "気分・体調" },
  // 今日の目標
  { text: "今日ひとつだけ達成するなら何？", timeSlot: "morning", category: "今日の目標" },
  { text: "今日意識したいことは？", timeSlot: "morning", category: "今日の目標" },
  { text: "今日の仕事や家事で頑張りたいことは？", timeSlot: "morning", category: "今日の目標" },
  { text: "今日の自分に一言かけるなら？", timeSlot: "morning", category: "今日の目標" },
  // 食べたいもの
  { text: "今日の夜ごはん何がいい？", timeSlot: "morning", category: "食べたいもの" },
  { text: "今日のランチ何食べる予定？", timeSlot: "morning", category: "食べたいもの" },
  { text: "今食べたいものは？", timeSlot: "morning", category: "食べたいもの" },
  { text: "今日のおやつ何がいい？", timeSlot: "morning", category: "食べたいもの" },
  // パートナーへの感謝
  { text: "最近パートナーにありがとうって思ったことは？", timeSlot: "morning", category: "パートナーへの感謝" },
  { text: "パートナーの好きなところをひとつ挙げるなら？", timeSlot: "morning", category: "パートナーへの感謝" },
  { text: "最近パートナーがしてくれて嬉しかったことは？", timeSlot: "morning", category: "パートナーへの感謝" },
  { text: "パートナーに「さすが」って思ったことは？", timeSlot: "morning", category: "パートナーへの感謝" },

  // 午後（afternoon）- 20問
  // 今の気分
  { text: "今どんな気分？", timeSlot: "afternoon", category: "今の気分" },
  { text: "午後の疲れ具合は何点？（10点満点）", timeSlot: "afternoon", category: "今の気分" },
  { text: "今のテンションを天気で表すと？", timeSlot: "afternoon", category: "今の気分" },
  { text: "今一番考えてることは？", timeSlot: "afternoon", category: "今の気分" },
  // 息抜き
  { text: "今一番したいことは？", timeSlot: "afternoon", category: "息抜き" },
  { text: "今すぐ休めるなら何する？", timeSlot: "afternoon", category: "息抜き" },
  { text: "今飲みたいものは？", timeSlot: "afternoon", category: "息抜き" },
  { text: "あと何時間で仕事終わる？", timeSlot: "afternoon", category: "息抜き" },
  // 妄想・願望
  { text: "今すぐどこでもドアがあったらどこ行く？", timeSlot: "afternoon", category: "妄想・願望" },
  { text: "100万円もらったら何に使う？", timeSlot: "afternoon", category: "妄想・願望" },
  { text: "明日仕事休みになったら何する？", timeSlot: "afternoon", category: "妄想・願望" },
  { text: "今の気分で選ぶなら海と山どっち？", timeSlot: "afternoon", category: "妄想・願望" },
  // 近い未来
  { text: "次の休みにしたいことは？", timeSlot: "afternoon", category: "近い未来" },
  { text: "今週末どう過ごしたい？", timeSlot: "afternoon", category: "近い未来" },
  { text: "近いうちに食べに行きたいものは？", timeSlot: "afternoon", category: "近い未来" },
  { text: "次の連休どこか行きたい？", timeSlot: "afternoon", category: "近い未来" },
  // 雑談ネタ
  { text: "最近気になってるものある？", timeSlot: "afternoon", category: "雑談ネタ" },
  { text: "最近ハマってることは？", timeSlot: "afternoon", category: "雑談ネタ" },
  { text: "今日あった小さな出来事は？", timeSlot: "afternoon", category: "雑談ネタ" },
  { text: "最近見た動画や記事で面白かったのある？", timeSlot: "afternoon", category: "雑談ネタ" },

  // 夜（evening）- 20問
  // 今日の小さな幸せ
  { text: "今日ちょっと嬉しかったことは？", timeSlot: "evening", category: "今日の小さな幸せ" },
  { text: "今日「良かった」って思った瞬間は？", timeSlot: "evening", category: "今日の小さな幸せ" },
  { text: "今日自分を褒めるなら何？", timeSlot: "evening", category: "今日の小さな幸せ" },
  { text: "今日の小さなラッキーは？", timeSlot: "evening", category: "今日の小さな幸せ" },
  // 五感・感覚系
  { text: "好きな香りは？", timeSlot: "evening", category: "五感・感覚系" },
  { text: "落ち着く音は？", timeSlot: "evening", category: "五感・感覚系" },
  { text: "触り心地が好きなものは？", timeSlot: "evening", category: "五感・感覚系" },
  { text: "見てると癒されるものは？", timeSlot: "evening", category: "五感・感覚系" },
  // 今夜のこと
  { text: "寝る前に何する？", timeSlot: "evening", category: "今夜のこと" },
  { text: "今夜見たい夢は？", timeSlot: "evening", category: "今夜のこと" },
  { text: "今夜何時に寝る？", timeSlot: "evening", category: "今夜のこと" },
  { text: "寝る前に食べたいものある？", timeSlot: "evening", category: "今夜のこと" },
  // 好きなもの
  { text: "最近ハマってるお菓子は？", timeSlot: "evening", category: "好きなもの" },
  { text: "最近ハマってるアイスは？", timeSlot: "evening", category: "好きなもの" },
  { text: "リラックスする時に何する？", timeSlot: "evening", category: "好きなもの" },
  { text: "家で最近ハマってる場所は？", timeSlot: "evening", category: "好きなもの" },
  // 子供時代
  { text: "子供の頃好きだった遊びは？", timeSlot: "evening", category: "子供時代" },
  { text: "子供の頃好きだった食べ物は？", timeSlot: "evening", category: "子供時代" },
  { text: "子供の頃の夢は何だった？", timeSlot: "evening", category: "子供時代" },
  { text: "子供の頃よく見てたテレビは？", timeSlot: "evening", category: "子供時代" }
];

async function seedQuestions() {
  // Firebase Admin SDK が初期化されているか確認
  if (!admin.apps.length) {
    admin.initializeApp();
  }

  const db = admin.firestore();
  const batch = db.batch();

  questions.forEach((q, index) => {
    const docId = `q${String(index + 1).padStart(3, "0")}`;
    const ref = db.collection("questions").doc(docId);
    batch.set(ref, q);
  });

  await batch.commit();
  console.log(`${questions.length} questions seeded successfully`);
}

// エクスポート
module.exports = { seedQuestions, questions };

// コマンドラインから直接実行された場合
if (require.main === module) {
  seedQuestions()
    .then(() => {
      console.log("Done!");
      process.exit(0);
    })
    .catch((error) => {
      console.error("Error:", error);
      process.exit(1);
    });
}
