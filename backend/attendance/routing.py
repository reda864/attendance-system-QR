from django.urls import re_path

from .consumers import AdminLiveConsumer, AttendanceConsumer, TeacherLiveConsumer

websocket_urlpatterns = [
    re_path(r"^ws/attendance/(?P<session_id>\d+)/$", AttendanceConsumer.as_asgi()),
    re_path(r"^ws/attendance/live/admin/$", AdminLiveConsumer.as_asgi()),
    re_path(
        r"^ws/attendance/live/teacher/(?P<teacher_id>\d+)/$",
        TeacherLiveConsumer.as_asgi(),
    ),
]
