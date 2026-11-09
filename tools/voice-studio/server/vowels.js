// Which text goes to Avasho for a line: three modes, chosen in the settings and compared by ear
// in the test tab.
//
//   plain  the written text, as the player sees it
//   light  only the marks that change how a word is said: the ezafe kasra at the end of a word
//          (کتابِ من) and shadda (تکّه); no sukun and no mark inside a word. A TTS model trained on
//          ordinary Persian text reads this closest to how it learned.
//   full   every vowel mark in tools/voice/spoken_fa.json (fatha, kasra, damma, sukun, shadda)

export const MODES = {
  plain: "بی‌اعراب (متن نوشته)",
  light: "اعراب سبک (فقط کسرهٔ اضافه و تشدید)",
  full: "اعراب کامل",
};

const FATHA = "َ", DAMMA = "ُ", KASRA = "ِ", SUKUN = "ْ", SHADDA = "ّ", TANWIN = "ً";
const MARKS = new RegExp(`[${FATHA}${DAMMA}${KASRA}${SUKUN}${SHADDA}${TANWIN}]`, "g");
// what may follow the end of a word: space, ZWNJ, punctuation or the end of the text
const WORD_END = "(?=[\\s‌.,!?؛،:…»«()\\-]|$)";

export const stripMarks = (text) => String(text || "").replace(MARKS, "");

export function light(full) {
  return String(full || "")
    // the ezafe kasra at the end of a word stays (it is said: «کتابِ من»)
    .replace(new RegExp(`${KASRA}${WORD_END}`, "g"), "\u0000")
    .replace(new RegExp(`[${FATHA}${DAMMA}${KASRA}${SUKUN}${TANWIN}]`, "g"), "")
    .replace(/\u0000/g, KASRA);
}

export function normalizeMode(value, useVowelsFallback = true) {
  if (value in MODES) return value;
  return useVowelsFallback ? "light" : "plain";
}

/** The text sent to the service for one line ({ written, spoken }). */
export function textFor(line, mode) {
  const written = String(line.written || "").trim();
  const spoken = String(line.spoken || "").trim() || written;
  if (mode === "plain") return written;
  if (mode === "full") return spoken;
  return light(spoken);
}
