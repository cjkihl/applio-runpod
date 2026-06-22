import { S3Client } from "bun";
import { readdirSync, existsSync, statSync } from "node:fs";

const HOME = process.env.HOME || "/Users/cj";

const accessKeyId = process.env.S3_ACCESS_KEY;
const secretAccessKey = process.env.S3_SECRET_KEY;

if (!accessKeyId || !secretAccessKey) {
  console.error("Missing S3_ACCESS_KEY or S3_SECRET_KEY in .env");
  process.exit(1);
}

const BUCKET = "b7nmt4mnz2";
const ENDPOINT = "https://s3api-eu-ro-1.runpod.io/";
const REGION = "EU-RO-1";

const s3 = new S3Client({
  accessKeyId,
  secretAccessKey,
  bucket: BUCKET,
  endpoint: ENDPOINT,
  region: REGION,
});

const recordingsDir = `${HOME}/a/recordings`;

if (!existsSync(recordingsDir)) {
  console.error(`Directory not found: ${recordingsDir}`);
  process.exit(1);
}

const files = readdirSync(recordingsDir).filter((f) => /^CJ_.*\.wav$/i.test(f));

if (files.length === 0) {
  console.log("No CJ_*.wav files found in", recordingsDir);
  process.exit(0);
}

for (const filename of files) {
  const match = filename.match(/^CJ_(.+)\.wav$/i);
  if (!match) continue;

  const date = match[1];
  const localPath = `${recordingsDir}/${filename}`;
  const s3Path = `datasets/CJ_${date}/main.wav`;

  console.log(`Uploading ${filename} (${localPath}) → s3://${BUCKET}/${s3Path}...`);
  const s3file = s3.file(s3Path);
  const localFile = Bun.file(localPath);
  const { size } = statSync(localPath);
  if (size > 500 * 1024 * 1024) {
    console.log(`  Large file (${(size / 1024 / 1024).toFixed(1)}MB), using multipart upload...`);
    await Bun.write(s3file, localFile);
  } else {
    const writer = s3file.writer({ partSize: 500 * 1024 * 1024 });
    await writer.write(await localFile.arrayBuffer());
    await writer.end();
  }
  console.log(`  ✓ Done: datasets/CJ_${date}/main.wav`);
}

console.log(`\nUploaded ${files.length} file(s).`);
