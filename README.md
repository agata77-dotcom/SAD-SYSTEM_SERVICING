# Laboratory Asset and Service Management System - Section A

## Submission Requirements

### 1. GitHub Repository URL
https://github.com/agata77-dotcom/SAD-SYSTEM_SERVICING

### 2. Live GitHub Pages URL
**To enable**: Go to repo → Settings → Pages → Source: `main` branch → Save
URL will be: `https://agata77-dotcom.github.io/SAD-SYSTEM_SERVICING/`

### 3. Updated ERD and Use Case Diagram
See `sql/schema.sql` for complete ERD (tables, relationships, constraints).

**ERD Diagram:**
```
profiles (id PK, full_name, email, role, created_at)
    │ 1:N
    ├──> borrowing_requests (id PK, user_id FK, equipment_id FK, status, ...)
    │        │ 1:N
    │        └──> audit_logs (id PK, user_id FK, action, module, record_id, ...)
    │
    └──> equipment (id PK, equipment_id, name, category, status, ...)
            │ 1:N
            └──> maintenance (id PK, equipment_id FK, type, status, ...)
```

**Use Case Diagram:**
```
Actors:
  Administrator: manage_users, manage_equipment, approve_request, reject_request,
                  manage_maintenance, view_reports, view_audit_logs, manage_returns
  Laboratory Staff: view_equipment, create_borrowing, process_return,
                     submit_maintenance, update_records
  Requester/Viewer: view_equipment, submit_request, view_own_status, view_history

Use Cases:
  (Administrator) --| manage_users | (User Management)
  (Administrator) --| approve_request | (Borrowing Workflow)
  (Administrator) --| reject_request | (Borrowing Workflow)
  (Administrator) --| view_audit_logs | (Audit Trail)
  (Laboratory Staff) --| create_borrowing | (Borrowing Workflow)
  (Laboratory Staff) --| process_return | (Borrowing Workflow)
  (Requester/Viewer) --| submit_request | (Borrowing Workflow)
  All Actors --| view_equipment | (Equipment Catalog)
```

### 4. Role-Permission Matrix

| Role | Permitted Functions |
|------|-------------------|
| Administrator | Manage users and equipment; approve/reject requests; manage maintenance; view reports and audit logs |
| Laboratory Staff | View equipment; create borrowing transactions; process returns; submit maintenance requests; update permitted records |
| Requester / Viewer | View available equipment; submit borrowing requests; view own request status and history |

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

### 6. Business Rules

| ID | Rule | Enforcement |
|----|------|------------|
| BR-A4-01 | Only available equipment may be requested | `submit_borrowing_request()` function |
| BR-A4-02 | Staff cannot approve their own request | `approve_borrowing_request()` function |
| BR-A4-03 | Only Administrator may approve or reject | `approve_borrowing_request()`, `reject_borrowing_request()` |
| BR-A4-04 | Only Approved requests may be released | `release_equipment()` function |
| BR-A4-05 | Released equipment becomes Borrowed | `release_equipment()` function |
| BR-A4-06 | Returned equipment becomes Available unless damaged | `return_equipment()` function |
| BR-A4-07 | Rejected requests cannot be released | `release_equipment()` function |
| BR-A4-08 | Returned transactions cannot be processed twice | `return_equipment()` function |
| BR-A4-09 | Equipment under Maintenance cannot be borrowed | `submit_borrowing_request()` function |
| BR-A4-10 | Sensitive operations must be logged | All functions log to `audit_logs` |

### 7. Audit-Log Screenshot
Navigate to `audit-logs.html` when logged in as Administrator to view audit trail entries.

### 8. Functional Test Results
See `TEST-RESULTS.md` for all 10 test cases (TC-A4-01 through TC-A4-10).
