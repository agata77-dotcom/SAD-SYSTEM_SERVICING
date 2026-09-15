-- ========================================
-- SAMPLE AUDIT LOGS (for testing)
-- ========================================

insert into audit_logs (user_id, action, module, record_id, description)
select
    (select id from profiles limit 1),
    'APPROVED',
    'Borrowing',
    'BR-20260101-0001',
    'Approved borrowing request for LAP-001'
where exists (select 1 from profiles limit 1);
