import logging
import os
import re
from unidecode import unidecode

TAVILY_API_KEY = os.getenv("TAVILY_API_KEY", "")
REQUEST_DELAY = float(os.getenv("REQUEST_DELAY", "1.5"))
MAX_PAGES_PER_CITY = int(os.getenv("MAX_PAGES_PER_CITY", "30"))
DAYS_AHEAD = int(os.getenv("DAYS_AHEAD", "90"))

OUTPUT_DIR = "datasets"
CACHE_DIR = ".cache"

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/122.0.0.0 Safari/537.36"
)

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)
logging.getLogger("aiohttp").setLevel(logging.WARNING)
log = logging.getLogger("eventRadar")


def city_to_ascii(name: str) -> str:
    return unidecode(name)


def city_to_slug(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", city_to_ascii(name).lower()).strip("-")


def build_search_queries(city: str, country_code: str = "") -> list[str]:
    import json
    from datetime import datetime
    from pathlib import Path

    month = datetime.now().strftime("%B")
    year = datetime.now().year
    ascii_city = city_to_ascii(city)

    english = [
        f"events in {ascii_city} {month} {year}",
        f"concerts {ascii_city} {year}",
        f"festival {ascii_city} {month} {year}",
        f"{ascii_city} event calendar {year}",
        f"things to do {ascii_city} upcoming",
    ]

    native: list[str] = []
    queries_path = Path(__file__).parent / "queries.json"
    if queries_path.exists():
        data = json.loads(queries_path.read_text(encoding="utf-8"))
        lang = data["country_language"].get(country_code.upper())
        terms = data["languages"].get(lang, {}).get("terms") if lang else None

        if terms:
            native = [
                f"{terms['events']} {city} {month} {year}",
                f"{terms['concerts']} {city} {year}",
                f"{terms['festival']} {city} {month} {year}",
                f"{terms['things_to_do']} {city}",
            ]
        elif city != ascii_city:
            log.debug("No country code for %r", city)

    queries: list[str] = []
    for pair in zip(native, english):
        queries.extend(pair)
    queries.extend(native[len(english) :])
    queries.extend(english[len(native) :])

    return queries
