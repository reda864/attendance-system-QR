"""Build public URLs for QR codes so student phones can reach the server."""

from django.conf import settings


def get_public_site_base(request) -> str:
    """
    Prefer SITE_BASE_URL when it is a real public host.
    Otherwise use the request host (e.g. 192.168.x.x) so LAN phones work.
    """
    configured = getattr(settings, "SITE_BASE_URL", "").strip().rstrip("/")
    if configured:
        lower = configured.lower()
        if "localhost" not in lower and "127.0.0.1" not in lower:
            return configured

    return request.build_absolute_uri("/").rstrip("/")


def build_attend_url(request, qr_token: str) -> str:
    base = get_public_site_base(request)
    return f"{base}/attend/?token={qr_token}"
