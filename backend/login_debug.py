import os
import sys
import json

sys.path.insert(0, os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
import django
django.setup()
from django.test import Client
from users.models import User
from django.contrib.auth import authenticate

user, created = User.objects.get_or_create(
    email='test-login@example.com',
    defaults={
        'first_name': 'Test',
        'last_name': 'Login',
        'role': 'teacher',
        'is_staff': False,
        'is_active': True,
    }
)
if created:
    user.set_password('Secret123!')
    user.save()

print('created', created, 'user id', user.id)
print('auth', authenticate(username='test-login@example.com', password='Secret123!'))

client = Client()
res = client.post(
    '/api/v1/auth/login/',
    json.dumps({'email': 'test-login@example.com', 'password': 'Secret123!'}),
    content_type='application/json',
)
print('status', res.status_code)
print('content', res.content.decode('utf-8'))
