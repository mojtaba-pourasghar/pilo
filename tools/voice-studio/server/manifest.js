// Reading what the characters of «سفر پیلو» say.
//
// The game keeps every line in data/voice/voice_lines.json (built by tools/voice/build_voice_lines.py
// from the level files):
//   { "id": "l03_intro_1", "file": "voice/l03_intro_1.mp3", "who": "pilo", "text": "…", "level": 3, … }
// The studio works with the file name as the key (l03_intro_1), because that is the name the game
// plays: a clip saved as <key>.mp3 in assets/audio/voice is found with no other step.
// "who" picks the character, and so the voice (config.characters in server/index.js).
// An optional "spoken" field holds a respelling for the TTS service (vowels, stress); the game
// never reads it — it only shows "text".

import fs from "node:fs";
import path from "node:path";

// One group per character; the level is the second filter ("chapter" in the page).
const GROUPS = [
  { id: "pilo", test: (l) => l.who === "pilo", label: "پیلو" },
  { id: "nima", test: (l) => l.who === "nima", label: "نیما" },
  { id: "ghubarak", test: (l) => l.who === "ghubarak", label: "غبارک" },
  { id: "squirrel", test: (l) => l.who === "squirrel", label: "سنجابک" },
];

function groupOf(line) {
  return (GROUPS.find((g) => g.test(line)) || { id: "other" }).id;
}

/** The studio's key for a line: the base name of the file the app plays. */
export function keyOf(line) {
  return path.basename(line.file || `voice/${line.id.replace(/\./g, "_")}.mp3`, ".mp3");
}

function readJson(manifestPath) {
  const data = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  return (data.lines || []).map((l) => ({
    key: keyOf(l),
    id: l.id,
    written: l.text,
    spoken: l.spoken && l.spoken.trim() ? l.spoken.trim() : l.text,
    event: l.event || "",
    note: l.note || "",
    who: l.who || "pilo",
    group: groupOf(l),
    chapter: l.level ? Number(l.level) : null,
  }));
}

function readText(manifestPath) {
  const lines = [];
  for (const raw of fs.readFileSync(manifestPath, "utf8").split(/\r?\n/)) {
    const line = raw.trim();
    if (!line || line.startsWith("#") || !line.includes("|")) continue;
    const cols = line.split("|").map((c) => c.trim());
    const [key, written] = cols;
    if (!key || !written) continue;
    lines.push({ key, id: key, written, spoken: cols[2] || written, event: "", note: "",
                 who: "pilo", group: "pilo", chapter: null });
  }
  return lines;
}

export function readManifest(manifestPath) {
  return manifestPath.toLowerCase().endsWith(".json") ? readJson(manifestPath) : readText(manifestPath);
}

/**
 * Sets (or with null, removes) the TTS respelling of one line in voice_lines.json, keeping the
 * file's formatting. Returns false when the key is not in the file.
 */
export function setSpoken(manifestPath, key, spoken) {
  if (!manifestPath.toLowerCase().endsWith(".json")) return false;
  const original = fs.readFileSync(manifestPath, "utf8");
  const data = JSON.parse(original);
  const line = (data.lines || []).find((l) => keyOf(l) === key);
  if (!line) return false;
  if (spoken) line.spoken = spoken;
  else delete line.spoken;
  const temp = manifestPath + ".tmp";
  fs.writeFileSync(temp, JSON.stringify(data, null, 2) + (original.endsWith("\n") ? "\n" : ""), "utf8");
  fs.renameSync(temp, manifestPath);
  return true;
}

/** Which keys already have a file in the output directory, whatever the extension. */
export function existingKeys(outDir) {
  const done = new Map();
  if (!outDir || !fs.existsSync(outDir)) return done;
  for (const name of fs.readdirSync(outDir)) {
    const ext = path.extname(name).toLowerCase();
    if (![".ogg", ".mp3", ".wav"].includes(ext)) continue;
    const full = path.join(outDir, name);
    let size = 0;
    try {
      size = fs.statSync(full).size;
    } catch {
      continue;
    }
    // a near-empty file is the wreck of a failed attempt, not a recording
    if (size < 512) continue;
    done.set(path.basename(name, ext), { name, size });
  }
  return done;
}

export const GROUP_LABELS = Object.fromEntries(GROUPS.map((g) => [g.id, g.label]));
