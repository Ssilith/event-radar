import { setCors } from "./cors.js";
import { BASE_URL } from "./github.js";

export default async function handler(req, res) {
  setCors(res);

  if (req.method === "OPTIONS") return res.status(204).end();
  if (req.method !== "GET") return res.status(405).json({ error: "GET only" });

  const { path } = req.query;
  if (!path) return res.status(400).json({ error: "'path' required" });
  if (!path.endsWith(".json"))
    return res.status(400).json({ error: ".json only" });

  try {
    const r = await fetch(`${BASE_URL()}/${path}`);
    if (!r.ok)
      return res.status(r.status).json({ error: `Upstream ${r.status}` });

    const data = await r.text();
    res.setHeader("Content-Type", "application/json");

    if (path === "index.json") {
      res.setHeader("Cache-Control", "no-store");
    } else {
      res.setHeader(
        "Cache-Control",
        "public, max-age=1800, stale-while-revalidate=3600", //* 30 mins
      );
    }

    return res.status(200).send(data);
  } catch (err) {
    console.error("Proxy error:", err);
    return res.status(502).json({ error: "Failed to fetch upstream" });
  }
}
