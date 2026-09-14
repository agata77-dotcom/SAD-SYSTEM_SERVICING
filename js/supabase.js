// ========================================
// SUPABASE CONNECTION
// ========================================

const SUPABASE_URL = "https://qotbafdtzhfodwplgivp.supabase.co";
const SUPABASE_KEY = "sb_publishable_GPOAhQG-JNgLxm2yv0Tfqg_3igl5D6X";

const supabaseClient = supabase.createClient(
    SUPABASE_URL,
    SUPABASE_KEY
);