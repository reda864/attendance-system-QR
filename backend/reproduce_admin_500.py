import os
import sys
import json

sys.path.insert(0, os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
import django
django.setup()
from django.test import Client
from users.models import User
from django.core.management import call_command
from django.db import transaction

admin_email = 'test-admin@example.com'
admin_password = 'Admin123!'
user, created = User.objects.get_or_create(
    email=admin_email,
    defaults={
        'first_name': 'Admin',
        'last_name': 'User',
        'role': 'admin',
        'is_staff': True,
        'is_superuser': True,
        'is_active': True,
    }
)
if created:
    user.set_password(admin_password)
    user.save()
    print('Created admin user', admin_email)
else:
    print('Reusing admin user', admin_email, 'id', user.id)

client = Client()
res = client.post('/api/v1/auth/login/', json.dumps({'email': admin_email, 'password': admin_password}), content_type='application/json')
print('login status', res.status_code)
print('login content', res.content.decode('utf-8'))
if res.status_code != 200:
    raise SystemExit(1)

data = json.loads(res.content.decode('utf-8'))
access = data['access']
headers = {'HTTP_AUTHORIZATION': 'Bearer ' + access}

for path in ['/api/v1/users/', '/api/v1/sessions/', '/api/v1/attendance/', '/api/v1/classes/']:
    r = client.get(path, **headers)
    print('\nGET', path, 'status', r.status_code)
    print(r.content.decode('utf-8'))

# test specific class detail if any class exists
from django.db.models import Count
from users.models import Classe
classe = Classe.objects.order_by('id').first()
if classe:
    path = '/api/v1/classes/%s/' % classe.id
    r = client.get(path, **headers)
    print('\nGET', path, 'status', r.status_code)
    print(r.content.decode('utf-8'))
    # delete attempt - use a new class and delete
    new = Classe.objects.create(name='TempClass', academic_year='2026', code='TEMP')
    r2 = client.delete('/api/v1/classes/%s/' % new.id, **headers)
    print('\nDELETE /api/v1/classes/%s/ status' % new.id, r2.status_code)
    print(r2.content.decode('utf-8'))
else:
    print('No Classe records found')
