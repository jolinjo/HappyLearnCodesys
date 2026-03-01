import type { ReactNode } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import rehypeRaw from "rehype-raw";
import { slugify } from "@/lib/markdownToc";

function getTextFromNode(node: import("hast").Element): string {
  let text = "";
  for (const child of node.children || []) {
    if (child.type === "text") text += child.value;
    if (child.type === "element") text += getTextFromNode(child);
  }
  return text;
}

/** 從 React 的 children 取出純文字，供標題 id 計算（與 TOC parseHeadings 一致） */
function getTextFromReactChildren(children: ReactNode): string {
  if (typeof children === "string") return children;
  if (Array.isArray(children))
    return children.map(getTextFromReactChildren).join("");
  if (
    children != null &&
    typeof children === "object" &&
    "props" in children &&
    (children as { props?: { children?: ReactNode } }).props?.children != null
  )
    return getTextFromReactChildren(
      (children as { props: { children: ReactNode } }).props.children
    );
  return "";
}

/** 組件層級：依標題文字產生 id（與 TOC 相同 slugify + 重複編號），確保 DOM 有 id 供錨點使用 */
const headingIdSeen = new Map<string, number>();

function headingId(children: ReactNode): string | undefined {
  const text = getTextFromReactChildren(children).trim();
  if (!text) return undefined;
  let id = slugify(text);
  if (headingIdSeen.has(id)) {
    const n = headingIdSeen.get(id)! + 1;
    headingIdSeen.set(id, n);
    id = `${id}-${n}`;
  } else {
    headingIdSeen.set(id, 1);
  }
  return id;
}

/** 為 h1～h3 加上 id，供左側 TOC 錨點使用 */
function rehypeAddHeadingIds() {
  const seen = new Map<string, number>();
  return (tree: import("hast").Root) => {
    function visit(node: import("hast").Root | import("hast").Element): void {
      if (node.type !== "element") return;
      const el = node as import("hast").Element;
      if (el.tagName === "h1" || el.tagName === "h2" || el.tagName === "h3") {
        const text = getTextFromNode(el).trim();
        if (text) {
          let id = slugify(text);
          if (seen.has(id)) {
            const n = seen.get(id)! + 1;
            seen.set(id, n);
            id = `${id}-${n}`;
          } else {
            seen.set(id, 1);
          }
          (el.properties as Record<string, unknown>) = el.properties || {};
          (el.properties as Record<string, string>).id = id;
        }
      }
      for (const child of (el.children || []) as import("hast").Element[]) {
        if (child.type === "element") visit(child);
      }
    }
    visit(tree);
  };
}

/** 移除 MD 內的 <style>，避免覆蓋全站樣式；顏色改由 globals.css 的 .md-content .cfg-* 提供 */
function rehypeRemoveStyle() {
  return (tree: import("hast").Root) => {
    function filterStyle(node: { children?: import("hast").Root["children"] }): void {
      const children = node.children;
      if (!Array.isArray(children)) return;
      node.children = children.filter((child) => {
        if (child.type === "element") {
          if (child.tagName === "style") return false;
          filterStyle(child);
        }
        return true;
      });
    }
    filterStyle(tree);
  };
}

export type MarkdownFontSize = "small" | "medium" | "large";

export interface MarkdownRendererProps {
  content: string;
  /** 文字大小，未傳則為 medium；由 MarkdownWithToc 傳入並可持久化 */
  fontSize?: MarkdownFontSize;
}

export function MarkdownRenderer({ content, fontSize = "medium" }: MarkdownRendererProps) {
  headingIdSeen.clear();
  const sizeClass =
    fontSize === "small"
      ? "md-content--size-small"
      : fontSize === "large"
        ? "md-content--size-large"
        : "";
  return (
    <article
      className={`prose max-w-none md-content ${sizeClass}`.trim()}
      style={{ color: "var(--t-text)" }}
    >
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        rehypePlugins={[rehypeRaw, rehypeAddHeadingIds, rehypeRemoveStyle]}
        components={markdownComponents}
      >
        {content}
      </ReactMarkdown>
    </article>
  );
}

const markdownComponents: Parameters<typeof ReactMarkdown>[0]["components"] = {
  h1({ children, node }) {
    const id =
      (node?.properties as { id?: string } | undefined)?.id ?? headingId(children);
    return (
      <h1 id={id} className="text-2xl font-semibold scroll-mt-6" style={{ color: "var(--t-text)" }}>
        {children}
      </h1>
    );
  },
  h2({ children, node }) {
    const id =
      (node?.properties as { id?: string } | undefined)?.id ?? headingId(children);
    return (
      <h2 id={id} className="mt-6 text-xl font-semibold scroll-mt-6" style={{ color: "var(--t-text)" }}>
        {children}
      </h2>
    );
  },
  h3({ children, node }) {
    const id =
      (node?.properties as { id?: string } | undefined)?.id ?? headingId(children);
    return (
      <h3
        id={id}
        className="mt-4 text-lg font-semibold scroll-mt-6"
        style={{ color: "var(--t-text)" }}
      >
        {children}
      </h3>
    );
  },
  p({ children }) {
    return <p className="my-2 leading-relaxed">{children}</p>;
  },
  ul({ children }) {
    return (
      <ul className="my-2 ml-6 list-disc space-y-1">
        {children}
      </ul>
    );
  },
  ol({ children }) {
    return (
      <ol className="my-2 ml-6 list-decimal space-y-1">
        {children}
      </ol>
    );
  },
  li({ children }) {
    return <li className="leading-relaxed">{children}</li>;
  },
  code({ className, children, ...props }) {
    const inline = !className?.startsWith("language-");
    if (inline) {
      return (
        <code
          className="rounded px-1 py-0.5"
          style={{
            backgroundColor: "var(--t-border)",
            color: "var(--t-text)",
          }}
          {...props}
        >
          {children}
        </code>
      );
    }

    return (
      <pre
        className="overflow-x-auto rounded-lg border p-3 text-sm leading-relaxed"
        style={{
          borderColor: "var(--t-border)",
          backgroundColor: "var(--t-bg-code)",
        }}
      >
        <code className={className} {...props}>
          {children}
        </code>
      </pre>
    );
  },
  table({ children }) {
    return (
      <div
        className="my-3 overflow-x-auto rounded border"
        style={{ borderColor: "var(--t-border)" }}
      >
        <table className="w-full text-sm">{children}</table>
      </div>
    );
  },
  th({ children }) {
    return (
      <th
        className="border-b px-2 py-1 text-left text-xs font-semibold"
        style={{
          borderColor: "var(--t-border)",
          backgroundColor: "var(--t-bg-code)",
          color: "var(--t-text)",
        }}
      >
        {children}
      </th>
    );
  },
  td({ children }) {
    return (
      <td
        className="border-b px-2 py-1 text-xs"
        style={{
          borderColor: "var(--t-border)",
          color: "var(--t-text)",
        }}
      >
        {children}
      </td>
    );
  },
};

