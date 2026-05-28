# Event Radar

Automatically discovers events from cities worldwide and serves them to a Flutter app. Zero server costs — everything runs on free tiers.

A monthly pipeline (GitHub Actions) reads publicly-available schema.org Event metadata that publishers embed in their pages, normalizes it, and publishes static JSON to GitHub Pages. When a user picks a city that hasn't been indexed yet, the app triggers an on-demand run through a Vercel function and polls until the data is ready (~2 minutes).

---

## Repo layout

```
event-radar/
├── app/             # Flutter mobile app (Android + iOS)
├── api/             # Vercel serverless functions (trigger + dataset proxy)
├── indexer/         # Python event-discovery pipeline run by GitHub Actions
├── cities.txt       # Cities to index monthly (one Name:CC per line)
└── .github/workflows/pipeline.yml
```

---

## How it works

### Monthly run (automatic)

GitHub Actions runs on the 1st of every month at 06:00 UTC. It reads every city from `cities.txt`, runs the discovery pipeline for each, and deploys the resulting JSON files to GitHub Pages.

### On-demand run (new city)

When a user picks a city that hasn't been indexed yet:

1. Flutter calls `POST /api/trigger` with `{ city: "Gdańsk", country_code: "PL" }`
2. Vercel checks `index.json` — city not found or data is stale
3. Vercel checks the GitHub Actions API — no run already in progress
4. Vercel triggers `workflow_dispatch` for `Gdańsk:PL`
5. GitHub Actions indexes Gdańsk and appends it to `cities.txt` (so it runs every month from now on)
6. Flutter polls `/api/datasets?path=index.json` every 15 seconds
7. When `gdansk.json` appears in the index, Flutter fetches and displays the events

Total time from tap to events: **~2 minutes**.

### Discovery strategy

The pipeline only reads what publishers have *explicitly* exposed for indexing — `<script type="application/ld+json">` Event objects embedded in event pages, per the [schema.org/Event](https://schema.org/Event) spec. Pages without structured data are skipped.

### City names and languages

Cities are passed as `Name:CC` (e.g. `Berlin:DE`, `Wrocław:PL`). The country code is looked up in `indexer/queries.json` to find the native language, and both English and native-language search queries are generated:

```
events in Berlin March 2026         ← English
Veranstaltungen Berlin März 2026    ← German
Konzerte Berlin 2026                ← German
```

This finds local event sites that English-only queries miss. 21 languages are supported.

### Deduplication

The same event often appears on multiple sites (venue website, ticketing platform, local listings). The pipeline deduplicates by `sha256(title + date + venue)` and keeps the most complete record.

### Geocoding

Venue coordinates come from the schema.org data embedded in event pages. For venues without coordinates, Photon is queried. Each unique venue is geocoded once per run — if `Berghain` appears across 20 events, only one API call is made.

### Timezones

Times are stored in UTC. Each dataset carries the venue's IANA timezone (e.g. `Europe/Warsaw`), resolved via `pytz.country_timezones[country_code]`. The Flutter app formats event times in the venue's timezone, not the phone's — a user in Tokyo browsing a Wrocław event sees `20:30`, not `03:30 next day`, with a `Warsaw time / your time` hint on the details screen.

Many event-listing pages emit broken `startDate` values (e.g. the WordPress "Modern Events Calendar" plugin double-applies the UTC offset, so a 20:30 Warsaw event becomes `22:30+02:00` in the JSON-LD). The pipeline compensates by reinterpreting the strict-parsed UTC components as venue-local wall-clock time. See `indexer/pipeline.py::EventNormalizer._to_utc`.

---

## Dataset format

Each city gets a JSON file at `datasets/{slug}.json`:

```json
{
  "city": "Berlin",
  "slug": "berlin",
  "country_code": "DE",
  "timezone": "Europe/Berlin",
  "generated_at": "2026-03-01T06:00:00+00:00",
  "count": 83,
  "events": [
    {
      "id": "a1b2c3d4e5f6g7h8",
      "title": "Boiler Room Berlin",
      "city": "berlin",
      "start": "2026-03-15T21:00:00+00:00",
      "end": "2026-03-16T05:00:00+00:00",
      "venue": "Tresor",
      "latitude": 52.5094,
      "longitude": 13.4194,
      "description": "...",
      "url": "https://...",
      "source": "residentadvisor.net",
      "price": "EUR 15",
      "category": "Music",
      "updated_at": "2026-03-01T06:00:00+00:00"
    }
  ]
}
```

`datasets/index.json` lists all available cities with their slugs, event counts, and last-updated timestamps. This is what Flutter and the Vercel trigger function use to look up whether a city exists.

---

## Flutter app

Feature-folder layout under `app/lib/`:

```
lib/
├── main.dart
├── core/
│   ├── config.dart
│   ├── models/        # Event, EventCategory, CityItem, CityDataState
│   ├── services/      # EventService, CityService, EventCacheService
│   ├── theme/         # AppColors, AppSpacing, AppText (typography)
│   └── utils/         # event_time, date_filter, log, language, page
├── features/
│   ├── discover/      # screen + per-feature widgets/
│   ├── map/
│   ├── saved/
│   ├── event_details/
│   └── home/
├── l10n/              # ARB files + generated/ (en, pl)
└── widgets/           # shared widgets: CategoryChip, StatusView, AsyncStateView, …
```

### Localization

Two locales today: English (template) and Polish. The device locale is auto-detected at startup. Add a new locale by dropping `lib/l10n/app_<code>.arb` next to the existing ones and running `flutter gen-l10n`.

Plural-sensitive keys use ICU syntax (`{count, plural, =1{...} few{...} many{...} other{...}}`) so Polish gets correct grammar.

### Persistence

Hive boxes:
- `bookmarks` — saved events (encoded `Event.toJson()`)
- `recent_cities` — recently-picked cities

### Local config

`app/lib/core/config.dart` reads from `--dart-define`:
- `VERCEL_BASE` — base URL of your Vercel deployment, e.g. `https://event-radar.vercel.app`

---

## Running locally

### Flutter app

```bash
cd app
flutter pub get
flutter gen-l10n
flutter run --dart-define=VERCEL_BASE=https://your-deploy.vercel.app
```

### Vercel API (local dev)

```bash
cd api
npm install
vercel dev
```

`.env.local` needs:
```
GITHUB_OWNER=<your-gh-user>
GITHUB_REPO=event-radar
GITHUB_TOKEN=<PAT with workflow + contents:write scopes>
```

### Discovery pipeline (one-off run)

```bash
cd indexer
python -m venv .venv
.venv\Scripts\Activate.ps1            # PowerShell
# source .venv/bin/activate           # bash
pip install -r requirements.txt
python main.py --city "Wrocław:PL"
```

Set `TAVILY_API_KEY` in your environment first (get one at https://tavily.com).

---

## Deployment

- **Indexer:** GitHub Actions (`.github/workflows/pipeline.yml`). Secrets required: `TAVILY_API_KEY`. Output goes to GitHub Pages.
- **API:** Vercel project pointing at `api/`. Env vars: `GITHUB_OWNER`, `GITHUB_REPO`, `GITHUB_TOKEN`.
- **App:** Flutter build for Android/iOS as usual.

---

## License

See `LICENSE`.
