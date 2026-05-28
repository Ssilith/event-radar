import asyncio
import aiohttp
from config import (
    TAVILY_API_KEY,
    MAX_PAGES_PER_CITY,
    REQUEST_DELAY,
    build_search_queries,
    log,
)


class SearchDiscovery:
    TAVILY_URL = "https://api.tavily.com/search"

    def __init__(self, session: aiohttp.ClientSession):
        self.session = session
        self.seen_urls: set[str] = set()

    async def discover_urls(self, city: str, country_code: str = "") -> list[str]:
        if not TAVILY_API_KEY:
            log.error("TAVILY_API_KEY not set. " "Get a key at https://tavily.com")
            return []

        urls: list[str] = []
        for query in build_search_queries(city, country_code):
            if len(urls) >= MAX_PAGES_PER_CITY:
                break
            try:
                batch = await self._search(query)
                new = [u for u in batch if u not in self.seen_urls]
                self.seen_urls.update(new)
                urls.extend(new)
                log.info("  %r -> %d new URLs (total %d)", query, len(new), len(urls))
                await asyncio.sleep(REQUEST_DELAY)
            except Exception as exc:
                log.warning("Search failed for %r: %s", query, exc)

        return urls[:MAX_PAGES_PER_CITY]

    async def _search(self, query: str) -> list[str]:
        payload = {
            "api_key": TAVILY_API_KEY,
            "query": query,
            "search_depth": "basic",
            "max_results": 10,
            "include_answer": False,
        }
        async with self.session.post(
            self.TAVILY_URL,
            json=payload,
            timeout=aiohttp.ClientTimeout(total=15),
        ) as r:
            r.raise_for_status()
            data = await r.json()
        return [item["url"] for item in data.get("results", [])]
