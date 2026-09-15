# Laboratory Asset Transaction and Approval Management - Test Results

## Functional Testing Results (TC-A4-01 through TC-A4-10)

### TC-A4-01: Viewer attempts to open Admin page
- **Status**: ✅ PASS
- **Procedure**: Login as Viewer, navigate to users.html, requests.html, audit-logs.html
- **Result**: Access denied alert shown, redirected to index.html
- **Evidence**: `requireRole(["Administrator"])` guard blocks access

### TC-A4-02: Staff submits request
- **Status**: ✅ PASS
- **Procedure**: Login as Laboratory Staff, go to borrowing.html, submit request for available equipment
- **Result**: Request saved as Pending. Equipment validated (BR-A4-01).
- **Evidence**: `submit_borrowing_request` RPC returns success with request_id

### TC-A4-03: Administrator approves request
- **Status**: ✅ PASS
- **Procedure**: Login as Administrator, go to borrowing.html, click Approve on Pending request
- **Result**: Status becomes Approved; audit log entry created in audit_logs table
- **Evidence**: `approve_borrowing_request` RPC updates status to Approved and inserts audit_logs record

### TC-A4-04: Administrator rejects request
- **Status**: ✅ PASS
- **Procedure**: Login as Administrator, click Reject on Pending request
- **Result**: Status becomes Rejected
- **Evidence**: `reject_borrowing_request` RPC updates status to Rejected

### TC-A4-05: Attempt to release rejected request
- **Status**: ✅ PASS
- **Procedure**: After rejection, attempt to release the request (as staff)
- **Result**: Operation blocked - `release_equipment` function returns error: "Only Approved requests may be released."
- **Evidence**: BR-A4-07 enforced in release_equipment() function

### TC-A4-06: Release approved equipment
- **Status**: ✅ PASS
- **Procedure**: After approval, click Release button on Approved request
- **Result**: Equipment becomes Borrowed; request status becomes Released
- **Evidence**: `release_equipment` RPC updates equipment.status to 'Borrowed' and request.status to 'Released'

### TC-A4-07: Return released equipment
- **Status**: ✅ PASS
- **Procedure**: Go to returns.html, click Return on released equipment
- **Result**: Equipment returns to Available status; request becomes Returned
- **Evidence**: `return_equipment` RPC updates equipment.status to 'Available' and request.status to 'Returned'

### TC-A4-08: Check audit log after approval
- **Status**: ✅ PASS
- **Procedure**: After approval, navigate to audit-logs.html
- **Result**: Approval entry visible with action=APPROVED, correct module, record_id, description
- **Evidence**: audit_logs table contains entry for the approval

### TC-A4-09: Staff attempts restricted delete
- **Status**: ✅ PASS
- **Procedure**: Login as Staff, attempt to delete user on users.html
- **Result**: Access denied - `requireRole(["Administrator"])` on users.html blocks access
- **Evidence**: Guard redirect to index.html with alert

### TC-A4-10: Logout and open protected page
- **Status**: ✅ PASS
- **Procedure**: Logout, navigate to any protected page
- **Result**: Redirected to login.html (no auth session)
- **Evidence**: `getCurrentUser()` redirects to login.html when no user session

---

## Business Rules Verification

| Rule | Description | Status |
|------|-------------|--------|
| BR-A4-01 | Only available equipment may be requested | ✅ Enforced in `submit_borrowing_request()` |
| BR-A4-02 | Staff cannot approve their own request | ✅ Checked in `approve_borrowing_request()` |
| BR-A4-03 | Only Administrator may approve or reject | ✅ Enforced in approval/rejection functions |
| BR-A4-04 | Only Approved requests may be released | ✅ Enforced in `release_equipment()` |
| BR-A4-05 | Released equipment becomes Borrowed | ✅ Enforced in `release_equipment()` |
| BR-A4-06 | Returned equipment becomes Available unless damaged | ✅ Enforced in `return_equipment()` |
| BR-A4-07 | Rejected requests cannot be released | ✅ Enforced in `release_equipment()` |
| BR-A4-08 | Returned transactions cannot be processed twice | ✅ Enforced in `return_equipment()` |
| BR-A4-09 | Equipment under Maintenance cannot be borrowed | ✅ Enforced in `submit_borrowing_request()` |
| BR-A4-10 | Sensitive operations must be logged | ✅ All operations logged via audit_logs |

---

## Database Security

- Row Level Security (RLS) enabled on all tables
- Policies enforce role-based access at database level
- Service role used only for audit_logs inserts (background logging)
- All business logic enforced via PostgreSQL functions (security definer)
- Client-side guards complement server-side RLS policies
