import json
import urllib.parse
from typing import Optional
from bs4 import BeautifulSoup
from models import RawEvent


class SchemaOrgExtractor:
    EVENT_TYPES = {
        "Event",
        "MusicEvent",
        "TheaterEvent",
        "FoodEvent",
        "SportsEvent",
        "ScreeningEvent",
        "SocialEvent",
        "ExhibitionEvent",
        "Festival",
        "ComedyEvent",
        "DanceEvent",
    }

    def extract(self, html: str, page_url: str) -> list[RawEvent]:
        soup = BeautifulSoup(html, "lxml")
        events = []
        for script in soup.find_all("script", type="application/ld+json"):
            try:
                data = json.loads(script.string or "")
            except json.JSONDecodeError:
                continue
            for obj in self._flatten(data):
                if self._is_event(obj):
                    ev = self._parse(obj, page_url)
                    if ev:
                        events.append(ev)
        return events

    def _flatten(self, data) -> list[dict]:
        if isinstance(data, list):
            out = []
            for item in data:
                out.extend(self._flatten(item))
            return out
        if isinstance(data, dict):
            return self._flatten(data["@graph"]) if "@graph" in data else [data]
        return []

    def _is_event(self, obj: dict) -> bool:
        t = obj.get("@type", "")
        return any(x in self.EVENT_TYPES for x in (t if isinstance(t, list) else [t]))

    def _parse(self, obj: dict, page_url: str) -> Optional[RawEvent]:
        title = self._str(obj.get("name"))
        start = self._str(obj.get("startDate"))
        if not title or not start:
            return None

        venue = address = None
        lat = lon = None

        loc = obj.get("location", {})
        if isinstance(loc, dict):
            venue = self._str(loc.get("name"))
            addr = loc.get("address", {})
            if isinstance(addr, str):
                address = addr
            elif isinstance(addr, dict):
                parts = [
                    addr.get("streetAddress"),
                    addr.get("addressLocality"),
                    addr.get("addressRegion"),
                    addr.get("addressCountry"),
                ]
                address = ", ".join(
                    str(p) for p in parts if p and not isinstance(p, (dict, list))
                )
            geo = loc.get("geo", {})
            if isinstance(geo, dict):
                try:
                    lat = float(geo.get("latitude", 0)) or None
                    lon = float(geo.get("longitude", 0)) or None
                except (TypeError, ValueError):
                    pass
        elif isinstance(loc, str):
            address = loc

        price = None
        offers = obj.get("offers", {})
        offer = offers[0] if isinstance(offers, list) and offers else offers
        if isinstance(offer, dict):
            p = offer.get("price") or offer.get("lowPrice")
            currency = offer.get("priceCurrency", "")
            if p is not None:
                price = f"{currency} {p}".strip() if currency else str(p)

        raw_type = obj.get("@type", "")
        schema_type = (
            raw_type[0] if isinstance(raw_type, list) and raw_type else raw_type
        ) or None

        return RawEvent(
            title=title,
            start=self._norm_date(start),
            end=self._norm_date(self._str(obj.get("endDate"))),
            venue=venue,
            address=address,
            description=self._str(obj.get("description")),
            url=self._str(obj.get("url")) or page_url,
            source=urllib.parse.urlparse(page_url).netloc,
            price=price,
            latitude=lat,
            longitude=lon,
            category=schema_type,
        )

    @staticmethod
    def _str(val) -> Optional[str]:
        if val is None:
            return None
        if isinstance(val, str):
            return val.strip() or None
        if isinstance(val, dict):
            return SchemaOrgExtractor._str(val.get("@value") or val.get("name"))
        return str(val).strip() or None

    @staticmethod
    def _norm_date(raw: Optional[str]) -> Optional[str]:
        if not raw:
            return None
        raw = raw.strip()
        from datetime import datetime

        for fmt in ("%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M", "%Y-%m-%d"):
            try:
                return datetime.strptime(raw[: len(fmt)], fmt).isoformat()
            except ValueError:
                pass
        return raw
