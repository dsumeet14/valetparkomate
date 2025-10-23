// deepl.js
const deepl = require("deepl-node");

const translator = new deepl.Translator(process.env.DEEPL_API_KEY);

async function translateText(text, targetLang = "EN") {
  try {
    const result = await translator.translateText(text, null, targetLang);
    return result.text;
  } catch (err) {
    console.error("DeepL translation error:", err.message);
    throw err;
  }
}

module.exports = { translateText };
