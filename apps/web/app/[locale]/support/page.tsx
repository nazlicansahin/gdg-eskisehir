import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { LegalArticle } from "@/components/legal-article";
import { isAppLocale } from "@/lib/locale";

type Props = { params: { locale: string } };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = params;
  if (!isAppLocale(locale)) {
    return {};
  }

  const t = await getTranslations({ locale, namespace: "support" });

  return {
    title: t("title"),
    description: t("metaDescription"),
  };
}

export default async function SupportPage({ params }: Props) {
  const { locale } = params;
  if (!isAppLocale(locale)) {
    return null;
  }

  return <LegalArticle locale={locale} namespace="support" />;
}
