-- ========================================
-- LABORATORY ASSET AND SERVICE MANAGEMENT
-- DATABASE SCHEMA
-- Role-Based Asset Transaction and Approval Management
-- ========================================

-- ========================================
-- EXTENSIONS
-- ========================================

create extension if not exists "uuid" default;

-- ========================================
-- TABLE: profiles
-- ========================================

create table if not exists profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text not null,
    email text unique,
    role text not null check (role in ('Administrator', 'Laboratory Staff', 'Requester', 'Viewer')),
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- ========================================
-- TABLE: equipment
-- ========================================

create table if not exists equipment (
    id uuid primary key default gen_random_uuid(),
    equipment_id text unique not null,
    name text not null,
    category text,
    status text not null default 'Available' check (status in ('Available', 'Borrowed', 'Under Maintenance', 'Unavailable')),
    description text,
    location text,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- ========================================
-- TABLE: borrowing_requests
-- ========================================

create table if not exists borrowing_requests (
    id uuid primary key default gen_random_uuid(),
    request_id text unique not null,
    user_id uuid not null references profiles(id) on delete cascade,
    equipment_id uuid not null references equipment(id) on delete restrict,
    request_date timestamp with time zone default now(),
    approval_date timestamp with time zone,
    released_date timestamp with time zone,
    returned_date timestamp with time zone,
    status text not null default 'Pending' check (status in ('Pending', 'Approved', 'Rejected', 'Released', 'Returned', 'Overdue', 'Closed')),
    reason text,
    damage_noted boolean default false,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- ========================================
-- TABLE: audit_logs
-- ========================================

create table if not exists audit_logs (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references profiles(id) on delete set null,
    action text not null,
    module text not null,
    record_id text,
    description text,
    created_at timestamp with time zone default now()
);

-- ========================================
-- TABLE: maintenance
-- ========================================

create table if not exists maintenance (
    id uuid primary key default gen_random_uuid(),
    equipment_id uuid not null references equipment(id) on delete cascade,
    maintenance_type text not null,
    maintenance_date timestamp with time zone default now(),
    status text not null default 'Pending' check (status in ('Pending', 'In Progress', 'Completed', 'Cancelled')),
    description text,
    created_at timestamp with time zone default now()
);

-- ========================================
-- INDEXES
-- ========================================

create index if not exists idx_borrowing_user on borrowing_requests(user_id);
create index if not exists idx_borrowing_status on borrowing_requests(status);
create index if not exists idx_borrowing_equipment on borrowing_requests(equipment_id);
create index if not exists idx_audit_user on audit_logs(user_id);
create index if not exists idx_audit_module on audit_logs(module);
create index if not exists idx_equipment_status on equipment(status);
create index if not exists idx_maintenance_equipment on maintenance(equipment_id);

-- ========================================
-- ROW LEVEL SECURITY
-- ========================================

alter table profiles enable row level security;
alter table equipment enable row level security;
alter table borrowing_requests enable row level security;
alter table audit_logs enable row level security;
alter table maintenance enable row level security;

-- ========================================
-- RLS POLICIES: profiles
-- ========================================

create policy "Users can view own profile"
on profiles for select
to authenticated
using (auth.uid() = id);

create policy "Users can update own profile"
on profiles for update
to authenticated
using (auth.uid() = id);

create policy "Admin can view all profiles"
on profiles for select
to authenticated
using (
    exists (
        select 1 from profiles p
        where p.id = auth.uid() and p.role = 'Administrator'
    )
);

-- ========================================
-- RLS POLICIES: equipment
-- ========================================

create policy "Anyone authenticated can view equipment"
on equipment for select
to authenticated
using (true);

create policy "Staff and Admin can insert equipment"
on equipment for insert
to authenticated
with check (
    exists (
        select 1 from profiles p
        where p.id = auth.uid()
        and p.role in ('Administrator', 'Laboratory Staff')
    )
);

create policy "Staff and Admin can update equipment"
on equipment for update
to authenticated
using (
    exists (
        select 1 from profiles p
        where p.id = auth.uid()
        and p.role in ('Administrator', 'Laboratory Staff')
    )
);

-- ========================================
-- RLS POLICIES: borrowing_requests
-- ========================================

create policy "Users can view own borrowing requests"
on borrowing_requests for select
to authenticated
using (auth.uid() = user_id);

create policy "Admin can view all borrowing requests"
on borrowing_requests for select
to authenticated
using (
    exists (
        select 1 from profiles p
        where p.id = auth.uid() and p.role = 'Administrator'
    )
);

create policy "Staff can view borrowing requests"
on borrowing_requests for select
to authenticated
using (
    exists (
        select 1 from profiles p
        where p.id = auth.uid() and p.role = 'Laboratory Staff'
    )
);

create policy "Users can insert own borrowing request"
on borrowing_requests for insert
to authenticated
with check (auth.uid() = user_id);

create policy "Admin can update borrowing requests"
on borrowing_requests for update
to authenticated
using (
    exists (
        select 1 from profiles p
        where p.id = auth.uid() and p.role = 'Administrator'
    )
);

-- ========================================
-- RLS POLICIES: audit_logs
-- ========================================

create policy "Admin can view all audit logs"
on audit_logs for select
to authenticated
using (
    exists (
        select 1 from profiles p
        where p.id = auth.uid() and p.role = 'Administrator'
    )
);

create policy "Service role can insert audit logs"
on audit_logs for insert
to service_role
with check (true);

-- ========================================
-- RLS POLICIES: maintenance
-- ========================================

create policy "Anyone authenticated can view maintenance"
on maintenance for select
to authenticated
using (true);

create policy "Staff and Admin can insert maintenance"
on maintenance for insert
to authenticated
with check (
    exists (
        select 1 from profiles p
        where p.id = auth.uid()
        and p.role in ('Administrator', 'Laboratory Staff')
    )
);

create policy "Staff and Admin can update maintenance"
on maintenance for update
to authenticated
using (
    exists (
        select 1 from profiles p
        where p.id = auth.uid()
        and p.role in ('Administrator', 'Laboratory Staff')
    )
);

-- ========================================
-- FUNCTIONS: Business Rule Enforcement
-- ========================================

-- Function: Submit borrowing request (BR-A4-01, BR-A4-09)
create or replace function submit_borrowing_request(
    p_equipment_id uuid,
    p_reason text
)
returns json
language plpgsql
security definer
as $$
declare
    v_equipment record;
    v_request_id text;
    v_user_id uuid;
begin
    -- Get user ID from auth
    v_user_id := auth.uid();

    -- BR-A4-01: Only available equipment may be requested
    select * into v_equipment
    from equipment
    where id = p_equipment_id;

    if not found then
        return json_build_object('success', false, 'error', 'Equipment not found.');
    end if;

    if v_equipment.status != 'Available' then
        return json_build_object('success', false, 'error', 'BR-A4-01: Only available equipment may be requested. Current status: ' || v_equipment.status);
    end if;

    -- BR-A4-09: Equipment under Maintenance cannot be borrowed
    if v_equipment.status = 'Under Maintenance' then
        return json_build_object('success', false, 'error', 'BR-A4-09: Equipment under Maintenance cannot be borrowed.');
    end if;

    -- Generate request ID
    select 'BR-' || to_char(now(), 'YYYYMMDD') || '-' || lpad((select count(*) + 1 from borrowing_requests), 4, '0')
    into v_request_id;

    -- Insert borrowing request
    insert into borrowing_requests (request_id, user_id, equipment_id, status, reason)
    values (v_request_id, v_user_id, p_equipment_id, 'Pending', p_reason);

    -- Audit log
    insert into audit_logs (user_id, action, module, record_id, description)
    values (v_user_id, 'SUBMITTED', 'Borrowing', v_request_id, 'Submitted borrowing request for ' || v_equipment.name);

    return json_build_object('success', true, 'request_id', v_request_id, 'message', 'Borrowing request submitted as Pending.');
end;
$$;

-- Function: Approve borrowing request (BR-A4-02, BR-A4-03)
create or replace function approve_borrowing_request(p_request_id text)
returns json
language plpgsql
security definer
as $$
declare
    v_request record;
    v_approver_id uuid;
    v_approver_role text;
begin
    v_approver_id := auth.uid();

    -- Get approver role
    select role into v_approver_role
    from profiles
    where id = v_approver_id;

    -- BR-A4-03: Only Administrator may approve or reject requests
    if v_approver_role != 'Administrator' then
        return json_build_object('success', false, 'error', 'BR-A4-03: Only Administrator may approve or reject requests.');
    end if;

    -- Get request
    select * into v_request
    from borrowing_requests
    where request_id = p_request_id;

    if not found then
        return json_build_object('success', false, 'error', 'Request not found.');
    end if;

    -- BR-A4-02: Staff cannot approve their own request (check if any staff tries)
    if v_approver_role = 'Laboratory Staff' and v_request.user_id = v_approver_id then
        return json_build_object('success', false, 'error', 'BR-A4-02: Staff cannot approve their own request.');
    end if;

    -- Check status
    if v_request.status != 'Pending' then
        return json_build_object('success', false, 'error', 'Request is not in Pending status. Current: ' || v_request.status);
    end if;

    -- Approve
    update borrowing_requests
    set status = 'Approved',
        approval_date = now(),
        updated_at = now()
    where request_id = p_request_id;

    -- Audit log
    insert into audit_logs (user_id, action, module, record_id, description)
    values (v_approver_id, 'APPROVED', 'Borrowing', p_request_id,
            'Approved borrowing request for ' || (select name from equipment where id = v_request.equipment_id));

    return json_build_object('success', true, 'message', 'Request approved.');
end;
$$;

-- Function: Reject borrowing request
create or replace function reject_borrowing_request(p_request_id text, p_reason text default null)
returns json
language plpgsql
security definer
as $$
declare
    v_request record;
    v_rejector_id uuid;
    v_rejector_role text;
begin
    v_rejector_id := auth.uid();

    select role into v_rejector_role
    from profiles
    where id = v_rejector_id;

    -- BR-A4-03: Only Administrator may approve or reject requests
    if v_rejector_role != 'Administrator' then
        return json_build_object('success', false, 'error', 'BR-A4-03: Only Administrator may approve or reject requests.');
    end if;

    select * into v_request
    from borrowing_requests
    where request_id = p_request_id;

    if not found then
        return json_build_object('success', false, 'error', 'Request not found.');
    end if;

    if v_request.status != 'Pending' then
        return json_build_object('success', false, 'error', 'Request is not in Pending status.');
    end if;

    update borrowing_requests
    set status = 'Rejected',
        approval_date = now(),
        reason = p_reason,
        updated_at = now()
    where request_id = p_request_id;

    insert into audit_logs (user_id, action, module, record_id, description)
    values (v_rejector_id, 'REJECTED', 'Borrowing', p_request_id,
            'Rejected borrowing request for ' || (select name from equipment where id = v_request.equipment_id));

    return json_build_object('success', true, 'message', 'Request rejected.');
end;
$$;

-- Function: Release approved equipment (BR-A4-04, BR-A4-05)
create or replace function release_equipment(p_request_id text)
returns json
language plpgsql
security definer
as $$
declare
    v_request record;
    v_operator_id uuid;
    v_operator_role text;
begin
    v_operator_id := auth.uid();

    select role into v_operator_role
    from profiles
    where id = v_operator_id;

    -- Must be admin or staff to release
    if v_operator_role not in ('Administrator', 'Laboratory Staff') then
        return json_build_object('success', false, 'error', 'Unauthorized. Only Administrator or Laboratory Staff may release equipment.');
    end if;

    select * into v_request
    from borrowing_requests
    where request_id = p_request_id;

    if not found then
        return json_build_object('success', false, 'error', 'Request not found.');
    end if;

    -- BR-A4-04: Only Approved requests may be released
    if v_request.status != 'Approved' then
        return json_build_object('success', false, 'error', 'BR-A4-04: Only Approved requests may be released. Current: ' || v_request.status);
    end if;

    -- BR-A4-05: Released equipment becomes Borrowed
    update equipment
    set status = 'Borrowed', updated_at = now()
    where id = v_request.equipment_id;

    update borrowing_requests
    set status = 'Released',
        released_date = now(),
        updated_at = now()
    where request_id = p_request_id;

    insert into audit_logs (user_id, action, module, record_id, description)
    values (v_operator_id, 'RELEASED', 'Borrowing', p_request_id,
            'Released equipment for borrowing request ' || p_request_id);

    return json_build_object('success', true, 'message', 'Equipment released. Status changed to Borrowed.');
end;
$$;

-- Function: Return equipment (BR-A4-06, BR-A4-08)
create or replace function return_equipment(p_request_id text, p_damaged boolean default false)
returns json
language plpgsql
as $$
declare
    v_request record;
    v_operator_id uuid;
    v_operator_role text;
begin
    v_operator_id := auth.uid();

    select role into v_operator_role
    from profiles
    where id = v_operator_id;

    if v_operator_role not in ('Administrator', 'Laboratory Staff') then
        return json_build_object('success', false, 'error', 'Unauthorized.');
    end if;

    select * into v_request
    from borrowing_requests
    where request_id = p_request_id;

    if not found then
        return json_build_object('success', false, 'error', 'Request not found.');
    end if;

    -- BR-A4-08: Returned transactions cannot be processed twice
    if v_request.status = 'Returned' then
        return json_build_object('success', false, 'error', 'BR-A4-08: This equipment has already been returned.');
    end if;

    if v_request.status != 'Released' then
        return json_build_object('success', false, 'error', 'Equipment is not currently released/borrowed.');
    end if;

    -- BR-A4-06: Returned equipment becomes Available unless damaged
    if p_damaged then
        update equipment
        set status = 'Unavailable', updated_at = now()
        where id = v_request.equipment_id;
    else
        update equipment
        set status = 'Available', updated_at = now()
        where id = v_request.equipment_id;
    end if;

    update borrowing_requests
    set status = 'Returned',
        returned_date = now(),
        damage_noted = p_damaged,
        updated_at = now()
    where request_id = p_request_id;

    insert into audit_logs (user_id, action, module, record_id, description)
    values (v_operator_id, 'RETURNED', 'Borrowing', p_request_id,
            'Returned equipment for borrowing request ' || p_request_id ||
            case when p_damaged then ' (Damage noted)' else '' end);

    return json_build_object('success', true, 'message', 'Equipment returned.');
end;
$$;

-- Function: Close borrowing request
create or replace function close_borrowing_request(p_request_id text)
returns json
language plpgsql
security definer
as $$
declare
    v_request record;
    v_operator_id uuid;
begin
    v_operator_id := auth.uid();

    select * into v_request
    from borrowing_requests
    where request_id = p_request_id;

    if not found then
        return json_build_object('success', false, 'error', 'Request not found.');
    end if;

    if v_request.status != 'Returned' then
        return json_build_object('success', false, 'error', 'Only Returned requests can be closed.');
    end if;

    update borrowing_requests
    set status = 'Closed', updated_at = now()
    where request_id = p_request_id;

    insert into audit_logs (user_id, action, module, record_id, description)
    values (v_operator_id, 'CLOSED', 'Borrowing', p_request_id,
            'Closed borrowing request ' || p_request_id);

    return json_build_object('success', true, 'message', 'Request closed.');
end;
$$;

-- ========================================
-- FUNCTION: Auto-create profile on signup
-- ========================================

create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
    insert into profiles (id, full_name, email, role)
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'full_name', new.email),
        new.email,
        coalesce(new.raw_user_meta_data->>'role', 'Requester')
    );
    return new;
end;
$$;

create or replace trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function handle_new_user();
