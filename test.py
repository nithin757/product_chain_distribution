from werkzeug.security import generate_password_hash
print(generate_password_hash('password123'))   # <-- Copy this hash output
UPDATE users SET password = 'pbkdf2:sha256:600000$uMuOpfBLGl1pyvJh$8c22f7aabf74681525d25961c1ce2c7710516eaca1381d63f04bc144ddbaa38b' WHERE username='nike_mfg' AND user_type='manufacturer';
UPDATE users SET password = 'pbkdf2:sha256:600000$uMuOpfBLGl1pyvJh$8c22f7aabf74681525d25961c1ce2c7710516eaca1381d63f04bc144ddbaa38b' WHERE username='metro_dist' AND user_type='distributor';
UPDATE users SET password = 'pbkdf2:sha256:600000$uMuOpfBLGl1pyvJh$8c22f7aabf74681525d25961c1ce2c7710516eaca1381d63f04bc144ddbaa38b' WHERE username='john_doe' AND user_type='customer';
