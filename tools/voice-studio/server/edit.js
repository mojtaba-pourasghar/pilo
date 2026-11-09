// Editing a line's text from the studio, so it changes everywhere at once.
//
// A line's written text lives in the game's own files (level files and the scripts that make
// them, the story and chapter cards, the tutorial, the in-game messages). Changing it only in
// data/voice/voice_lines.json would be undone by the next rebuild and would leave the game
// showing the old words. So a new written text replaces the old one, as an exact quoted string,
// in every source file; every line with that text gets the new text; and its vowelled form in
// tools/voice/spoken_fa.json moves with it. A new vowelled form is checked to have exactly the
// letters of the text. The clips of the changed lines are then out of date; the studio remakes them.

import fs from "node:fs";
import path from "node:path";
import { stripMarks } from "./vowels.js";

const SOURCES = [
  ["data/levels", /\.json$/],
  ["data/story", /\.json$/],
  ["tools/levels", /\.py$/],
  ["scripts", /\.gd$/],
  ["tools/voice", /^build_voice_lines\.py$/],
];

function walk(dir, pattern, out = []) {
  if (!fs.existsSync(dir)) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, pattern, out);
    else if (pattern.test(entry.name)) out.push(full);
  }
  return out;
}

const quoted = (text) => `"${text}"`;

/** Replaces "old" with "new" (whole quoted strings only) in every source file; returns the files changed. */
function replaceEverywhere(app, oldText, newText) {
  const changed = [];
  for (const [dir, pattern] of SOURCES) {
    for (const file of walk(path.join(app, dir), pattern)) {
      const before = fs.readFileSync(file, "utf8");
      if (!before.includes(quoted(oldText))) continue;
      const after = before.split(quoted(oldText)).join(quoted(newText));
      fs.writeFileSync(file, after, "utf8");
      changed.push(path.relative(app, file).replace(/\\/g, "/"));
    }
  }
  return changed;
}

function readJson(file, fallback) {
  return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : fallback;
}

function writeJson(file, data, indent) {
  const temp = file + ".tmp";
  fs.writeFileSync(temp, JSON.stringify(data, null, indent) + "\n", "utf8");
  fs.renameSync(temp, file);
}

/**
 * { written?, spoken? } for the line `key`. Returns the keys whose clips are now out of date and
 * the source files that were changed.
 */
export function editLine(app, manifestPath, key, { written, spoken }) {
  const spokenFile = path.join(app, "tools/voice/spoken_fa.json");
  const data = readJson(manifestPath, { lines: [] });
  const keyOf = (l) => path.basename(l.file || `voice/${l.id}.mp3`, ".mp3");
  const line = data.lines.find((l) => keyOf(l) === key);
  if (!line) throw new Error(`جملهٔ «${key}» در فهرست نیست`);

  const oldText = line.text;
  const newText = (written ?? oldText).trim();
  if (!newText) throw new Error("متن خالی است");
  if (/["\\]/.test(newText)) throw new Error("متن نباید \" یا \\ داشته باشد");
  let newSpoken = spoken === undefined || spoken === null ? null : String(spoken).trim();
  if (newSpoken && stripMarks(newSpoken) !== stripMarks(newText)) {
    throw new Error("حروفِ متنِ تلفظی با متن یکی نیست — فقط اعراب اضافه یا کم کنید، یا متن را هم عوض کنید");
  }

  const spokenMap = readJson(spokenFile, {});
  const files = newText === oldText ? [] : replaceEverywhere(app, oldText, newText);
  if (newText !== oldText) {
    // the old vowelled form no longer fits the new words; without a new one, the plain text is read
    if (!newSpoken) newSpoken = spokenMap[oldText] && stripMarks(spokenMap[oldText]) === stripMarks(newText)
      ? spokenMap[oldText] : newText;
    delete spokenMap[oldText];
  }
  if (newSpoken) spokenMap[newText] = newSpoken;
  const sorted = Object.fromEntries(Object.entries(spokenMap).sort(([a], [b]) => a.localeCompare(b, "fa")));
  writeJson(spokenFile, sorted, 1);

  // every line that says these words (signs repeat across levels) changes together
  const affected = [];
  for (const l of data.lines) {
    if (l.text !== oldText) continue;
    l.text = newText;
    if (newSpoken) l.spoken = newSpoken;
    affected.push(keyOf(l));
  }
  writeJson(manifestPath, data, 1);
  return { keys: affected, files, text: newText, spoken: newSpoken || newText };
}

/** Drops the vowelled form of the line's text (the plain text is then read). */
export function clearSpoken(app, manifestPath, key) {
  const spokenFile = path.join(app, "tools/voice/spoken_fa.json");
  const data = readJson(manifestPath, { lines: [] });
  const keyOf = (l) => path.basename(l.file || `voice/${l.id}.mp3`, ".mp3");
  const line = data.lines.find((l) => keyOf(l) === key);
  if (!line) return [];
  const spokenMap = readJson(spokenFile, {});
  delete spokenMap[line.text];
  writeJson(spokenFile, spokenMap, 1);
  const affected = [];
  for (const l of data.lines) {
    if (l.text === line.text) { delete l.spoken; affected.push(keyOf(l)); }
  }
  writeJson(manifestPath, data, 1);
  return affected;
}
