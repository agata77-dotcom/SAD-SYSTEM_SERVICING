# Supabase Database Setup Guide

## Prerequisites
- Access to Supabase dashboard at https://app.supabase.com
- Your project: `SAD-SYSTEM-SERVICING`

## Step 1: Run SQL Schema

1. Go to Supabase Dashboard → SQL Editor
2. Create a new query tab
3. Paste the contents of `sql/schema.sql`
4. Click **Run**

This creates:
- `profiles` table (user profiles with roles)
- `equipment` table (equipment inventory)
- `borrowing_requests` table (borrowing workflow)
- `audit_logs` table (audit trail)
- `maintenance` table (maintenance records)
- RLS policies on all tables
- Business logic functions (stored procedures)
- Trigger for auto-creating profiles on signup

## Step 2: Insert Seed Data

1. Create another query tab
2. Paste `sql/seed.sql`
3. Click **Run**

This inserts 9 sample equipment items.

## Step 3: Create Authenticated Users

### Option A: Via Supabase Dashboard (Recommended)

1. Go to Supabase Dashboard → **Authentication** → **Users** → **Add user**
2. Create these accounts:

| Role | Email | Password |
|------|-------|----------|
| Administrator | admin@ict.local | Admin123! |
| Laboratory Staff | staff@ict.local | Staff123! |
| Requester | requester@ict.local | Requester123! |

### Option B: Via SQL (in Supabase SQL Editor)

```sql
SELECT auth.create_user('admin@ict.local', 'Admin123!', '{\"full_name\":\"Administrator\",\"role\":\"Administrator\"}');
SELECT auth.create_user('staff@ict.local', 'Staff123!', '{\"full_name\":\"Laboratory Staff\",\"role\":\"Laboratory Staff\"}');
SELECT auth.create_user('requester@ict.local', 'Requester123!', '{\"full_name\":\"Requester\",\"role\":\"Requester\"}');
```

> ⚠️ If `auth.create_user` is not available, use the Dashboard method.

### Step 3b: Set User Roles

After creating users, go to Table Editor → `profiles` and update each user's role:

```sql
UPDATE profiles SET role = 'Administrator' WHERE email = 'admin@ict.local';
UPDATE profiles SET role = 'Laboratory Staff' WHERE email = 'staff@ict.local';
UPDATE profiles SET role = 'Requester' WHERE email = 'requester@ict.local';
```

## Step 5: Verify Setup

1. Sign in as Administrator at the GitHub Pages URL
2. Navigate to Equipment page to verify data loads
3. Submit a borrowing request as Staff
4. Approve the request as Administrator
5. Release and return equipment
6. Check audit-logs.html for audit trail entries

## Database Connection

The app connects using the publishable key in `js/supabase.js`:
- URL: `https://qotbafdtzhfodwplgivp.supabase.co`
- Key: `sb_publishable_GPOAhQG-JNgLxm2yv0Tfqg_3igl5D6X`

⚠️ For production, use a `anon` key with RLS instead of publishable key.
