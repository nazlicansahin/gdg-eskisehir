import { getTranslations } from "next-intl/server";

export async function SiteFooter() {
  const t = await getTranslations("footer");

  return (
    <footer className="site-footer">
      <p className="site-footer-line">
        <span className="site-footer-name">{t("organiserName")}</span>
        <span className="site-footer-sep" aria-hidden>
          ·
        </span>
        <a className="site-footer-mail" href={`mailto:${t("organiserEmail")}`}>
          {t("organiserEmail")}
        </a>
      </p>
      <p className="site-footer-note">{t("note")}</p>
    </footer>
  );
}
