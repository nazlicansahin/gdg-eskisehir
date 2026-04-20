import { getMessages, getTranslations, setRequestLocale } from "next-intl/server";
import type { LegalSection } from "@/lib/legal";

export type LegalNamespace = "privacy" | "support" | "terms";

type Props = {
  locale: string;
  namespace: LegalNamespace;
};

export async function LegalArticle({ locale, namespace }: Props) {
  setRequestLocale(locale);

  const t = await getTranslations({ locale, namespace });
  const messages = await getMessages();

  const sections = (
    messages as Record<string, { sections?: LegalSection[] } | undefined>
  )[namespace]?.sections;

  const date = t("lastUpdatedDate");

  return (
    <article className="prose">
      <h1>{t("title")}</h1>
      <p className="meta">{t("lastUpdatedLabel", { date })}</p>

      {sections?.map((section) => (
        <section key={section.id} id={section.id}>
          <h2>{section.title}</h2>
          {section.paragraphs.map((paragraph, index) => (
            <p key={`${section.id}-${index}`}>{paragraph}</p>
          ))}
        </section>
      ))}
    </article>
  );
}
