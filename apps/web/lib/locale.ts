import { routing } from "@/i18n/routing";

/** Union of configured locales; extend by editing `i18n/routing` and adding `messages/<locale>.json`. */
export type AppLocale = (typeof routing.locales)[number];

export function isAppLocale(locale: string | undefined): locale is AppLocale {
  return (
    typeof locale === "string" &&
    (routing.locales as readonly string[]).includes(locale)
  );
}
