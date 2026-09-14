// ========================================
// SERVICE REQUEST MANAGEMENT
// ========================================

let requests = [];
let currentUser = null;


// ========================================
// GET CURRENT USER
// ========================================

async function getCurrentUser() {

    const {
        data: { user },
        error
    } = await supabaseClient.auth.getUser();

    if (error || !user) {

        window.location.href = "login.html";

        return null;
    }

    currentUser = user;

    return user;
}


// ========================================
// LOAD REQUESTS
// ========================================

async function loadRequests() {

    const { data, error } = await supabaseClient
        .from("service_requests")
        .select("*")
        .order("created_at", { ascending: false });

    if (error) {

        console.error("Error loading requests:", error);

        alert("Unable to load service requests.");

        return;
    }

    requests = data || [];

    displayRequests(requests);
    updateDashboard(requests);
}


// ========================================
// DISPLAY REQUESTS
// ========================================

function displayRequests(data) {

    const tableBody = document.getElementById("requestTableBody");

    tableBody.innerHTML = "";

    if (data.length === 0) {

        tableBody.innerHTML = `
            <tr>
                <td colspan="8" style="text-align: center;">
                    No service requests found.
                </td>
            </tr>
        `;

        return;
    }


    data.forEach(request => {

        const row = document.createElement("tr");

        const date = new Date(request.created_at)
            .toLocaleDateString();

        row.innerHTML = `
            <td>${request.id}</td>

            <td>${escapeHTML(request.requester_name)}</td>

            <td>${escapeHTML(request.department)}</td>

            <td>${escapeHTML(request.category)}</td>

            <td>${escapeHTML(request.priority)}</td>

            <td>${escapeHTML(request.status)}</td>

            <td>${date}</td>

            <td>
                <button
                    class="btn-edit"
                    onclick="editRequest(${request.id})">
                    Edit
                </button>

                <button
                    class="btn-delete"
                    onclick="deleteRequest(${request.id})">
                    Delete
                </button>
            </td>
        `;

        tableBody.appendChild(row);
    });
}


// ========================================
// DASHBOARD
// ========================================

function updateDashboard(data) {

    const total = data.length;

    const pending = data.filter(
        request => request.status === "Pending"
    ).length;

    const inProgress = data.filter(
        request => request.status === "In Progress"
    ).length;

    const completed = data.filter(
        request => request.status === "Completed"
    ).length;


    document.getElementById("totalRequests").textContent = total;

    document.getElementById("pendingRequests").textContent = pending;

    document.getElementById("inProgressRequests").textContent = inProgress;

    document.getElementById("completedRequests").textContent = completed;
}


// ========================================
// CREATE / UPDATE FORM
// ========================================

const requestForm = document.getElementById("requestForm");

if (requestForm) {

    requestForm.addEventListener("submit", async function (event) {

        event.preventDefault();

        const requestId =
            document.getElementById("requestId").value;

        const requesterName =
            document.getElementById("requesterName").value.trim();

        const department =
            document.getElementById("department").value.trim();

        const category =
            document.getElementById("category").value;

        const description =
            document.getElementById("description").value.trim();

        const priority =
            document.getElementById("priority").value;

        const status =
            document.getElementById("status").value;

        const message =
            document.getElementById("requestMessage");


        // ========================================
        // VALIDATION
        // ========================================

        if (!requesterName) {

            message.textContent =
                "Requester name is required.";

            return;
        }

        if (!department) {

            message.textContent =
                "Department is required.";

            return;
        }

        if (!category) {

            message.textContent =
                "Please select a category.";

            return;
        }

        if (description.length < 10) {

            message.textContent =
                "Description must contain sufficient information.";

            return;
        }

        if (!priority) {

            message.textContent =
                "Please select a priority.";

            return;
        }


        // ========================================
        // UPDATE
        // ========================================

        if (requestId) {

            const { error } = await supabaseClient
                .from("service_requests")
                .update({
                    requester_name: requesterName,
                    department: department,
                    category: category,
                    description: description,
                    priority: priority,
                    status: status
                })
                .eq("id", requestId);


            if (error) {

                console.error(error);

                message.textContent =
                    "Failed to update request.";

                return;
            }


            message.textContent =
                "Request updated successfully.";

        }


        // ========================================
        // CREATE
        // ========================================

        else {

            const { error } = await supabaseClient
                .from("service_requests")
                .insert([
                    {
                        requester_name: requesterName,
                        department: department,
                        category: category,
                        description: description,
                        priority: priority,
                        status: "Pending",
                        user_id: currentUser.id
                    }
                ]);


            if (error) {

                console.error(error);

                message.textContent =
                    "Failed to create request.";

                return;
            }


            message.textContent =
                "Request created successfully.";
        }


        // Reload data
        await loadRequests();

        // Close modal
        setTimeout(() => {

            closeModal();

        }, 500);
    });
}


// ========================================
// OPEN NEW REQUEST MODAL
// ========================================

const newRequestBtn =
    document.getElementById("newRequestBtn");

if (newRequestBtn) {

    newRequestBtn.addEventListener("click", function () {

        openNewRequestModal();

    });
}


function openNewRequestModal() {

    document.getElementById("modalTitle").textContent =
        "New Service Request";

    document.getElementById("requestForm").reset();

    document.getElementById("requestId").value = "";

    document.getElementById("status").value = "Pending";

    document.getElementById("statusGroup").style.display = "none";

    document.getElementById("requestMessage").textContent = "";

    document.getElementById("requestModal").style.display = "flex";
}


// ========================================
// EDIT REQUEST
// ========================================

async function editRequest(id) {

    const request = requests.find(
        item => item.id === id
    );

    if (!request) {

        alert("Request not found.");

        return;
    }


    document.getElementById("modalTitle").textContent =
        "Edit Service Request";

    document.getElementById("requestId").value =
        request.id;

    document.getElementById("requesterName").value =
        request.requester_name;

    document.getElementById("department").value =
        request.department;

    document.getElementById("category").value =
        request.category;

    document.getElementById("description").value =
        request.description;

    document.getElementById("priority").value =
        request.priority;

    document.getElementById("status").value =
        request.status;

    document.getElementById("statusGroup").style.display =
        "block";

    document.getElementById("requestMessage").textContent =
        "";

    document.getElementById("requestModal").style.display =
        "flex";
}


// ========================================
// DELETE REQUEST
// ========================================

async function deleteRequest(id) {

    const confirmed = confirm(
        "Are you sure you want to delete this request?"
    );

    if (!confirmed) {

        return;
    }


    const { error } = await supabaseClient
        .from("service_requests")
        .delete()
        .eq("id", id);


    if (error) {

        console.error(error);

        alert(
            "Unable to delete request. You may not have permission."
        );

        return;
    }


    await loadRequests();
}


// ========================================
// SEARCH AND FILTER
// ========================================

function applyFilters() {

    const search =
        document.getElementById("searchInput")
            .value
            .toLowerCase()
            .trim();

    const status =
        document.getElementById("statusFilter").value;

    const priority =
        document.getElementById("priorityFilter").value;


    const filtered = requests.filter(request => {

        const matchesSearch =
            request.requester_name
                .toLowerCase()
                .includes(search)

            ||

            request.description
                .toLowerCase()
                .includes(search);


        const matchesStatus =
            !status ||
            request.status === status;


        const matchesPriority =
            !priority ||
            request.priority === priority;


        return (
            matchesSearch &&
            matchesStatus &&
            matchesPriority
        );
    });


    displayRequests(filtered);

    // Dashboard can remain based on all requests
}


// Search
const searchInput =
    document.getElementById("searchInput");

if (searchInput) {

    searchInput.addEventListener(
        "input",
        applyFilters
    );
}


// Status filter
const statusFilter =
    document.getElementById("statusFilter");

if (statusFilter) {

    statusFilter.addEventListener(
        "change",
        applyFilters
    );
}


// Priority filter
const priorityFilter =
    document.getElementById("priorityFilter");

if (priorityFilter) {

    priorityFilter.addEventListener(
        "change",
        applyFilters
    );
}


// ========================================
// MODAL CONTROLS
// ========================================

const closeModalBtn =
    document.getElementById("closeModalBtn");

const cancelBtn =
    document.getElementById("cancelBtn");


if (closeModalBtn) {

    closeModalBtn.addEventListener(
        "click",
        closeModal
    );
}


if (cancelBtn) {

    cancelBtn.addEventListener(
        "click",
        closeModal
    );
}


function closeModal() {

    document.getElementById("requestModal").style.display =
        "none";

    document.getElementById("requestForm").reset();

    document.getElementById("requestId").value = "";

    document.getElementById("statusGroup").style.display =
        "none";

    document.getElementById("requestMessage").textContent =
        "";
}


// ========================================
// BASIC HTML ESCAPING
// ========================================

function escapeHTML(value) {

    return String(value)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;")
        .replaceAll("'", "&#039;");
}


// ========================================
// START APPLICATION
// ========================================

async function initializeApp() {

    const user = await getCurrentUser();

    if (!user) {

        return;
    }

    await loadRequests();
}


initializeApp();