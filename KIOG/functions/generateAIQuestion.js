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
