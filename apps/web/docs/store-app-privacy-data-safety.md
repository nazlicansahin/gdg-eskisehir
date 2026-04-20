# App Store Connect & Play Console — privacy declarations (GDG Events)

Use this checklist together with the published **Privacy Policy** (`/en/privacy` or `/tr/privacy`). Align answers with what the app actually does; if you change behavior or SDKs, update both the policy and these forms.

**Official reference language:** English (`en` messages). Turkish is auxiliary.

---

## Apple — App Privacy (nutrition labels)

In App Store Connect → App Privacy, declare data collected **from this app** (including via third-party SDKs such as Firebase).

Suggested mappings for **GDG Events** (email/password auth, GraphQL backend, Firebase Auth + FCM push):

| Data type (Apple category) | Collected? | Linked to user? | Used for tracking? | Typical purpose |
|----------------------------|------------|-----------------|-------------------|-----------------|
| **Contact Info → Email Address** | Yes | Yes | No | Account login (Firebase Authentication). |
| **Contact Info → Name** | Yes | Yes | No | Display name you set in Profile (not necessarily legal name). |
| **Identifiers → User ID** | Yes | Yes | No | Firebase UID / internal user id for account and registrations. |
| **Identifiers → Device ID** | Optional | Yes | No | Only if Apple asks for device-level id — the app primarily uses **push tokens** via FCM; many teams map push token under **Other Data** instead. If unsure, mirror Google’s Data safety and keep consistent. |
| **Other User Content** | Yes | Yes | No | Event registrations, QR/ticket usage, check-in timestamps, announcements content you create as staff (if applicable). |
| **Usage Data** | Optional | Often No / N/A | No | Only if you add product analytics (e.g. Firebase Analytics); **currently not emphasized in policy** — if you do not run analytics SDK, answer **no** or not collected. |

**Tracking:** If you do not use App Tracking Transparency (ATT) / cross-app tracking, answer **No** for tracking across apps and websites of other companies.

**Linked to user:** Email, UID, profile name, registrations, push token (if collected) are **linked to the user’s identity** for app functionality.

**Privacy Policy URL:** your production HTTPS URL to the English policy, e.g. `https://<your-domain>/en/privacy`.

**Account deletion:** Policy and App Store listing should state users can delete the account **in-app** (Profile → Delete account, with password confirmation) and via **nnazlicansahin@gmail.com** if they cannot access the app.

---

## Google Play — Data safety

In Play Console → App content → **Data safety**, declare data collected or processed. Align with [User Data policy](https://support.google.com/googleplay/android-developer/answer/10787469).

Suggested baseline for this app:

**Data collected / shared**

- **Personal info:** Email address; Name (display name).
- **App activity:** App interactions related to events (registrations, tickets/QR, check-in) — use the closest categories Play offers (e.g. “Other actions” / app activity as described).
- **Device or other IDs:** If Play asks about **FCM registration token**, treat as an identifier used for **messages** (push notifications), linked to the account, **not** for ads (unless you add ads).

**Purpose:** Account management, app functionality, developer communications (optional), **push notifications** (with user consent per OS prompts).

**Optional:** Photos/videos, Location, Financial info — **No** unless you add those features.

**Encryption in transit:** Yes (HTTPS to your API).

**Account deletion:** Provide the same URL as privacy policy or a dedicated support URL; describe **in-app deletion** (Profile → Delete account) and support email **nnazlicansahin@gmail.com**.

**Data sharing:** Declare sharing with **Google** (Firebase Auth, FCM) as **service provider / required for app functionality**, not for advertising (unless you add ads).

---

## Support URL (stores)

Use your deployed **Support** page, e.g. `https://<your-domain>/en/support` (and mention Turkish `/tr/support` if you submit localized store listings).

---

## When you change the app

- Add a new SDK (e.g. Analytics, Crashlytics) → update **Privacy Policy** (`messages/en.json`) and **both** store questionnaires.
- Change retention or deletion behavior → update policy + forms.
