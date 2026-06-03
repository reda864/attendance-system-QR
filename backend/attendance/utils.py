import hashlib
import math
from decimal import Decimal, ROUND_HALF_UP

GPS_DECIMAL_PLACES = 7


def round_coordinate(value, places: int = GPS_DECIMAL_PLACES):
    """Round GPS to fit DecimalField(max_digits=10, decimal_places=7)."""
    if value is None:
        return None
    d = Decimal(str(value))
    quantizer = Decimal(10) ** -places
    return d.quantize(quantizer, rounding=ROUND_HALF_UP)


def haversine_distance_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Return great-circle distance in meters between two GPS coordinates."""
    earth_radius = 6371000.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = (
        math.sin(dphi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return earth_radius * c


def compute_device_fingerprint(
    device_id: str = "",
    ip_address: str = "",
    user_agent: str = "",
    extra: str = "",
) -> str:
    """Stable hash used to detect duplicate scans from the same physical device."""
    raw = f"{device_id}|{ip_address}|{user_agent}|{extra}".strip().lower()
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()
