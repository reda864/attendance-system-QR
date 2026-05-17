"""
ASGI config for QR Attendance System.

Supports both HTTP (Django) and WebSocket (Django Channels) connections.
"""

import os

from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

# Initialize Django ASGI application early to ensure AppRegistry is populated
django_asgi_app = get_asgi_application()

from attendance.routing import websocket_urlpatterns  # noqa: E402
from channels.routing import ProtocolTypeRouter, URLRouter  # noqa: E402

application = ProtocolTypeRouter(
    {
        # Standard Django HTTP requests
        "http": django_asgi_app,
        # WebSocket connections — no origin validation in dev for simplicity
        "websocket": URLRouter(websocket_urlpatterns),
    }
)
