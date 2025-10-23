// -------------------- API Fetch Helper --------------------
let AUTH_TOKEN = null;

async function apiFetch(path, opts = {}) {
    const base = window.APP_CONFIG?.API_BASE_URL || "http://localhost:3000";
    const url = `${base}${path}`;

    const headers = {
        'Content-Type': 'application/json',
        ...opts.headers // Allow custom headers to be passed
    };

    // Add authentication token to headers if it exists
    if (AUTH_TOKEN) {
        headers['Authorization'] = `Bearer ${AUTH_TOKEN}`;
    }

    const res = await fetch(url, { ...opts, headers });
    return res;
}

/* ---------- Notification / Toast utilities ---------- */
const _toastRoot = (() => {
    let root = document.querySelector('.toasts');
    if (!root) {
        root = document.createElement('div');
        root.className = 'toasts';
        document.body.appendChild(root);
    }
    return root;
})();

function showToast(text, type = 'info', timeout = 4000) {
    const el = document.createElement('div');
    el.className = `toast ${type === 'success' ? 'success' : (type === 'error' ? 'warn' : '')}`;
    el.innerHTML = `<div class="t-text">${text}</div>`;
    _toastRoot.appendChild(el);
    setTimeout(() => {
        el.style.opacity = 0;
        setTimeout(() => el.remove(), 400);
    }, timeout);
}

function playBeep(freq = 880, duration = 130, volume = 0.06) {
    try {
        const ctx = new(window.AudioContext || window.webkitAudioContext)();
        const o = ctx.createOscillator();
        const g = ctx.createGain();
        o.type = 'sine';
        o.frequency.value = freq;
        g.gain.value = volume;
        o.connect(g);
        g.connect(ctx.destination);
        o.start();
        setTimeout(() => {
            o.stop();
            ctx.close();
        }, duration);
    } catch (e) { /* ignore audio errors */ }
}

async function sendBrowserNotification(title, text) {
    if (!('Notification' in window)) return;
    if (Notification.permission === 'granted') {
        new Notification(title, { body: text });
    } else if (Notification.permission !== 'denied') {
        const p = await Notification.requestPermission();
        if (p === 'granted') new Notification(title, { body: text });
    }
}

/* ---------------- Global Auth + UI Handler ---------------- */
document.addEventListener('DOMContentLoaded', () => {
    const path = window.location.pathname;

    // Retrieve token and other user data from localStorage on load
    AUTH_TOKEN = localStorage.getItem('token');
    const role = localStorage.getItem('role');
    const userId = localStorage.getItem('userId');
    const siteNo = localStorage.getItem('site_no');

    // Skip check on login page (index.html) and client page (client.html)
    if (!path.endsWith('index.html') && !path.endsWith('/') && !path.includes('/client.html')) {
        if (!AUTH_TOKEN || !role || !userId) {
            // Not logged in → redirect
            window.location.href = "/index.html";
            return;
        }

        // Inject "Signed in as ..." if element exists
        const whoEl = document.getElementById('who');
        if (whoEl) {
            whoEl.innerText = `${userId} (Site ${siteNo || 'Global'})`;
        }
    }

    // ---------------- Login handler (only on index.html) ----------------
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', async(e) => {
            e.preventDefault();
            const formData = new FormData(e.target);
            const data = {
                site_no: formData.get('site_no'),
                id: formData.get('id'),
                password: formData.get('password')
            };

            try {
                const res = await apiFetch('/api/login', {
                    method: 'POST',
                    body: JSON.stringify(data)
                });
                const result = await res.json();

                if (!res.ok) {
                    document.getElementById('message').innerText = result.message || 'Login failed';
                    showToast(result.message || 'Login failed', 'warn');
                    playBeep(300, 200, 0.08);
                    return;
                }

                // Get and store all user data, including the token
                const role = result.role;
                const userId = result.id;
                const siteNo = String(result.site_no);
                const token = result.token;

                localStorage.setItem('userId', userId);
                localStorage.setItem('role', role);
                localStorage.setItem('site_no', siteNo);
                localStorage.setItem('token', token); // Store the token
                AUTH_TOKEN = token; // Update the global variable

                if (role === 'client') {
                    const clientUrl = `${window.location.origin}/client.html?site_no=${siteNo}&valet_id=${userId}`;
                    const wrapper = document.getElementById('valetLinkWrapper');
                    const input = document.getElementById('valetLink');
                    if (wrapper && input) {
                        input.value = clientUrl;
                        wrapper.style.display = 'block';
                        showToast('Valet link generated! Copy and share with your client.', 'success');
                    } else {
                        window.location.href = clientUrl;
                    }
                } else if (role === 'superadmin') {
                    window.location.href = 'superadmin.html';
                } else {
                    window.location.href = `site_${siteNo}/${role}.html`;
                }
            } catch (err) {
                document.getElementById('message').innerText = 'Server error';
                showToast('Server error while logging in', 'warn');
            }
        });
    }

    // Copy valet link to clipboard
    window.copyValetLink = () => {
        const input = document.getElementById('valetLink');
        input.select();
        input.setSelectionRange(0, 99999);
        navigator.clipboard.writeText(input.value);
        showToast('Valet link copied!', 'success');
    };

    // ---------------- Logout handler (global) ----------------
    logoutBtn.addEventListener("click", async () => {
    try {
        const driverId = localStorage.getItem("userId");
        const siteNo = localStorage.getItem("site_no");
        const role = localStorage.getItem("role");

        if (role === "driver") {
            // Notify backend that driver session is ending
            await apiFetch("/api/site_" + siteNo + "/driver-session/end", {
                method: "POST",
                body: JSON.stringify({ driver_id: driverId, site_no: siteNo })
            });
        }
    } catch (err) {
        console.error("Logout API error:", err);
    } finally {
        // Always clear frontend state
        localStorage.clear();
        AUTH_TOKEN = null;
        window.location.href = "/index.html";
    }
});


    // ---------------- Language handler ----------------
    let currentLang = localStorage.getItem("lang") || "EN";
    const langSelect = document.getElementById("langSelect");
    if (langSelect) {
        langSelect.value = currentLang;
        langSelect.addEventListener("change", (e) => {
            currentLang = e.target.value;
            localStorage.setItem("lang", currentLang);
            applyTranslations();
        });
    }

    async function applyTranslations() {
        const elements = document.querySelectorAll("[data-translate]");
        for (const el of elements) {
            const original = el.getAttribute("data-original") || el.innerText;
            el.setAttribute("data-original", original);
            el.innerText = await translateText(original);
        }
        const dynamicEls = document.querySelectorAll(".translate-dynamic");
        for (const el of dynamicEls) {
            const original = el.getAttribute("data-original") || el.innerText;
            el.setAttribute("data-original", original);
            el.innerText = await translateText(original);
        }
    }

    async function translateText(text, targetLang = currentLang) {
        if (!text || targetLang === "EN") return text;
        try {
            const res = await apiFetch("/api/translate", {
                method: "POST",
                body: JSON.stringify({ text, targetLang }),
            });
            const data = await res.json();
            return data.translated || text;
        } catch (err) {
            console.error("Translation error:", err);
            return text;
        }
    }

    applyTranslations();
});