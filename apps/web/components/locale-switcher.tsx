"use client";

import { useLocale, useMessages } from "next-intl";
import { Link, usePathname } from "@/i18n/navigation";
import { routing } from "@/i18n/routing";

type Messages = {
  localeSwitcher: {
    label: string;
    /** Display label per locale code; add keys when adding languages. */
    names: Record<string, string>;
  };
};

export function LocaleSwitcher() {
  const messages = useMessages() as Messages;
  const pathname = usePathname();
  const locale = useLocale();
  const { label, names } = messages.localeSwitcher;

  return (
    <div className="locale-switcher" aria-label={label}>
      <span>{label}</span>
      <span role="group">
        {routing.locales.map((loc) => (
          <Link
            key={loc}
            href={pathname}
            locale={loc}
            scroll={false}
            data-active={locale === loc ? "true" : undefined}
          >
            {names[loc] ?? loc}
          </Link>
        ))}
      </span>
    </div>
  );
}
