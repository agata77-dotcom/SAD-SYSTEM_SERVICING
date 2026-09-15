-- ========================================
-- BUSINESS RULES REFERENCE
-- BR-A4-01 through BR-A4-10
-- ========================================

-- BR-A4-01: Only available equipment may be requested.
-- Enforced in submit_borrowing_request() function.
-- Equipment status must be 'Available'.

-- BR-A4-02: Staff cannot approve their own request.
-- Enforced in approve_borrowing_request() function.
-- If approver role = 'Laboratory Staff' and user_id = approver_id, reject.

-- BR-A4-03: Only Administrator may approve or reject requests.
-- Enforced in approve_borrowing_request() and reject_borrowing_request() functions.
-- Role must be 'Administrator'.

-- BR-A4-04: Only Approved requests may be released.
-- Enforced in release_equipment() function.
-- Status must be 'Approved' before release.

-- BR-A4-05: Released equipment becomes Borrowed.
-- Enforced in release_equipment() function.
-- Equipment status updated to 'Borrowed'.

-- BR-A4-06: Returned equipment becomes Available unless damaged.
-- Enforced in return_equipment() function.
-- Equipment status = 'Available' if not damaged, 'Unavailable' if damaged.

-- BR-A4-07: Rejected requests cannot be released.
-- Enforced in release_equipment() function.
-- Only 'Approved' requests can be released.

-- BR-A4-08: Returned transactions cannot be processed twice.
-- Enforced in return_equipment() function.
-- If status is already 'Returned', block further return.

-- BR-A4-09: Equipment under Maintenance cannot be borrowed.
-- Enforced in submit_borrowing_request() function.
-- Equipment status must not be 'Under Maintenance'.

-- BR-A4-10: Sensitive operations must be logged.
-- All operations (SUBMITTED, APPROVED, REJECTED, RELEASED, RETURNED, CLOSED)
-- are logged in audit_logs table via the corresponding functions.
