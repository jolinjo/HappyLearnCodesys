"use client";

import { useState } from "react";

export interface StCodeBlockProps {
  title: string;
  html: string;
}

const MIN_FONT_SIZE = 12;
const MAX_FONT_SIZE = 20;
const DEFAULT_FONT_SIZE = 14;

export function StCodeBlock({ title, html }: StCodeBlockProps) {
  const [open, setOpen] = useState(false);
  const [fontSize, setFontSize] = useState(DEFAULT_FONT_SIZE);
  const [fullscreen, setFullscreen] = useState(false);

  return (
    <>
      <div
        className="rounded-lg border overflow-hidden"
        style={{
          borderColor: "var(--t-border)",
          backgroundColor: "var(--t-bg-code)",
        }}
      >
        <button
          type="button"
          onClick={() => setOpen((o) => !o)}
          className="flex w-full items-center justify-between gap-2 px-3 py-2 text-left text-sm font-medium transition"
          style={{ color: "var(--t-text)" }}
        >
          <span className="truncate">{title}</span>
          <span
            className={`shrink-0 transition-transform ${open ? "rotate-180" : ""}`}
            style={{ color: "var(--t-text-muted)" }}
            aria-hidden
          >
            ▼
          </span>
        </button>

        {open && (
          <div style={{ borderColor: "var(--t-border)" }} className="border-t">
            <div
              className="flex items-center justify-end gap-1 px-2 py-1"
              style={{ backgroundColor: "var(--t-bg-card)" }}
            >
              <button
                type="button"
                onClick={() => setFontSize((s) => Math.max(MIN_FONT_SIZE, s - 1))}
                className="rounded px-2 py-0.5 text-xs hover:opacity-80"
                style={{ color: "var(--t-text-muted)" }}
                title="字體縮小"
                aria-label="字體縮小"
              >
                A−
              </button>
              <button
                type="button"
                onClick={() => setFontSize((s) => Math.min(MAX_FONT_SIZE, s + 1))}
                className="rounded px-2 py-0.5 text-xs hover:opacity-80"
                style={{ color: "var(--t-text-muted)" }}
                title="字體放大"
                aria-label="字體放大"
              >
                A+
              </button>
              <button
                type="button"
                onClick={() => setFullscreen(true)}
                className="rounded px-2 py-0.5 text-xs hover:opacity-80"
                style={{ color: "var(--t-text-muted)" }}
                title="全螢幕檢視程式碼"
                aria-label="全螢幕檢視程式碼"
              >
                放大
              </button>
            </div>
            <div
              className="overflow-x-auto overflow-y-auto max-h-[60vh] rounded-b-lg bg-white p-3"
              style={{ fontSize: `${fontSize}px` }}
            >
              <div
                className="shiki-code [&_pre]:!m-0 [&_pre]:!p-0 [&_pre]:!bg-transparent [&_pre]:!text-[inherit]"
                dangerouslySetInnerHTML={{ __html: html }}
              />
            </div>
          </div>
        )}
      </div>

      {fullscreen && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4"
          role="dialog"
          aria-modal="true"
          aria-label="程式碼全螢幕檢視"
        >
          <div
            className="relative flex max-h-full w-full max-w-4xl flex-col rounded-lg border shadow-xl"
            style={{
              borderColor: "var(--t-border)",
              backgroundColor: "var(--t-bg-code)",
            }}
          >
            <div
              className="flex items-center justify-between border-b px-3 py-2"
              style={{ borderColor: "var(--t-border)" }}
            >
              <span className="text-sm font-medium" style={{ color: "var(--t-text)" }}>
                {title}
              </span>
              <button
                type="button"
                onClick={() => setFullscreen(false)}
                className="rounded px-2 py-1 text-xs hover:opacity-80"
                style={{ color: "var(--t-text-muted)" }}
                title="關閉全螢幕"
                aria-label="關閉全螢幕"
              >
                關閉
              </button>
            </div>
            <div
              className="overflow-auto flex-1 bg-white p-4"
              style={{ fontSize: `${fontSize}px` }}
            >
              <div
                className="shiki-code [&_pre]:!m-0 [&_pre]:!p-0 [&_pre]:!bg-transparent [&_pre]:!text-[inherit]"
                dangerouslySetInnerHTML={{ __html: html }}
              />
            </div>
          </div>
        </div>
      )}
    </>
  );
}
