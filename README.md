# Laboratory Asset and Service Management System - Section A

## Submission Documents

### 1. GitHub Repository URL
See repository URL in deployment section.

### 2. Live GitHub Pages URL
See GitHub Pages deployment URL.

### 3. Role-Permission Matrix

| Role | Functions |
|------|-----------|
| Administrator | Manage users and equipment; approve/reject requests; manage maintenance; view reports and audit logs |
| Laboratory Staff | View equipment; create borrowing transactions; process returns; submit maintenance requests; update permitted records |
| Requester / Viewer | View available equipment; submit borrowing requests; view own request status and history |

### 4. Business Rules

| ID | Rule | Implementation |
|----|------|---------------|
| BR-A4-01 | Only available equipment may be requested | `submit_borrowing_request()` checks equipment.status = 'Available' |
| BR-A4-02 | Staff cannot approve their own request | `approve_borrowing_request()` checks if approver is staff and self |
| BR-A4-03 | Only Administrator may approve or reject | `approve_borrowing_request()` and `reject_borrowing_request()` require Administrator role |
| BR-A4-04 | Only Approved requests may be released | `release_equipment()` checks status = 'Approved' |
| BR-A4-05 | Released equipment becomes Borrowed | `release_equipment()` updates equipment.status = 'Borrowed' |
| BR-A4-06 | Returned equipment becomes Available unless damaged | `return_equipment()` sets status accordingly |
| BR-A4-07 | Rejected requests cannot be released | `release_equipment()` rejects non-Approved requests |
| BR-A4-08 | Returned transactions cannot be processed twice | `return_equipment()` blocks if status = 'Returned' |
| BR-A4-09 | Equipment under Maintenance cannot be borrowed | `submit_borrowing_request()` blocks if equipment.status = 'Under Maintenance' |
| BR-A4-10 | Sensitive operations must be logged | All functions insert into audit_logs |

### 5. Workflow Diagram

```
Borrowing Request Submitted
        ↓
      Pending
        ↓
  Administrator Reviews Request
        ↓
   Approved / Rejected
        ↓
  If Approved → Released → Returned → Closed
```

### 6. Audit Trail

The `audit_logs` table records: id, user_id, action, module, record_id, description, created_at.
All critical operations (submit, approve, reject, release, return, close) are logged via database functions.

### 7. Database Schema

See `sql/schema.sql` for complete DDL including tables, RLS policies, and business logic functions.
See `sql/seed.sql` for sample data.

### 8. Pages

| Page | Access | Purpose |
|------|--------|---------|
| index.html | All | Dashboard with role-specific navigation and stats |
| login.html | All | Authentication |
| equipment.html | Admin, Staff, Requester | Equipment inventory management |
| borrowing.html | Admin, Staff, Requester | Borrowing request submission and approval workflow |
| requests.html | Admin | Request management and approval queue |
| returns.html | Admin, Staff | Equipment return processing |
| maintenance.html | Admin, Staff | Maintenance records and requests |
| reports.html | Admin | System statistics and reports |
| audit-logs.html | Admin | Audit trail viewing |
| users.html | Admin | User management |
| my-requests.html | Requester, Viewer | Borrowing request status tracking |
| request-history.html | Requester, Viewer | Service and borrowing history |
