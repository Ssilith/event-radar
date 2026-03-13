import asyncio
import hashlib
import json
import re
import time
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional
import aiohttp
from config import CACHE_DIR, DAYS_AHEAD, OUTPUT_DIR, USER_AGENT, city_to_slug, log
from models import NormalizedEvent, RawEvent


class PageFetcher:
    def __init__(self, session: aiohttp.ClientSession):
        self.session = session
        self._cache: dict[str, dict] = {}
        self._path = Path(CACHE_DIR) / "pages.json"
        self._dirty = False
        self._load()

    def _load(self):
        if self._path.exists():
            try:
                data = json.loads(self._path.read_text(encoding="utf-8"))
                now = time.time()
                self._cache = {
                    k: v for k, v in data.items() if now - v.get("ts", 0) < 21600
                }
            except Exception:
                pass

    def flush(self):
        if self._dirty:
            self._path.write_text(
                json.dumps(self._cache, ensure_ascii=False), encoding="utf-8"
            )
            self._dirty = False

    async def fetch(self, url: str) -> Optional[str]:
        if url in self._cache:
            return self._cache[url]["html"]

        headers = {
            "User-Agent": USER_AGENT,
            "Accept-Language": "pl,cs,de,en;q=0.8",
            "Accept": "text/html,application/xhtml+xml",
        }
        for attempt in range(3):
            try:
                async with self.session.get(
                    url,
                    headers=headers,
                    timeout=aiohttp.ClientTimeout(total=15),
                    allow_redirects=True,
                ) as r:
                    if r.status == 200:
                        html = await self._decode(r)
                        self._cache[url] = {"html": html, "ts": time.time()}
                        self._dirty = True
                        return html
                    if r.status in (403, 404, 410):
                        return None
            except (aiohttp.ClientError, asyncio.TimeoutError):
                if attempt < 2:
                    await asyncio.sleep(2**attempt)
        return None

    @staticmethod
    async def _decode(r: aiohttp.ClientResponse) -> str:
        raw = await r.read()

        charset = None
        ct = r.headers.get("Content-Type", "")
        if "charset=" in ct:
            charset = ct.split("charset=")[-1].split(";")[0].strip()

        if not charset:
            snippet = raw[:4096].decode("ascii", errors="replace")
            m = re.search(
                r'<meta[^>]+charset[=\s"\']+([a-zA-Z0-9\-]+)', snippet, re.IGNORECASE
            )
            if m:
                charset = m.group(1)

        for enc in filter(
            None, [charset, "utf-8", "windows-1250", "iso-8859-2", "latin-1"]
        ):
            try:
                return raw.decode(enc)
            except (UnicodeDecodeError, LookupError):
                continue
        return raw.decode("utf-8", errors="replace")


class Geocoder:
    URL = "https://photon.komoot.io/api/"

    def __init__(self, session: aiohttp.ClientSession):
        self.session = session
        self._cache: dict[str, list] = {}
        self._path = Path(CACHE_DIR) / "geocache.json"
        self._load()

    def _load(self):
        if self._path.exists():
            try:
                self._cache = json.loads(self._path.read_text(encoding="utf-8"))
            except Exception:
                pass

    def _save(self):
        self._path.write_text(
            json.dumps(self._cache, indent=2, ensure_ascii=False), encoding="utf-8"
        )

    @staticmethod
    def _clean(address: str) -> str:
        address = re.sub(r"[\u0400-\u04FF]+", "", address)
        address = re.sub(r"[\t\r\n]+", " ", address)
        address = re.sub(r"\s{2,}", " ", address)
        address = re.sub(r",\s*,", ",", address)
        return address.strip(" ,")

    async def resolve(self, address: str) -> tuple[Optional[float], Optional[float]]:
        address = self._clean(address)
        if not address:
            return None, None

        key = address.lower()
        if key in self._cache:
            return tuple(self._cache[key])

        try:
            async with self.session.get(
                self.URL,
                params={"q": address, "limit": 1, "lang": "en"},
                headers={"User-Agent": USER_AGENT},
                timeout=aiohttp.ClientTimeout(total=8),
            ) as r:
                data = await r.json(content_type=None)
                features = data.get("features", [])
                if features:
                    coords = features[0]["geometry"]["coordinates"]
                    lon, lat = float(coords[0]), float(coords[1])
                    self._cache[key] = [lat, lon]
                    self._save()
                    return lat, lon
        except Exception as exc:
            log.debug("Geocoding failed for %r: %s", address, exc)

        return None, None


class EventNormalizer:
    def __init__(self, city: str, geocoder: Geocoder):
        self.city = city
        self.slug = city_to_slug(city)
        self.geocoder = geocoder
        self.cutoff = datetime.now() + timedelta(days=DAYS_AHEAD)
        self._geo_cache: dict[str, tuple] = {}

    async def _resolve(
        self, *candidates: Optional[str]
    ) -> tuple[Optional[float], Optional[float]]:
        for addr in candidates:
            if not addr:
                continue
            key = addr.lower().strip()
            if key in self._geo_cache:
                return self._geo_cache[key]
            result = await self.geocoder.resolve(addr)
            self._geo_cache[key] = result
            if result[0]:
                return result
        return None, None

    async def normalize(self, raw: RawEvent) -> Optional[NormalizedEvent]:
        try:
            start_dt = datetime.fromisoformat(raw.start.replace("Z", "+00:00"))
        except Exception:
            return None

        start_naive = start_dt.replace(tzinfo=None)
        if start_naive < datetime.now() or start_naive > self.cutoff:
            return None

        lat, lon = raw.latitude, raw.longitude
        if not lat:
            lat, lon = await self._resolve(
                raw.address,
                f"{raw.venue}, {self.city}" if raw.venue else None,
            )

        return NormalizedEvent(
            id=hashlib.sha256(
                f"{raw.title}|{raw.start}|{raw.venue or ''}".encode()
            ).hexdigest()[:16],
            title=re.sub(r"\s+", " ", raw.title.strip()),
            city=self.slug,
            start=start_dt.isoformat(),
            end=raw.end,
            venue=raw.venue,
            latitude=round(lat, 6) if lat else None,
            longitude=round(lon, 6) if lon else None,
            description=raw.description[:500] if raw.description else None,
            url=raw.url,
            source=raw.source,
            price=raw.price,
        )


class Deduplicator:
    def __init__(self):
        self._seen: dict[str, NormalizedEvent] = {}

    def add(self, event: NormalizedEvent):
        key = hashlib.sha256(
            f"{event.title.lower()}|{event.start[:10]}|{(event.venue or '').lower()}".encode()
        ).hexdigest()[:16]
        existing = self._seen.get(key)
        if not existing or self._score(event) > self._score(existing):
            self._seen[key] = event

    @property
    def events(self) -> list[NormalizedEvent]:
        return sorted(self._seen.values(), key=lambda e: e.start)

    @staticmethod
    def _score(e: NormalizedEvent) -> int:
        return sum(1 for f in [e.venue, e.latitude, e.description, e.price, e.url] if f)


class DatasetPublisher:
    def __init__(self):
        Path(OUTPUT_DIR).mkdir(parents=True, exist_ok=True)
        self._index: dict[str, dict] = {}
        idx = Path(OUTPUT_DIR) / "index.json"
        if idx.exists():
            try:
                self._index = {
                    c["slug"]: c
                    for c in json.loads(idx.read_text(encoding="utf-8")).get(
                        "cities", []
                    )
                }
            except Exception:
                pass

    def publish(self, city: str, events: list[NormalizedEvent]):
        slug = city_to_slug(city)
        payload = {
            "city": city,
            "slug": slug,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "count": len(events),
            "events": [e.to_dict() for e in events],
        }
        out = Path(OUTPUT_DIR) / f"{slug}.json"
        out.write_text(
            json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        log.info("Published %d events for %s -> %s", len(events), city, out)

        self._index[slug] = {
            "city": city,
            "slug": slug,
            "count": len(events),
            "updated_at": payload["generated_at"],
            "url": f"{slug}.json",
        }
        (Path(OUTPUT_DIR) / "index.json").write_text(
            json.dumps(
                {
                    "cities": list(self._index.values()),
                    "updated_at": datetime.now(timezone.utc).isoformat(),
                },
                indent=2,
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )
