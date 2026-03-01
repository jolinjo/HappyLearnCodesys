import fs from "fs/promises";
import path from "path";
import type { Dirent } from "fs";

const contentDir = "content";

/**
 * 讀取位於 tutorial-site/content 下的 Markdown 檔案。
 * @param relativePath 相對於 tutorial-site/content 的路徑
 */
export async function readMarkdown(relativePath: string): Promise<string> {
  const projectRoot = process.cwd();
  const fullPath = path.join(projectRoot, contentDir, relativePath);
  const buffer = await fs.readFile(fullPath);
  return buffer.toString("utf-8");
}

/**
 * 讀取 content 下任意文字檔（例如 .st）。
 * @param relativePath 相對於 content 的路徑
 */
export async function readTextFile(relativePath: string): Promise<string> {
  const projectRoot = process.cwd();
  const fullPath = path.join(projectRoot, contentDir, relativePath);
  const buffer = await fs.readFile(fullPath);
  return buffer.toString("utf-8");
}

export interface StFileEntry {
  name: string;
  path: string;
}

/**
 * 列出指定 content 子目錄下所有 .st 檔（名稱與相對路徑）。
 * @param dirRelativeToContent 例如 "softmotion/BasicMotion_GearInPos"
 */
export async function listStFiles(
  dirRelativeToContent: string,
): Promise<StFileEntry[]> {
  const projectRoot = process.cwd();
  const fullDir = path.join(projectRoot, contentDir, dirRelativeToContent);
  let entries: Dirent[];
  try {
    entries = await fs.readdir(fullDir, { withFileTypes: true });
  } catch {
    return [];
  }
  const out: StFileEntry[] = [];
  for (const e of entries) {
    if (!e.isFile() || !e.name.toLowerCase().endsWith(".st")) continue;
    out.push({
      name: e.name,
      path: path.join(dirRelativeToContent, e.name).replace(/\\/g, "/"),
    });
  }
  return out.sort((a, b) => a.name.localeCompare(b.name));
}

