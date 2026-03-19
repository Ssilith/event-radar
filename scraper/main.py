#!/usr/bin/env python3
import argparse
import asyncio
import os
from pathlib import Path
import aiohttp
from config import CACHE_DIR, DAYS_AHEAD, REQUEST_DELAY, log
from extractor import SchemaOrgExtractor
from pipeline import (
    DatasetPublisher,
    Deduplicator,
    EventNormalizer,
    Geocoder,
    PageFetcher,
)
from search import SearchDiscovery


async def run_city(
    city: str,
    country_code: str,
    session: aiohttp.ClientSession,
    publisher: DatasetPublisher,
):
    log.info("=" * 55)
    log.info("City: %s  Country: %s", city, country_code or "unknown")
    log.info("=" * 55)

    discovery = SearchDiscovery(session)
    fetcher = PageFetcher(session)
    extractor = SchemaOrgExtractor()
    geocoder = Geocoder(session)
    normalizer = EventNormalizer(city, geocoder)
    deduplicator = Deduplicator()

    log.info("[1/6] Resolving city coordinates...")
    resolved = await geocoder.set_city(city)
    if not resolved:
        log.warning("Could not geocode city %r — venue coords may be inaccurate", city)

    log.info("[2/6] Discovering URLs...")
    urls = await discovery.discover_urls(city, country_code)
    log.info("Found %d URLs", len(urls))

    log.info("[3/6] Scraping pages...")
    raw_events = []
    for i, url in enumerate(urls, 1):
        log.info("  [%d/%d] %s", i, len(urls), url[:80])
        html = await fetcher.fetch(url)
        if html:
            found = extractor.extract(html, url)
            if found:
                log.info("    -> %d events", len(found))
            raw_events.extend(found)
        await asyncio.sleep(REQUEST_DELAY)
    fetcher.flush()
    log.info("Raw events: %d", len(raw_events))

    log.info("[4/6] Normalizing...")
    normalized = [ev for raw in raw_events if (ev := await normalizer.normalize(raw))]
    log.info("Normalized: %d", len(normalized))

    log.info("[5/6] Deduplicating...")
    for ev in normalized:
        deduplicator.add(ev)
    final = deduplicator.events
    log.info("Final: %d events", len(final))

    log.info("[6/6] Publishing...")
    publisher.publish(city, final, country_code=country_code)


def parse_city_arg(raw: str) -> tuple[str, str]:
    if ":" in raw:
        city, cc = raw.rsplit(":", 1)
        return city.strip(), cc.strip().upper()
    return raw.strip(), ""


async def main():
    global DAYS_AHEAD

    parser = argparse.ArgumentParser()
    parser.add_argument("--city", help="Single city")
    parser.add_argument("--cities", help="File with one city per line")
    parser.add_argument("--days", type=int, default=DAYS_AHEAD)
    args = parser.parse_args()

    import config
    config.DAYS_AHEAD = args.days

    if args.city:
        cities = [args.city]
    elif args.cities:
        cities = [
            c.strip()
            for c in Path(args.cities).read_text(encoding="utf-8").splitlines()
            if c.strip()
        ]
    else:
        cities = [
            c.strip() for c in os.getenv("CITIES", "").split(",") if c.strip()
        ] or ["Wrocław:PL"]

    Path(CACHE_DIR).mkdir(parents=True, exist_ok=True)
    publisher = DatasetPublisher()

    async with aiohttp.ClientSession(
        connector=aiohttp.TCPConnector(limit=5, limit_per_host=2)
    ) as session:
        for raw in cities:
            city, country_code = parse_city_arg(raw)
            try:
                await run_city(city, country_code, session, publisher)
            except Exception as exc:
                log.error("Failed for %s: %s", city, exc, exc_info=True)

    log.info("Done. Datasets -> %s/", config.OUTPUT_DIR)


if __name__ == "__main__":
    asyncio.run(main())