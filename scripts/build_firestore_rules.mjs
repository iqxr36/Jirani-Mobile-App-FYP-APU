import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');
const rulesDir = path.join(root, 'firestore_rules');
const outFile = path.join(root, 'firestore.rules');

const GENERATED_HEADER =
  '// GENERATED FILE — edit firestore_rules/*.rules and run: node scripts/build_firestore_rules.mjs';

function build() {
  const files = fs
    .readdirSync(rulesDir)
    .filter((f) => f.endsWith('.rules'))
    .sort();

  const fragments = files.map((f) =>
    fs.readFileSync(path.join(rulesDir, f), 'utf8').trim(),
  );

  const body = fragments.join('\n\n');
  const output = `${GENERATED_HEADER}
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
${body}
  }
}
`;

  fs.writeFileSync(outFile, output, 'utf8');
  const lineCount = output.split(/\r?\n/).length;
  console.log(`Wrote ${outFile} (${lineCount} lines)`);
  console.log('Fragments:');
  for (const f of files) {
    const fileContent = fs.readFileSync(path.join(rulesDir, f), 'utf8');
    const lines = fileContent.split(/\r?\n/).length;
    console.log(`  ${f} (${lines} lines)`);
  }
}

build();
