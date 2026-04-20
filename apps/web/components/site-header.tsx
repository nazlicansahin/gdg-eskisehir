import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import { LocaleSwitcher } from "@/components/locale-switcher";

export async function SiteHeader() {
  const brand = await getTranslations("LocaleLayout");
  const nav = await getTranslations("nav");

  return (
    <header className="site-header">
      <div className="brand">
        <Link href="/">{brand("title")}</Link>
      </div>
      <div
        style={{
          display: "flex",
          flexWrap: "wrap",
          alignItems: "center",
          gap: "1rem",
        }}
      >
        <nav className="nav" aria-label="Primary">
          <Link href="/">{nav("home")}</Link>
          <Link href="/privacy">{nav("privacy")}</Link>
          <Link href="/terms">{nav("terms")}</Link>
          <Link href="/support">{nav("support")}</Link>
        </nav>
        <LocaleSwitcher />
      </div>
    </header>
  );
}
