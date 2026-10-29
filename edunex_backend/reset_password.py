import getpass
import glob
import os

import firebase_admin
from firebase_admin import auth, credentials

key = glob.glob(os.path.join('secrets', '*.json'))[0]
firebase_admin.initialize_app(credentials.Certificate(key))

email = input('Account email: ').strip()
password = getpass.getpass('New password (6+ characters): ')

user = auth.get_user_by_email(email)
auth.update_user(user.uid, password=password, email_verified=True)
print('Done. You can now log in as', user.email)