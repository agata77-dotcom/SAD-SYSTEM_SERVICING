// ========================================
// AUTHENTICATION
// ========================================

// Get the current page name
const currentPage = window.location.pathname.split("/").pop();


// ========================================
// LOGIN
// ========================================

const loginForm = document.getElementById("loginForm");

if (loginForm) {

    loginForm.addEventListener("submit", async function (event) {

        event.preventDefault();

        const email = document.getElementById("email").value.trim();
        const password = document.getElementById("password").value;
        const loginMessage = document.getElementById("loginMessage");

        loginMessage.textContent = "Logging in...";

        const { data, error } =
            await supabaseClient.auth.signInWithPassword({
                email: email,
                password: password
            });

        // Login failed
        if (error) {

            console.error("Login error:", error);

            loginMessage.textContent =
                "Login failed: " + error.message;

            return;
        }

        // Login successful
        loginMessage.textContent =
            "Login successful! Redirecting...";

        window.location.href = "index.html";
    });
}


// ========================================
// CHECK USER SESSION
// ========================================

async function checkUserSession() {

    const {
        data: { session },
        error
    } = await supabaseClient.auth.getSession();

    if (error) {

        console.error(
            "Session error:",
            error
        );

        return;
    }


    // ----------------------------------------
    // User is NOT logged in
    // ----------------------------------------

    if (!session && currentPage === "index.html") {

        window.location.href = "login.html";

        return;
    }


    // ----------------------------------------
    // User IS logged in
    // but is trying to access login page
    // ----------------------------------------

    if (session && currentPage === "login.html") {

        window.location.href = "index.html";

        return;
    }
}


// ========================================
// LOGOUT
// ========================================

const logoutBtn =
    document.getElementById("logoutBtn");

if (logoutBtn) {

    logoutBtn.addEventListener(
        "click",
        async function () {

            const { error } =
                await supabaseClient.auth.signOut();

            if (error) {

                console.error(
                    "Logout error:",
                    error
                );

                alert(
                    "Logout failed: " +
                    error.message
                );

                return;
            }

            // Return to login page
            window.location.href = "login.html";
        }
    );
}


// ========================================
// RUN SESSION CHECK
// ========================================

checkUserSession();
