// Which clips in assets/audio/voice were made by the TTS service, as opposed to recorded by a
// person. Kept in docs/voice/tts_generated.json, which goes into git, so everyone can see which
// clips are still temporary.
//
// The rule it enforces: the studio may write and rewrite its own clips, but never a file that is
// not on this list — that is a human recording, and a TTS line must not replace it.
// tools/voice/import_recordings.sh takes a key off the list when a recording arrives.

import fs from "node:fs";
import path from "node:path";

export function createRegistry(file) {
  const read = () => {
    try {
      return JSON.parse(fs.readFileSync(file, "utf8"));
    } catch {
      return { note: "clips made with the TTS service — temporary until a voice actor records them", files: {} };
    }
  };

  const write = (data) => {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    const sorted = Object.fromEntries(Object.entries(data.files).sort(([a], [b]) => a.localeCompare(b)));
    const temp = file + ".tmp";
    fs.writeFileSync(temp, JSON.stringify({ ...data, files: sorted }, null, 2) + "\n", "utf8");
    fs.renameSync(temp, file);
  };

  return {
    file,
    keys: () => new Set(Object.keys(read().files)),
    has: (key) => Object.prototype.hasOwnProperty.call(read().files, key),
    mark(key, meta) {
      const data = read();
      data.files[key] = { ...meta, at: new Date().toISOString() };
      write(data);
    },
  };
}
