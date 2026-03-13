const STALE_MS = 30 * 24 * 60 * 60 * 1000;
const BASE_URL = () =>
  `https://${process.env.GITHUB_OWNER}.github.io/${process.env.GITHUB_REPO}/datasets`;

export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") return res.status(204).end();
  if (req.method !== "POST")
    return res.status(405).json({ error: "POST only" });

  const { city } = req.body || {};
  if (!city?.trim())
    return res.status(400).json({ error: "'city' field is required" });

  const cityName = city.trim();

  const entry = await findInIndex(cityName);

  if (entry) {
    const datasetUrl = `${BASE_URL()}/${entry.slug}.json`;
    const ageMs = Date.now() - new Date(entry.updated_at).getTime();

    if (ageMs < STALE_MS) {
      //* Fresh data already exists - no scrape needed
      return res.json({
        status: "fresh",
        city: entry.city,
        slug: entry.slug,
        count: entry.count,
        updated_at: entry.updated_at,
        dataset_url: datasetUrl,
      });
    }
  }

  //* Trigger GitHub Actions workflow_dispatch
  const ghRes = await fetch(
    `https://api.github.com/repos/${process.env.GITHUB_OWNER}/${process.env.GITHUB_REPO}/actions/workflows/pipeline.yml/dispatches`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
        Accept: "application/vnd.github+json",
        "Content-Type": "application/json",
        "X-GitHub-Api-Version": "2022-11-28",
      },
      body: JSON.stringify({
        ref: "main",
        inputs: { cities: cityName, days_ahead: "90" },
      }),
    },
  );

  if (!ghRes.ok) {
    const detail = await ghRes.text();
    console.error("GitHub API error:", ghRes.status, detail);
    return res
      .status(502)
      .json({ error: "Failed to trigger pipeline", detail });
  }

  return res.json({
    status: "triggered",
    city: cityName,
    message:
      "Scrape started. Poll index_url every 15s - usually ready in ~2 minutes.",
    index_url: `${BASE_URL()}/index.json`,
  });
}

async function findInIndex(cityName) {
  try {
    const res = await fetch(`${BASE_URL()}/index.json`);
    if (!res.ok) return null;
    const data = await res.json();
    const needle = cityName.toLowerCase();
    return data.cities?.find((c) => c.city?.toLowerCase() === needle) ?? null;
  } catch {
    return null;
  }
}
