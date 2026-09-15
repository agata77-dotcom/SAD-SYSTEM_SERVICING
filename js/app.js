import { supabase } from './supabase.js';
import { getCurrentUserProfile, logout } from './auth.js';

async function initializeDashboard() {
    const result = await getCurrentUserProfile();
    if (!result) return;

    const profile = result.profile;

    // Display user info
    const userName = document.getElementById("userName");
    const userRole = document.getElementById("userRole");
    const welcomeMessage = document.getElementById("welcomeMessage");

    if (userName) userName.textContent = profile.full_name || "User";
    if (userRole) userRole.textContent = profile.role || "User";
    if (welcomeMessage) welcomeMessage.textContent = `Welcome, ${profile.full_name || "User"}!`;

    // Show correct role menu
    const adminMenu = document.querySelector(".admin-menu");
    const staffMenu = document.querySelector(".staff-menu");
    const viewerMenu = document.querySelector(".viewer-menu");

    if (adminMenu) adminMenu.style.display = "none";
    if (staffMenu) staffMenu.style.display = "none";
    if (viewerMenu) viewerMenu.style.display = "none";

    if (profile.role === "Administrator") {
        if (adminMenu) adminMenu.style.display = "block";
    } else if (profile.role === "Laboratory Staff") {
        if (staffMenu) staffMenu.style.display = "block";
    } else if (['Requester', 'Viewer', 'Requester / Viewer'].includes(profile.role)) {
        if (viewerMenu) viewerMenu.style.display = "block";
    } else {
        console.warn("Unknown user role:", profile.role);
    }

    await loadRequestStatistics(profile, result.authUser);
}

async function loadRequestStatistics(profile, authUser) {
    // Load request counts from borrowing_requests for admin/staff
    let borrowQuery = supabase
        .from("borrowing_requests")
        .select("status", { count: "exact" });

    if (['Requester', 'Viewer', 'Requester / Viewer'].includes(profile.role)) {
        borrowQuery = borrowQuery.eq("user_id", authUser.id);
    }

    const { data: borrowData, error: borrowError } = await borrowQuery;

    if (!borrowError && borrowData) {
        const total = borrowData.length;
        const pending = borrowData.filter(r => r.status === "Pending").length;
        const approved = borrowData.filter(r => r.status === "Approved").length;
        const completed = borrowData.filter(r => ['Returned', 'Closed'].includes(r.status)).length;

        setText("totalRequests", total);
        setText("pendingRequests", pending);
        setText("approvedRequests", approved);
        setText("completedRequests", completed);
    }

    // Also load service_requests for compatibility
    let query = supabase.from("service_requests").select("id, status, user_id", { count: "exact" });

    if (['Requester', 'Viewer', 'Requester / Viewer'].includes(profile.role)) {
        query = query.eq("user_id", authUser.id);
    }

    const { data, error } = await query;
    if (error) { console.error("Request statistics error:", error); return; }

    const requests = data || [];
    const total = requests.length;
    const pending = requests.filter(r => r.status === "Pending").length;
    const approved = requests.filter(r => r.status === "Approved").length;
    const completed = requests.filter(r => r.status === "Completed").length;

    // Use borrowing stats if available, else service request stats
    if (borrowData) {
        // Already set above
    } else {
        setText("totalRequests", total);
        setText("pendingRequests", pending);
        setText("approvedRequests", approved);
        setText("completedRequests", completed);
    }
}

function setText(id, value) {
    const el = document.getElementById(id);
    if (el) el.textContent = value;
}

// Logout button
const logoutBtn = document.getElementById("logoutBtn");
if (logoutBtn) {
    logoutBtn.addEventListener("click", async () => { await logout(); });
}

// Page-level auth guard (redirect if not logged in)
(async () => {
    const user = await getCurrentUserProfile();
    if (!user) return;
    initializeDashboard();
})();