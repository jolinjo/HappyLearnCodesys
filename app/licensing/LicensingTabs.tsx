"use client";

import { useState } from "react";
import { MarkdownWithToc } from "@/components/MarkdownWithToc";

export interface LicensingTabItem {
  id: string;
  title: string;
  markdown: string;
}

interface LicensingTabsProps {
  items: LicensingTabItem[];
}

export function LicensingTabs({ items }: LicensingTabsProps) {
  const [activeId, setActiveId] = useState(items[0]?.id ?? "");

  const active = items.find((i) => i.id === activeId) ?? items[0];

  return (
    <div
      className="rounded-lg border"
      style={{
        borderColor: "var(--t-border)",
        backgroundColor: "var(--t-bg-card)",
      }}
    >
      <div
        className="flex border-b"
        style={{
          borderColor: "var(--t-border)",
          backgroundColor: "var(--t-bg-code)",
        }}
      >
        {items.map((item) => (
          <button
            key={item.id}
            type="button"
            onClick={() => setActiveId(item.id)}
            className="px-4 py-2.5 text-sm font-medium transition hover:opacity-90"
            style={
              activeId === item.id
                ? {
                    color: "var(--t-accent)",
                    backgroundColor: "var(--t-bg-card)",
                    borderBottom: "2px solid var(--t-accent)",
                  }
                : {
                    color: "var(--t-text-muted)",
                  }
            }
            title={`切換至：${item.title}`}
            aria-label={`切換至：${item.title}`}
          >
            {item.title}
          </button>
        ))}
      </div>
      <div className="p-4">
        {active && <MarkdownWithToc content={active.markdown} />}
      </div>
    </div>
  );
}
