# User-Facing Website (Phase 1)

## Run locally

```bash
cd apps/web
npm install
npm run dev
```

- App: [http://localhost:3000](http://localhost:3000) — middleware redirects to a locale (e.g. `/en`).
- Legal pages (copy in `messages/*.json`; English is reference): `/en/privacy`, `/en/terms`, `/en/support` (and `/tr/...`).
- Store questionnaires: see [docs/store-app-privacy-data-safety.md](docs/store-app-privacy-data-safety.md).

**Before production:** copy [`.env.example`](.env.example) to `.env.local` and set `NEXT_PUBLIC_SITE_URL` to your **HTTPS** origin (no trailing slash), e.g. `https://events.yourdomain.com`. This sets `metadataBase` in `app/[locale]/layout.tsx` and keeps [`app/sitemap.ts`](app/sitemap.ts) / [`app/robots.ts`](app/robots.ts) consistent.

## Localization (adding a language)

1. Add the locale to [i18n/routing.ts](i18n/routing.ts) `locales` (keep `defaultLocale` as needed).
2. Add `messages/<locale>.json` by copying an existing file and translating all keys. **Do not** change key names—only values.
3. Add a display name under `localeSwitcher.names.<locale>` in **every** message file so the language switcher can show a label.
4. Rebuild; `generateStaticParams` in the locale layout will pick up the new segment.

Stack: [next-intl](https://next-intl.dev) (message files + `app/[locale]/...` routes).

## Product boundary

This is a user-facing product, not a marketing-only landing page.

## Route map

Implemented:

- `/[locale]` — home (e.g. `/en`, `/tr`)
- `/[locale]/privacy` — privacy policy (store / GDPR-facing)
- `/[locale]/terms` — terms of use
- `/[locale]/support` — support contact (stores may ask for a support URL)

Planned (see product boundary):

- `/events`
- `/events/[id]`
- `/events/[id]/schedule`
- `/speakers`
- `/speakers/[id]`
- `/tickets`
- `/profile`
- `/auth/*`

## Experience differences vs mobile

Allowed differences:

- denser list/table layouts
- richer filtering/search on larger screens
- keyboard navigation improvements

Not allowed differences:

- any mismatch in core domain behavior (registration, capacity, visibility, QR validity)

## Security guardrail

- Only public config can go to browser bundles.
- Any secret-bearing operation must execute server-side or via backend API.
