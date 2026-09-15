import { supabase } from './supabase.js';

// ========================================
// GET CURRENT AUTHENTICATED USER
// ========================================

export async function getCurrentUser() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) {
        window.location.href = "login.html";
        return null;
    }
    return user;
}

// ========================================
// GET USER PROFILE
// ========================================

export async function getUserProfile(userId) {
    const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
    if (error) {
        console.error("Profile error:", error);
        return null;
    }
    return data;
}

// ========================================
// GET CURRENT USER + PROFILE
// ========================================

export async function getCurrentUserProfile() {
    const user = await getCurrentUser();
    if (!user) return null;
    const profile = await getUserProfile(user.id);
    if (!profile) {
        alert("User profile not found.");
        await supabase.auth.signOut();
        window.location.href = "login.html";
        return null;
    }
    return { authUser: user, profile };
}

// ========================================
// REQUIRE LOGIN
// ========================================

export async function requireLogin() {
    return await getCurrentUserProfile();
}

// ========================================
// CHECK AUTH WITHOUT REDIRECT (for login page)
// ========================================

export async function checkAuthOnly() {
    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) return null;
    return user;
}

// ========================================
// REQUIRE SPECIFIC ROLE
// ========================================

export async function requireRole(allowedRoles) {
    const result = await getCurrentUserProfile();
    if (!result) return null;
    const profile = result.profile;
    if (!allowedRoles.includes(profile.role)) {
        alert("Access denied. You do not have permission to access this page.");
        window.location.href = "index.html";
        return null;
    }
    return result;
}

// ========================================
// LOGOUT
// ========================================

export async function logout() {
    const { error } = await supabase.auth.signOut();
    if (error) {
        console.error("Logout error:", error);
        alert("Unable to logout.");
        return;
    }
    window.location.href = "login.html";
}

// ========================================
// CHECK IF ADMIN
// ========================================

export function isAdmin(profile) {
    return profile && profile.role === 'Administrator';
}

// ========================================
// CHECK IF STAFF
// ========================================

export function isStaff(profile) {
    return profile && profile.role === 'Laboratory Staff';
}

// ========================================
// CHECK IF REQUESTER/VIEWER
// ========================================

export function isRequester(profile) {
    return profile && ['Requester', 'Viewer'].includes(profile.role);
}
