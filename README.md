# Event Radar

Automatically discovers events from cities worldwide and serves them to a Flutter app. Zero server costs - everything runs on free tiers.

The scraper runs on GitHub Actions once a month and publishes static JSON to GitHub Pages. When a user picks a city that hasn't been scraped yet, the app triggers an on-demand scrape through a Vercel function and polls until the data is ready (~2 minutes).

---

## How It Works

### Monthly scrape (automatic)

GitHub Actions runs on the 1st of every month at 06:00 UTC. It reads every city from `cities.txt`, runs the Python scraper for each one, and deploys the resulting JSON files to GitHub Pages.

### On-demand scrape (new city)

When a user picks a city that hasn't been scraped yet:

1. Flutter calls `POST /api/trigger` with `{ city: "Gdańsk", country_code: "PL" }`
2. Vercel checks `index.json` — city not found or data is stale
3. Vercel checks the GitHub Actions API — no run already in progress
4. Vercel triggers `workflow_dispatch` for `Gdańsk:PL`
5. GitHub Actions scrapes Gdańsk and appends it to `cities.txt` (so it runs every month from now on)
6. Flutter polls `/api/datasets?path=index.json` every 15 seconds
7. When `gdansk.json` appears in the index, Flutter fetches and displays the events

Total time from tap to events: **~2 minutes**.

### City names and languages

Cities are passed as `Name:CC` (e.g. `Berlin:DE`, `Wrocław:PL`). The scraper uses the country code to look up the native language in `scraper/queries.json` and generates both English and native-language search queries:

```
events in Berlin March 2026         ← English
Veranstaltungen Berlin März 2026    ← German
Konzerte Berlin 2026                ← German
```

This finds local event sites that English-only queries miss. 21 languages are supported.

### Deduplication

The same event often appears on multiple sites (venue website, Ticketmaster, local listings). The scraper deduplicates by `sha256(title + date + venue)` and keeps the most complete record.

### Geocoding

Venue coordinates come from the schema.org data embedded in event pages. For venues without coordinates, the scraper calls Photon. Each unique venue is geocoded once per run — if `Berghain` appears across 20 events, only one API call is made.

---

## Dataset Format

Each city gets a JSON file at `datasets/{slug}.json`:

```json
{
  "city": "Berlin",
  "slug": "berlin",
  "generated_at": "2026-03-01T06:00:00+00:00",
  "count": 83,
  "events": [
    {
      "id": "a1b2c3d4e5f6g7h8",
      "title": "Boiler Room Berlin",
      "city": "berlin",
      "start": "2026-03-15T22:00:00",
      "end": "2026-03-16T06:00:00",
      "venue": "Tresor",
      "latitude": 52.5094,
      "longitude": 13.4194,
      "description": "...",
      "url": "https://...",
      "source": "residentadvisor.net",
      "price": "EUR 15",
      "updated_at": "2026-03-01T06:00:00+00:00"
    }
  ]
}
```

`datasets/index.json` lists all available cities with their slugs, event counts, and last-updated timestamps. This is what Flutter and the Vercel trigger function use to look up whether a city exists.

---
