<template>
    <header class="sticky top-0 z-50 flex h-(--topbar-h) items-center gap-2 bg-yt-bg px-2 sm:gap-4 sm:px-4">
        <!-- Left: hamburger + logo -->
        <div class="flex items-center gap-2 md:min-w-(--sidebar-w)">
            <button
                type="button"
                class="hidden size-10 items-center justify-center rounded-full text-yt-text hover:bg-yt-surface md:inline-flex"
                aria-label="Toggle menu"
                @click="$emit('toggle-sidebar')"
            >
                <i-fa6-solid-bars />
            </button>
            <button
                type="button"
                class="flex size-10 items-center justify-center rounded-full text-yt-text hover:bg-yt-surface md:hidden"
                aria-label="Mobile nav"
                @click="showMobileNav = !showMobileNav"
            >
                <i-fa6-solid-bars />
            </button>
            <router-link to="/" class="flex items-center font-sans text-2xl font-bold tracking-tight">
                <img alt="logo" src="/img/icons/logo.svg" height="32" width="32" class="-mr-2 w-8" />iped
            </router-link>
        </div>

        <!-- Middle: search (desktop) -->
        <div class="relative mx-auto hidden max-w-[640px] flex-1 md:flex">
            <input
                ref="videoSearch"
                v-model="searchText"
                class="h-10 w-full rounded-l-full border border-yt-border bg-yt-bg px-4 text-base text-yt-text outline-none focus:border-blue-500 focus:shadow-[inset_0_0_0_1px_#3ea6ff] dark:bg-dark-900"
                type="text"
                role="search"
                :title="$t('actions.search')"
                :placeholder="$t('actions.search')"
                @keyup="onKeyUp"
                @keypress="onKeyPress"
                @focus="onInputFocus"
                @blur="onInputBlur"
            />
            <button
                id="search-btn"
                class="flex h-10 w-16 items-center justify-center rounded-r-full border border-l-0 border-yt-border bg-yt-surface text-yt-text hover:bg-yt-surface-hover"
                :title="$t('actions.search')"
                @click="onSearchClick"
            >
                <i-fa6-solid-magnifying-glass />
            </button>
            <ClearButton v-if="searchText" @clear="searchText = ''" />
        </div>

        <!-- Right: actions -->
        <div class="ml-auto flex items-center gap-1">
            <router-link
                v-if="shouldShowLogin"
                to="/login"
                class="hidden h-9 items-center gap-1.5 rounded-full border border-yt-border px-3 text-sm font-medium text-yt-brand-red hover:bg-yt-surface md:inline-flex"
            >
                <i-fa6-solid-user />
                <span v-t="'titles.login'" />
            </router-link>
            <span
                v-else
                class="grid size-8 place-items-center rounded-full bg-linear-to-br from-red-700 to-orange-500 text-sm font-semibold text-white"
                :title="$t('titles.preferences')"
            >
                P
            </span>
        </div>
    </header>

    <!-- Mobile search bar (below the top bar on small screens) -->
    <div class="relative mx-2 mt-2 mb-1 inline-flex w-[calc(100%-1rem)] items-center md:hidden">
        <input
            v-model="searchText"
            class="h-10 w-full rounded-full border border-yt-border bg-yt-bg px-4 text-yt-text focus:border-blue-500 focus:outline-none dark:bg-dark-900"
            type="text"
            role="search"
            :title="$t('actions.search')"
            :placeholder="$t('actions.search')"
            @keyup="onKeyUp"
            @keypress="onKeyPress"
            @focus="onInputFocus"
            @blur="onInputBlur"
        />
        <ClearButton v-if="searchText" @clear="searchText = ''" />
    </div>

    <!-- Mobile slide-down nav -->
    <nav v-if="showMobileNav" class="mb-2 flex flex-col border-y border-yt-border bg-yt-bg md:hidden">
        <router-link to="/" class="flex items-center gap-3 px-4 py-3 hover:bg-yt-surface">
            <i-fa6-solid-house /> Home
        </router-link>
        <router-link to="/shorts" class="flex items-center gap-3 px-4 py-3 hover:bg-yt-surface">
            <i-fa6-solid-bolt /> Shorts
        </router-link>
        <router-link to="/feed" class="flex items-center gap-3 px-4 py-3 hover:bg-yt-surface">
            <i-fa6-solid-rectangle-list /> Subscriptions
        </router-link>
        <router-link to="/trending" class="flex items-center gap-3 px-4 py-3 hover:bg-yt-surface">
            <i-fa6-solid-fire /> Trending
        </router-link>
        <router-link
            v-if="shouldShowHistory"
            to="/history"
            class="flex items-center gap-3 px-4 py-3 hover:bg-yt-surface"
        >
            <i-fa6-solid-clock-rotate-left /> History
        </router-link>
        <router-link to="/playlists" class="flex items-center gap-3 px-4 py-3 hover:bg-yt-surface">
            <i-fa6-solid-list /> Playlists
        </router-link>
        <router-link v-if="shouldShowLogin" to="/login" class="flex items-center gap-3 px-4 py-3 hover:bg-yt-surface">
            <i-fa6-solid-user /> Sign in
        </router-link>
        <router-link
            v-if="shouldShowRegister"
            to="/register"
            class="flex items-center gap-3 px-4 py-3 hover:bg-yt-surface"
        >
            <i-fa6-solid-user-plus /> Register
        </router-link>
        <router-link to="/preferences" class="flex items-center gap-3 px-4 py-3 hover:bg-yt-surface">
            <i-fa6-solid-gear /> Settings
        </router-link>
    </nav>

    <SearchSuggestions
        v-show="(searchText || showSearchHistory) && suggestionsVisible"
        ref="searchSuggestions"
        :search-text="searchText"
        @searchchange="onSearchTextChange"
    />
</template>

<script setup>
import { ref, computed, watch, onMounted } from "vue";
import { useRouter, useRoute } from "vue-router";
import SearchSuggestions from "./SearchSuggestions.vue";
import ClearButton from "./ui/ClearButton.vue";
import hotkeys from "hotkeys-js";
import { fetchJson, authApiUrl, getAuthToken } from "@/composables/useApi.js";
import { getPreferenceBoolean } from "@/composables/usePreferences.js";

defineEmits(["toggle-sidebar"]);

const router = useRouter();
const route = useRoute();

const videoSearch = ref(null);
const searchSuggestions = ref(null);

const searchText = ref("");
const suggestionsVisible = ref(false);
const showMobileNav = ref(false);
const registrationDisabled = ref(false);

const shouldShowLogin = computed(() => getAuthToken() == null);
const shouldShowRegister = computed(() => (registrationDisabled.value ? false : shouldShowLogin.value));
const shouldShowHistory = computed(() => getPreferenceBoolean("watchHistory", false));
const showSearchHistory = computed(
    () => getPreferenceBoolean("searchHistory", false) && localStorage.getItem("search_history"),
);

watch(
    () => route.fullPath,
    () => {
        updateSearchTextFromURLSearchParams();
        showMobileNav.value = false;
    },
);

function updateSearchTextFromURLSearchParams() {
    const query = new URLSearchParams(window.location.search).get("search_query");
    if (query) onSearchTextChange(query);
}

function focusOnSearchBar() {
    hotkeys("ctrl+k", event => {
        event.preventDefault();
        videoSearch.value?.focus();
    });
}

function onKeyUp(e) {
    if (e.key === "ArrowUp" || e.key === "ArrowDown") e.preventDefault();
    searchSuggestions.value?.onKeyUp(e);
}

function onKeyPress(e) {
    if (e.key === "Enter") submitSearch(e);
}

function onInputFocus() {
    if (showSearchHistory.value) searchSuggestions.value?.refreshSuggestions();
    suggestionsVisible.value = true;
}

function onInputBlur() {
    setTimeout(() => (suggestionsVisible.value = false), 200);
}

function onSearchTextChange(text) {
    searchText.value = text;
}

function fetchAuthConfig() {
    fetchJson(authApiUrl() + "/config").then(config => {
        registrationDisabled.value = config?.registrationDisabled === true;
    });
}

function onSearchClick(e) {
    submitSearch(e);
}

function submitSearch(e) {
    e.target.blur();
    if (searchText.value) {
        router.push({ name: "SearchResults", query: { search_query: searchText.value } });
    } else {
        router.push("/");
    }
}

onMounted(() => {
    fetchAuthConfig();
    updateSearchTextFromURLSearchParams();
    focusOnSearchBar();
});
</script>
