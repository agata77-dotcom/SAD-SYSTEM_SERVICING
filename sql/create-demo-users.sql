-- Run this in Supabase SQL Editor to create demo accounts
-- Prerequisite: Schema must be set up first (see schema.sql)

-- Create admin user
-- Go to Authentication → Users → Add User in Supabase Dashboard first, then update role:
-- Email: admin@ict.local
-- Password: Admin123!

-- Create staff user
-- Email: staff@ict.local
-- Password: Staff123!

-- Create requester user
-- Email: requester@ict.local
-- Password: Requester123!

-- After creating users via Supabase Auth UI, update their roles:
UPDATE profiles SET role = 'Administrator' WHERE email = 'admin@ict.local';
UPDATE profiles SET role = 'Laboratory Staff' WHERE email = 'staff@ict.local';
UPDATE profiles SET role = 'Requester' WHERE email = 'requester@ict.local';

-- If you prefer to create users via SQL (requires auth.admin role):
-- SELECT auth.create_user('admin@ict.local', 'Admin123!', 'Administrator');
