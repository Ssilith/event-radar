from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from typing import Optional


@dataclass
class RawEvent:
    title: str
    start: str
    end: Optional[str] = None
    venue: Optional[str] = None
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    description: Optional[str] = None
    url: Optional[str] = None
    source: Optional[str] = None
    price: Optional[str] = None


@dataclass
class NormalizedEvent:
    id: str
    title: str
    city: str
    start: str
    end: Optional[str]
    venue: Optional[str]
    latitude: Optional[float]
    longitude: Optional[float]
    description: Optional[str]
    url: Optional[str]
    source: Optional[str]
    price: Optional[str]
    updated_at: str = field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )

    def to_dict(self) -> dict:
        return {k: v for k, v in asdict(self).items() if v is not None}
