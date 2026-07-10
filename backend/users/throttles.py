from rest_framework.throttling import ScopedRateThrottle


class LoginRateThrottle(ScopedRateThrottle):
    """Dedicated per-IP quota for login, isolated from other anonymous traffic
    (e.g. students scanning QR codes from the same school Wi-Fi/NAT IP)."""

    scope = "login"


class TokenRefreshRateThrottle(ScopedRateThrottle):
    """Dedicated per-IP quota for token refresh, isolated from other
    anonymous traffic sharing the same public IP."""

    scope = "token_refresh"
