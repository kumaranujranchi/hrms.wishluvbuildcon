-- Create admin user with password: admin123
DELETE FROM hrms_users WHERE email = 'admin@hrms.com';

INSERT INTO hrms_users (
  id,
  email,
  password_hash,
  first_name,
  last_name,
  role,
  is_onboarding_complete,
  needs_password_reset,
  is_active
) VALUES (
  gen_random_uuid()::text,
  'admin@hrms.com',
  '$2b$10$/WmWf1GQPCuAMDbhCOCOFe66QfFiWAW09qi1GFZ72C/MivtSGSLHO',
  'Admin',
  'User',
  'admin',
  true,
  false,
  true
);

SELECT 'Admin user created successfully!' as status;
SELECT id, email, first_name, last_name, role FROM hrms_users WHERE email = 'admin@hrms.com';
