const { GoogleGenerativeAI } = require("@google/generative-ai");

async function transcribeAudio(audioBuffer, members) {
  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

  const memberInfo = members
    .map(m => `${m.name}（${m.gender}）`)
    .join("、");

  const memberNames = members.map(m => m.name);

  const prompt = `
この音声ファイルを文字起こししてください。

## 話者情報
${memberInfo}

## 出力形式
話者を識別し、以下の形式で出力してください：

${memberNames[0]}: 発話内容
${memberNames[1] || "相手"}: 発話内容
...

## ルール
- 話者の性別と声の特徴から、誰の発言か判断してください
- 発話内容はできるだけ正確に書き起こしてください
- 「えー」「あー」などのフィラーは省略してOK
- 聞き取れない部分は（聞き取れず）と記載
- 会話の流れが自然になるように整形してください
`;

  const audioBase64 = audioBuffer.toString("base64");

  const result = await model.generateContent([
    prompt,
    {
      inlineData: {
        mimeType: "audio/mp4",
        data: audioBase64
      }
    }
  ]);

  return result.response.text();
}

module.exports = { transcribeAudio };
