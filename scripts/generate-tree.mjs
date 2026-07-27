import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const output = path.join(root, "DIRECTORY_TREE.txt");
const excluded = new Set([
  ".git",
  "node_modules",
  ".pnpm-store",
  ".dart_tool",
  ".turbo",
  "ephemeral",
  "dist",
  "build",
]);
fs.writeFileSync(output, "", "utf8");
const lines = ["Nexoraa-CleanSoft/"];

function render(directory, prefix) {
  const entries = fs.readdirSync(directory, { withFileTypes: true })
    .filter((entry) => !excluded.has(entry.name))
    .sort((a, b) => a.isDirectory() === b.isDirectory()
      ? a.name.localeCompare(b.name)
      : a.isDirectory() ? -1 : 1);
  entries.forEach((entry, index) => {
    const last = index === entries.length - 1;
    lines.push(prefix + (last ? "`-- " : "|-- ") + entry.name + (entry.isDirectory() ? "/" : ""));
    if (entry.isDirectory()) {
      render(path.join(directory, entry.name), prefix + (last ? "    " : "|   "));
    }
  });
}

render(root, "");
fs.writeFileSync(output, lines.join("\n") + "\n", "utf8");
console.log("Wrote " + lines.length + " tree lines.");
