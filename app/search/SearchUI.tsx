"use client";

import { useState, useEffect, useCallback } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";

const BASE = typeof process !== "undefined" ? (process.env.NEXT_PUBLIC_BASE_PATH || "") : "";

interface SearchResultItem {
  url: string;
  title: string;
  snippet: string;
}

interface SearchIndexEntry {
  url: string;
  title: string;
  content: string;
}

function snippetAround(text: string, query: string, maxLen = 200): string {
  const lower = text.toLowerCase();
  const q = query.trim().toLowerCase();
  if (!q) return text.slice(0, maxLen);
  const idx = lower.indexOf(q);
  if (idx === -1) return text.slice(0, maxLen);
  const start = Math.max(0, idx - 60);
  const end = Math.min(text.length, idx + q.length + 140);
  let s = text.slice(start, end);
  if (start > 0) s = "…" + s;
  if (end < text.length) s = s + "…";
  return s;
}

interface SearchUIProps {
  initialQuery: string;
}

export function SearchUI({ initialQuery }: SearchUIProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [query, setQuery] = useState(initialQuery);
  const [results, setResults] = useState<SearchResultItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [searched, setSearched] = useState(false);
  const [index, setIndex] = useState<SearchIndexEntry[] | null>(null);

  const runSearch = useCallback(
    async (q: string) => {
      if (!q.trim()) {
        setResults([]);
        setSearched(true);
        return;
      }
      setLoading(true);
      setSearched(true);
      try {
        let idx = index;
        if (idx === null) {
          const res = await fetch(`${BASE}/search-index.json`);
          const data: SearchIndexEntry[] = await res.json();
          setIndex(data);
          idx = data;
        }
        if (!idx) {
          setResults([]);
          return;
        }
        const qLower = q.trim().toLowerCase();
        const list: SearchResultItem[] = [];
        for (const entry of idx) {
          if (!entry.content.toLowerCase().includes(qLower)) continue;
          list.push({
            url: entry.url,
            title: entry.title,
            snippet: snippetAround(entry.content, q.trim()),
          });
        }
        setResults(list);
      } catch {
        setResults([]);
      } finally {
        setLoading(false);
      }
    },
    [index],
  );

  useEffect(() => {
    const q = searchParams.get("q") ?? "";
    setQuery(q);
    if (q) runSearch(q);
    else setSearched(false);
  }, [searchParams, runSearch]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const q = query.trim();
    router.push(q ? `/search?q=${encodeURIComponent(q)}` : "/search");
    if (q) runSearch(q);
  };

  return (
    <>
      <form onSubmit={handleSubmit} className="flex gap-2">
        <input
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="輸入函數名稱或關鍵字，例如 MC_GearInPos、安全控制"
          className="flex-1 rounded-md border px-3 py-2 text-sm focus:outline-none focus:ring-1"
          style={{
            borderColor: "var(--t-input-border)",
            backgroundColor: "var(--t-input-bg)",
            color: "var(--t-text)",
          }}
          aria-label="搜尋關鍵字"
        />
        <button
          type="submit"
          className="rounded-md px-4 py-2 text-sm font-medium text-white"
          style={{ backgroundColor: "var(--t-accent)" }}
          title="執行搜尋"
          aria-label="執行搜尋"
        >
          搜尋
        </button>
      </form>

      {loading && (
        <p className="text-sm" style={{ color: "var(--t-text-muted)" }}>
          搜尋中…
        </p>
      )}

      {!loading && searched && (
        <section className="space-y-3">
          {results.length === 0 ? (
            <p className="text-sm" style={{ color: "var(--t-text-muted)" }}>
              {query.trim() ? "沒有找到符合的結果，可試試其他關鍵字。" : "輸入關鍵字後按搜尋。"}
            </p>
          ) : (
            <ul className="space-y-2">
              {results.map((r, i) => (
                <li key={`${r.url}-${r.title}-${i}`}>
                  <Link
                    href={r.url}
                    className="block rounded-lg border p-3 transition hover:opacity-90"
                    style={{
                      borderColor: "var(--t-border)",
                      backgroundColor: "var(--t-bg-card)",
                    }}
                  >
                    <div className="font-medium" style={{ color: "var(--t-accent)" }}>
                      {r.title}
                    </div>
                    <div className="mt-1 text-xs" style={{ color: "var(--t-text-muted)" }}>
                      {r.url}
                    </div>
                    <p
                      className="mt-1.5 line-clamp-2 text-sm leading-relaxed"
                      style={{ color: "var(--t-text-muted)" }}
                    >
                      {r.snippet}
                    </p>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </section>
      )}
    </>
  );
}
