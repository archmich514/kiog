const Anthropic = require("@anthropic-ai/sdk");

async function generateReport(transcript, members) {
  const client = new Anthropic.default({
    apiKey: process.env.CLAUDE_API_KEY
  });

  const memberInfo = members
    .map((m, i) => `話者${i + 1}: ${m.name}`)
    .join("\n");

  const prompt = `
あなたは、同棲カップルの日常会話からレポートを生成するアシスタントです。

## 入力
- 二人の会話の文字起こしデータ（話者分離済み）
${memberInfo}

## 出力形式

以下の形式でレポートを生成してください。JSONで出力してください。

{
  "content": "レポート本文（Markdown形式）",
  "tags": ["タグ1", "タグ2", ...]
}

レポート本文の形式：

---

■ 今日の会話

（話題ごとに段落を分けて要約。実際の発話は「」で引用する。）

■ 印象的なやりとり

（面白かった・印象に残る会話をそのまま抜粋。会話形式で記載。）

■ 今日のトピック

**決まったこと**
- （箇条書き。該当なしの場合は「特になし」）

**新しく知ったこと**
- （箇条書き。該当なしの場合は「特になし」）

**やりたいこと**
- （箇条書き。該当なしの場合は「特になし」）

**欲しいもの**
- （箇条書き。該当なしの場合は「特になし」）

**明日・近い予定**
- （箇条書き。該当なしの場合は「特になし」）

**記念日**
- （箇条書き。該当なしの場合は省略）

---

## ルール

1. 文章スタイル
   - ドキュメンタリー風の客観的な視点で記述する
   - 実際の発話は「」で引用し、そのまま記載する
   - 500文字以上1500文字以下で生成する

2. 禁止事項
   - 文字起こしに含まれない情報を追加しない（時間、場所、感情など）
   - 感情を推測して書かない（「嬉しそうだった」「楽しそうに話した」などはNG）
   - 事実にない解釈を加えない

3. 話題の分け方
   - 会話の流れに沿って、話題が変わったら段落を分ける
   - 各話題で具体的な発言を1〜2個は引用する

4. 印象的なやりとり
   - ユーモアのあるやりとり、意外な発言、二人らしさが出ている部分を選ぶ
   - 会話形式でそのまま抜粋する（3〜6発話程度）

5. タグ
   - 会話に出てきた具体的なキーワードを5〜10個抽出する
   - 固有名詞、物の名前、イベント名などを優先する
   - 「#」は含めず、キーワードのみ

## 会話データ

${transcript}
`;

  const response = await client.messages.create({
    model: "claude-sonnet-4-20250514",
    max_tokens: 2000,
    messages: [
      { role: "user", content: prompt }
    ]
  });

  const responseText = response.content[0].text;

  // JSON部分を抽出
  const jsonMatch = responseText.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    console.error("Failed to parse report JSON, response:", responseText);
    // フォールバック: テキストをそのままcontentとして返す
    return {
      content: responseText,
      tags: []
    };
  }

  try {
    return JSON.parse(jsonMatch[0]);
  } catch (error) {
    console.error("JSON parse error:", error);
    return {
      content: responseText,
      tags: []
    };
  }
}

module.exports = { generateReport };
