import type { ReactNode } from "react";

interface OfflineHelpLayoutProps {
  children: ReactNode;
}

export default function OfflineHelpLayout({ children }: OfflineHelpLayoutProps) {
  // Offline Help 區域不再常駐左側導覽，改由 `/offline-help` 首頁作為獨立導覽頁。
  // 這裡只負責包一層，讓批次頁與文章頁可以全寬顯示內容。
  return <div className="min-w-0">{children}</div>;
}

