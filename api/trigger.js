const STALE_MS = 30 * 24 * 60 * 60 * 1000; //* 30 days

const BASE_URL = () =>
  `https://${process.env.GITHUB_OWNER}.github.io/${process.env.GITHUB_REPO}/datasets`;
const GITHUB_API = () =>
  `https://api.github.com/repos/${process.env.GITHUB_OWNER}/${process.env.GITHUB_REPO}`;

const GH_HEADERS = {
  Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
  Accept: "application/vnd.github+json",
  "Content-Type": "application/json",
  "X-GitHub-Api-Version": "2022-11-28",
};

export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") return res.status(204).end();
  if (req.method !== "POST")
    return res.status(405).json({ error: "POST only" });

  const { city, country_code } = req.body || {};
  if (!city?.trim())
    return res.status(400).json({ error: "'city' field is required" });

  const cityName = city.trim();
  const cc = (country_code || "").trim().toUpperCase();
  const cityArg = cc ? `${cityName}:${cc}` : cityName;

  const entry = await findInIndex(cityName);
  if (entry) {
    const ageMs = Date.now() - new Date(entry.updated_at).getTime();
    if (ageMs < STALE_MS) {
      return res.json({
        status: "fresh",
        city: entry.city,
        slug: entry.slug,
        count: entry.count,
        updated_at: entry.updated_at,
        dataset_url: `${BASE_URL()}/${entry.slug}.json`,
      });
    }
  }

  const alreadyRunning = await isWorkflowRunning(cityName);
  if (alreadyRunning) {
    return res.json({
      status: "already_running",
      city: cityName,
      message: "A scrape is already in progress. Poll index_url every 15s.",
      index_url: `${BASE_URL()}/index.json`,
    });
  }
  const ghRes = await fetch(
    `${GITHUB_API()}/actions/workflows/pipeline.yml/dispatches`,
    {
      method: "POST",
      headers: GH_HEADERS,
      body: JSON.stringify({
        ref: "main",
        inputs: { cities: cityArg, days_ahead: "90" },
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
      "Scrape started. Poll index_url every 15s — usually ready in ~2 minutes.",
    index_url: `${BASE_URL()}/index.json`,
  });
}

async function isWorkflowRunning(cityName) {
  try {
    const r = await fetch(
      `${GITHUB_API()}/actions/workflows/pipeline.yml/runs?status=in_progress&per_page=10`,
      { headers: GH_HEADERS },
    );
    if (!r.ok) return false;

    const data = await r.json();
    const tenMinutesAgo = Date.now() - 10 * 60 * 1000;

    return (
      data.workflow_runs?.some((run) => {
        const startedAt = new Date(run.created_at).getTime();
        if (startedAt < tenMinutesAgo) return false;
        return run.status === "in_progress" || run.status === "queued";
      }) ?? false
    );
  } catch {
    return false;
  }
}

async function findInIndex(cityName) {
  try {
    const r = await fetch(`${BASE_URL()}/index.json`);
    if (!r.ok) return null;
    const data = await r.json();
    const needle = cityName.toLowerCase();
    return data.cities?.find((c) => c.city?.toLowerCase() === needle) ?? null;
  } catch {
    return null;
  }
}
