"use client";

import { useCallback, useEffect, useState } from "react";
import { parseHeadings, type TocItem } from "@/lib/markdownToc";
import { MarkdownRenderer, type MarkdownFontSize } from "./MarkdownRenderer";

const STORAGE_KEY = "tutorial-md-font-size";

function loadStoredFontSize(): MarkdownFontSize {
  if (typeof window === "undefined") return "medium";
  const v = localStorage.getItem(STORAGE_KEY);
  if (v === "small" || v === "medium" || v === "large") return v;
  return "medium";
}

export interface MarkdownWithTocProps {
  content: string;
}

export function MarkdownWithToc({ content }: MarkdownWithTocProps) {
  const [fontSize, setFontSize] = useState<MarkdownFontSize>("medium");
  useEffect(() => {
    setFontSize(loadStoredFontSize());
  }, []);

  const handleFontSize = useCallback((size: MarkdownFontSize) => {
    setFontSize(size);
    if (typeof window !== "undefined") {
      localStorage.setItem(STORAGE_KEY, size);
    }
  }, []);

  const toc = parseHeadings(content);

  const renderContent = () => (
    <div className="min-w-0 flex-1 space-y-2">
      <div
        className="flex items-center gap-2 rounded-md border py-1.5 px-2 text-xs"
        style={{
          borderColor: "var(--t-border)",
          backgroundColor: "var(--t-bg)",
          color: "var(--t-text-muted)",
        }}
        role="group"
        aria-label="文字大小"
      >
        <span className="shrink-0">文字大小：</span>
        {(["small", "medium", "large"] as const).map((size) => (
          <button
            key={size}
            type="button"
            onClick={() => handleFontSize(size)}
            className="rounded px-2 py-0.5 font-medium transition-colors hover:underline"
            style={{
              backgroundColor: fontSize === size ? "var(--t-border)" : "transparent",
              color: fontSize === size ? "var(--t-text)" : "var(--t-text-muted)",
            }}
            aria-pressed={fontSize === size}
          >
            {size === "small" ? "小" : size === "medium" ? "中" : "大"}
          </button>
        ))}
      </div>
      <MarkdownRenderer content={content} fontSize={fontSize} />
    </div>
  );

  if (toc.length === 0) {
    return renderContent();
  }

  return (
    <div className="flex gap-6">
      {/* 左側目錄：sticky 不隨滾輪移動 */}
      <aside
        className="shrink-0 w-56 self-start sticky top-6 hidden lg:block"
        aria-label="本頁標題目錄"
      >
        <nav
          className="rounded-lg border py-3 px-3 text-sm max-h-[calc(100vh-4rem)] overflow-y-auto"
          style={{
            borderColor: "var(--t-border)",
            backgroundColor: "var(--t-bg-card)",
          }}
        >
          <div className="mb-2 flex items-center justify-between">
            <button
              type="button"
              className="text-[11px] hover:underline"
              style={{ color: "var(--t-text-muted)" }}
              onClick={() => {
                if (typeof window !== "undefined") {
                  window.history.back();
                }
              }}
            >
              回上一層
            </button>
            <div
              className="text-xs font-semibold uppercase tracking-wide"
              style={{ color: "var(--t-text-muted)" }}
            >
              目錄
            </div>
          </div>
          <ul className="space-y-1.5">
            {toc.map((item) => (
              <li key={item.id}>
                <TocLink item={item} />
              </li>
            ))}
          </ul>
          <button
            type="button"
            className="mt-3 w-full text-left hover:underline"
            style={{
              fontSize: "0.75rem",
              color: "var(--t-text-muted)",
            }}
            onClick={() => {
              if (typeof window !== "undefined") {
                window.scrollTo({ top: 0, behavior: "smooth" });
              }
            }}
          >
            回到最上層
          </button>
        </nav>
      </aside>

      {/* 右側 Markdown 內容 */}
      {renderContent()}
    </div>
  );
}

function TocLink({ item }: { item: TocItem }) {
  const paddingLeft =
    item.level === 1 ? "0" : item.level === 2 ? "0.75rem" : "1.25rem";
  const href = `#${item.id}`;

  return (
    <a
      href={href}
      className="block truncate py-0.5 hover:underline"
      style={{
        paddingLeft,
        color: "var(--t-text-muted)",
        fontSize: item.level === 1 ? "0.8125rem" : "0.75rem",
      }}
      onClick={(e) => {
        const headings = Array.from(
          document.querySelectorAll(
            "article.md-content h1[id], article.md-content h2[id], article.md-content h3[id], article.md-content h4[id], article.md-content h5[id], article.md-content h6[id]"
          )
        ) as HTMLElement[];

        const target =
          document.getElementById(item.id) as HTMLElement | null ||
          (document.getElementById(`${item.id}-2`) as HTMLElement | null) ||
          headings.find((h) => h.textContent?.trim() === item.text.trim()) ||
          null;

        if (target) {
          e.preventDefault();
          target.scrollIntoView({ behavior: "smooth", block: "start" });
          if (typeof window !== "undefined" && window.history?.replaceState) {
            window.history.replaceState(null, "", `#${target.id}`);
          }
        }
      }}
    >
      {item.text}
    </a>
  );
}

