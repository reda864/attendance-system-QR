import json
import logging

from channels.generic.websocket import AsyncWebsocketConsumer

logger = logging.getLogger(__name__)


class AttendanceConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.session_id = self.scope["url_route"]["kwargs"]["session_id"]
        self.group_name = f"attendance_{self.session_id}"

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()
        logger.info(f"WebSocket connected: session={self.session_id}")

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)
        logger.info(
            f"WebSocket disconnected: session={self.session_id} code={close_code}"
        )

    async def attendance_update(self, event):
        """Called when a new attendance record is broadcast to this group."""
        await self.send(text_data=json.dumps(event["data"]))
