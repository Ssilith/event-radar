const GITHUB_PAGES = () =>
  `https://${process.env.GITHUB_OWNER}.github.io/${process.env.GITHUB_REPO}/datasets`;

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

export default async function handler(req, res) {
  if (req.method === "OPTIONS") {
    Object.entries(CORS).forEach(([k, v]) => res.setHeader(k, v));
    return res.status(204).end();
  }

  if (req.method !== "GET") {
    return res.status(405).json({ error: "GET only" });
  }

  const { path } = req.query;
  if (!path) {
    return res
      .status(400)
      .json({ error: "'path' query param required, e.g. ?path=wroclaw.json" });
  }

  if (!path.endsWith(".json")) {
    return res.status(400).json({ error: "Only .json files are allowed" });
  }

  const upstream = `${GITHUB_PAGES()}/${path}`;

  try {
    const r = await fetch(upstream, {
      headers: { "Cache-Control": "no-cache" },
    });

    if (!r.ok) {
      return res
        .status(r.status)
        .json({ error: `Upstream returned ${r.status}` });
    }

    const data = await r.text();

    Object.entries(CORS).forEach(([k, v]) => res.setHeader(k, v));
    res.setHeader("Content-Type", "application/json");
    res.setHeader(
      "Cache-Control",
      "public, max-age=1800, stale-while-revalidate=3600",
    );

    return res.status(200).send(data);
  } catch (err) {
    console.error("Proxy error:", err);
    return res.status(502).json({ error: "Failed to fetch from upstream" });
  }
}
