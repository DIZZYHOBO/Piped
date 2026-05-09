/* Shared chrome (top bar + sidebar) + theme/sidebar toggles for the mockup pages.
   Pages opt in by including <div data-shell="..." data-active="home"></div> placeholders. */
(function () {
    const root = document.documentElement;
    const savedTheme = localStorage.getItem("piped-mock-theme") || "dark";
    const savedSidebar = localStorage.getItem("piped-mock-sidebar") || "expanded";
    root.setAttribute("data-theme", savedTheme);

    const NAV_PRIMARY = [
        { id: "home", icon: "home", label: "Home", href: "home.html" },
        { id: "shorts", icon: "bolt", label: "Shorts", href: "home.html#shorts" },
        { id: "subs", icon: "subscriptions", label: "Subscriptions", href: "subscriptions.html" },
    ];
    const NAV_YOU = [
        { id: "library", icon: "video_library", label: "Library", href: "library.html" },
        { id: "history", icon: "history", label: "History", href: "library.html#history" },
        { id: "playlists", icon: "playlist_play", label: "Playlists", href: "library.html#playlists" },
        { id: "watchlater", icon: "schedule", label: "Watch later", href: "library.html#watchlater" },
        { id: "liked", icon: "thumb_up", label: "Liked videos", href: "library.html#liked" },
    ];
    const NAV_EXPLORE = [
        { id: "trending", icon: "local_fire_department", label: "Trending", href: "trending.html" },
        { id: "music", icon: "music_note", label: "Music", href: "#" },
        { id: "gaming", icon: "stadia_controller", label: "Gaming", href: "#" },
        { id: "news", icon: "newspaper", label: "News", href: "#" },
        { id: "live", icon: "podcasts", label: "Live", href: "#" },
    ];
    const NAV_FOOTER = [
        { id: "settings", icon: "settings", label: "Settings", href: "#" },
        { id: "help", icon: "help", label: "Help", href: "#" },
        { id: "feedback", icon: "feedback", label: "Send feedback", href: "#" },
    ];
    const SUBS = [
        { name: "Linus Tech Tips", color: "#cc1d1d" },
        { name: "Fireship", color: "#ff6a00" },
        { name: "Veritasium", color: "#1976d2" },
        { name: "MKBHD", color: "#222" },
        { name: "Kurzgesagt", color: "#00838f" },
        { name: "Tom Scott", color: "#388e3c" },
    ];

    function navItem(item, activeId) {
        const fill = item.id === activeId ? "is-active" : "";
        return `<a href="${item.href}" class="nav-item ${fill}">
            <span class="material-symbols-outlined">${item.icon}</span>
            <span class="nav-item__label">${item.label}</span>
        </a>`;
    }
    function subItem(s) {
        const initials = s.name
            .split(" ")
            .map(w => w[0])
            .slice(0, 2)
            .join("");
        return `<a href="channel.html" class="nav-item">
            <span class="avatar" style="width:24px;height:24px;font-size:11px;background:${s.color}">${initials}</span>
            <span class="nav-item__label">${s.name}</span>
        </a>`;
    }

    function buildTopbar() {
        return `
        <header class="topbar">
            <div class="topbar__left">
                <button class="icon-btn" data-sidebar-toggle aria-label="Toggle sidebar">
                    <span class="material-symbols-outlined">menu</span>
                </button>
                <a class="brand" href="home.html">
                    <img src="/img/icons/logo.svg" alt="Piped logo" />iped<sup>BETA</sup>
                </a>
            </div>
            <div class="search">
                <form class="search__form" onsubmit="event.preventDefault(); location.href='search.html';">
                    <input class="search__input" type="text" placeholder="Search" value="" />
                    <button class="search__btn" type="submit" aria-label="Search">
                        <span class="material-symbols-outlined">search</span>
                    </button>
                </form>
                <button class="search__mic hide-md" aria-label="Search with voice">
                    <span class="material-symbols-outlined">mic</span>
                </button>
            </div>
            <div class="topbar__right">
                <div class="toggle-group hide-md" title="Theme">
                    <button data-theme-btn="dark">Dark</button>
                    <button data-theme-btn="light">Light</button>
                </div>
                <button class="icon-btn" aria-label="Create"><span class="material-symbols-outlined">video_call</span></button>
                <button class="icon-btn" aria-label="Notifications"><span class="material-symbols-outlined">notifications</span></button>
                <span class="avatar" title="Account">P</span>
            </div>
        </header>`;
    }

    function buildSidebar(activeId) {
        const primary = NAV_PRIMARY.map(n => navItem(n, activeId)).join("");
        const you = NAV_YOU.map(n => navItem(n, activeId)).join("");
        const explore = NAV_EXPLORE.map(n => navItem(n, activeId)).join("");
        const subs = SUBS.map(subItem).join("");
        const footer = NAV_FOOTER.map(n => navItem(n, activeId)).join("");
        return `<aside class="sidebar">
            <div class="sidebar__section">${primary}</div>
            <div class="sidebar__section sidebar__section--full">
                <div class="sidebar__title">You ›</div>
                ${you}
            </div>
            <div class="sidebar__section sidebar__section--full">
                <div class="sidebar__title">Subscriptions</div>
                ${subs}
            </div>
            <div class="sidebar__section sidebar__section--full">
                <div class="sidebar__title">Explore</div>
                ${explore}
            </div>
            <div class="sidebar__section sidebar__section--full">
                ${footer}
            </div>
        </aside>`;
    }

    function applyTheme(theme) {
        root.setAttribute("data-theme", theme);
        localStorage.setItem("piped-mock-theme", theme);
        document.querySelectorAll("[data-theme-btn]").forEach(b => {
            b.classList.toggle("is-active", b.dataset.themeBtn === theme);
        });
    }

    function applySidebar(state) {
        const app = document.querySelector(".app");
        if (!app) return;
        app.setAttribute("data-sidebar", state);
        localStorage.setItem("piped-mock-sidebar", state);
    }

    document.addEventListener("DOMContentLoaded", () => {
        const app = document.querySelector(".app");
        if (app) {
            const activeId = app.dataset.active || "";
            const topMount = app.querySelector("[data-shell='topbar']");
            const sideMount = app.querySelector("[data-shell='sidebar']");
            if (topMount) topMount.outerHTML = buildTopbar();
            if (sideMount) sideMount.outerHTML = buildSidebar(activeId);
            applySidebar(savedSidebar);
        }
        applyTheme(savedTheme);

        document.addEventListener("click", e => {
            const t = e.target.closest("[data-theme-btn]");
            if (t) applyTheme(t.dataset.themeBtn);
            const s = e.target.closest("[data-sidebar-toggle]");
            if (s) {
                const cur = document.querySelector(".app").getAttribute("data-sidebar") || "expanded";
                applySidebar(cur === "expanded" ? "rail" : "expanded");
            }
        });
    });
})();
