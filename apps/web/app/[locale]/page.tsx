import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";
import { Link } from "@/i18n/navigation";
import { isAppLocale } from "@/lib/locale";

type Props = { params: { locale: string } };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = params;
  if (!isAppLocale(locale)) {
    return {};
  }

  const t = await getTranslations({ locale, namespace: "home" });

  return {
    title: t("title"),
    description: t("lead"),
  };
}

export default async function HomePage({ params }: Props) {
  const { locale } = params;
  if (!isAppLocale(locale)) {
    return null;
  }

  setRequestLocale(locale);

  const t = await getTranslations({ locale, namespace: "home" });

  return (
    <div className="hero">
      <h1>{t("title")}</h1>
      <p>{t("lead")}</p>
      <div className="hero-actions">
        <Link className="button" href="/privacy">
          {t("ctaPrivacy")}
        </Link>
      </div>
      <nav className="hero-links" aria-label="Legal pages">
        <Link href="/terms">{t("ctaTerms")}</Link>
        <span aria-hidden className="hero-links-sep">
          ·
        </span>
        <Link href="/support">{t("ctaSupport")}</Link>
      </nav>
    </div>
  );
}
