import { existsSync, readdirSync, statSync } from "node:fs";
import { basename } from "node:path";
import { execFileSync } from "node:child_process";

const HOME = process.env.HOME || "/Users/cj";

const BUCKET = "b7nmt4mnz2";
const ENDPOINT = "https://s3api-eu-ro-1.runpod.io/";
const REGION = "EU-RO-1";

function sanitizeName(name: string): string {
  return name
    .replace(/\.[^.]+$/, "")
    .replace(/[^a-zA-Z0-9_ -]/g, "")
    .trim()
    .replace(/\s+/g, "_")
    .replace(/-+/g, "_")
    .toLowerCase();
}

function isCjFile(filename: string): boolean {
  return /^CJ_.*\.wav$/i.test(filename);
}

function parseArgs(): { filepath?: string; datasetName?: string; dryRun: boolean } {
  const args = process.argv.slice(2);
  let filepath: string | undefined;
  let datasetName: string | undefined;
  let dryRun = false;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--name" && i + 1 < args.length) {
      datasetName = args[++i];
    } else if (args[i] === "--dry-run") {
      dryRun = true;
    } else if (!args[i].startsWith("--")) {
      filepath = args[i];
    }
  }

  return { filepath, datasetName, dryRun };
}

function s3Url(key: string): string {
  return `s3://${BUCKET}/${key}`;
}

function uploadViaAwsCli(localPath: string, s3Key: string) {
  const accessKeyId = process.env.S3_ACCESS_KEY;
  const secretAccessKey = process.env.S3_SECRET_KEY;

  if (!accessKeyId || !secretAccessKey) {
    console.error("Missing S3_ACCESS_KEY or S3_SECRET_KEY in .env");
    process.exit(1);
  }

  const dest = s3Url(s3Key);
  console.log(`  Uploading via awscli...`);

  execFileSync("python3", [
    "-m", "awscli", "s3", "cp",
    localPath, dest,
    "--endpoint-url", ENDPOINT,
    "--region", REGION,
  ], {
    stdio: "inherit",
    env: {
      ...process.env,
      AWS_ACCESS_KEY_ID: accessKeyId,
      AWS_SECRET_ACCESS_KEY: secretAccessKey,
    },
  });

  console.log(`  ✓ Done: ${dest}`);
}

async function uploadFile(localPath: string, datasetName: string, renameToMain: boolean, dryRun: boolean) {
  if (!existsSync(localPath)) {
    console.error(`File not found: ${localPath}`);
    process.exit(1);
  }

  const { size } = statSync(localPath);
  const s3Filename = renameToMain ? "main.wav" : basename(localPath);
  const s3Key = `datasets/${datasetName}/${s3Filename}`;

  console.log(`Upload: ${localPath} (${(size / 1024 / 1024).toFixed(1)}MB)`);
  console.log(`    →  ${s3Url(s3Key)}`);
  console.log(`    →  /workspace/datasets/${datasetName}/${s3Filename}`);

  if (dryRun) return;

  uploadViaAwsCli(localPath, s3Key);
}

async function main() {
  const { filepath, datasetName, dryRun } = parseArgs();

  if (filepath) {
    const origFilename = basename(filepath);

    if (isCjFile(origFilename) && !datasetName) {
      const label = origFilename.match(/^CJ_(.+)\.wav$/i)?.[1] || sanitizeName(origFilename);
      await uploadFile(filepath, `CJ_${label}`, true, dryRun);
    } else {
      const dsName = datasetName || sanitizeName(origFilename);
      await uploadFile(filepath, dsName, false, dryRun);
    }
  } else {
    const recordingsDir = `${HOME}/a/recordings`;
    if (!existsSync(recordingsDir)) {
      console.error(`Directory not found: ${recordingsDir}`);
      process.exit(1);
    }

    const files = readdirSync(recordingsDir).filter((f) => isCjFile(f));

    if (files.length === 0) {
      console.log("No CJ_*.wav files found in", recordingsDir);
      process.exit(0);
    }

    for (const filename of files) {
      const label = filename.match(/^CJ_(.+)\.wav$/i)?.[1];
      if (!label) continue;
      await uploadFile(`${recordingsDir}/${filename}`, `CJ_${label}`, true, dryRun);
    }
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
