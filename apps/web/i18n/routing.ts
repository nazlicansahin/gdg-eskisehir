import { defineRouting } from "next-intl/routing";

/** Locales in UI order; add new languages here and add `messages/<locale>.json`. */
export const routing = defineRouting({
  locales: ["en", "tr"],
  defaultLocale: "en",
  localePrefix: "always",
});
