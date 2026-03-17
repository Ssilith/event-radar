const GEODB_BASE = "https://wft-geo-db.p.rapidapi.com";

function setCors(res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
}

export default async function handler(req, res) {
  setCors(res);

  if (req.method === "OPTIONS") return res.status(204).end();
  if (req.method !== "GET") return res.status(405).json({ error: "GET only" });

  const { path, ...params } = req.query;
  if (!path)
    return res.status(400).json({ error: "'path' query param required" });

  const upstream = new URL(`${GEODB_BASE}${path}`);
  Object.entries(params).forEach(([k, v]) => upstream.searchParams.set(k, v));

  try {
    const r = await fetch(upstream.toString(), {
      headers: {
        "X-RapidAPI-Key": process.env.GEODB_API_KEY,
        "X-RapidAPI-Host": "wft-geo-db.p.rapidapi.com",
      },
    });

    const data = await r.text();

    setCors(res);
    res.setHeader("Content-Type", "application/json");
    res.setHeader(
      "Cache-Control",
      "public, max-age=86400, stale-while-revalidate=3600", //* 24h
    );
    return res.status(r.status).send(data);
  } catch (err) {
    console.error("GeoDB proxy error:", err);
    return res.status(502).json({ error: "Failed to reach GeoDB" });
  }
}
