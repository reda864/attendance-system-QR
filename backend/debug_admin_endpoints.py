import os
import sys
import json

sys.path.insert(0, os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
import django
from django.test import Client
from users.models import User, Classe

django.setup()

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
    },
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
    sys.exit(1)

data = json.loads(res.content.decode('utf-8'))
access = data['access']
headers = {'HTTP_AUTHORIZATION': 'Bearer ' + access}

for path in ['/api/v1/users/', '/api/v1/sessions/', '/api/v1/attendance/', '/api/v1/classes/']:
    print('\nREQUEST', path)
    r = client.get(path, **headers)
    print('status', r.status_code)
    print('content', r.content.decode('utf-8')[:1000])

classe = Classe.objects.order_by('id').first()
if classe:
    path = f'/api/v1/classes/{classe.id}/'
    print('\nREQUEST', path)
    r = client.get(path, **headers)
    print('status', r.status_code)
    print('content', r.content.decode('utf-8')[:1000])

    new = Classe.objects.create(name='TempClass', academic_year='2026', code='TEMP')
    print('created TempClass id', new.id)
    r2 = client.delete(f'/api/v1/classes/{new.id}/', **headers)
    print('delete status', r2.status_code)
    print('delete content', r2.content.decode('utf-8')[:1000])
else:
    print('No Classe records found')
