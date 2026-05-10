<template>
    <div class="pt-3 pb-2">
        <p class="text-xs text-yt-text-secondary">Search results for</p>
        <h1 class="text-2xl font-bold text-yt-text" v-text="$route.query.search_query" />
    </div>

    <!-- Filter chips -->
    <nav class="sticky top-(--topbar-h) z-20 -mx-1 scrollbar-hidden flex gap-2 overflow-x-auto bg-yt-bg px-1 py-3">
        <button
            v-for="filter in availableFilters"
            :key="filter"
            v-t="`search.${filter}`"
            class="shrink-0 rounded-lg border px-3 py-1.5 text-sm font-medium transition-colors"
            :class="
                selectedFilter === filter
                    ? 'border-transparent bg-yt-text text-yt-bg'
                    : 'border-yt-border bg-yt-surface text-yt-text hover:bg-yt-surface-hover'
            "
            @click="
                selectedFilter = filter;
                updateFilter();
            "
        />
    </nav>

    <div v-if="results && results.corrected" class="mb-2 text-base text-yt-text-secondary">
        <i18n-t keypath="search.did_you_mean" tag="div">
            <router-link
                :to="{ name: 'SearchResults', query: { search_query: results.suggestion } }"
                class="text-yt-text underline"
            >
                <em v-text="results.suggestion" />
            </router-link>
        </i18n-t>
    </div>

    <LoadingIndicatorPage
        :show-content="Boolean(results != null && results.items?.length)"
        class="grid grid-cols-1 gap-x-4 gap-y-10 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5"
    >
        <template v-for="result in results.items" :key="result.url">
            <ContentItem :item="result" height="94" width="168" />
        </template>
    </LoadingIndicatorPage>
</template>

<script setup>
import { ref, onMounted, onUpdated, onActivated, onDeactivated, onUnmounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import ContentItem from "./ContentItem.vue";
import LoadingIndicatorPage from "./LoadingIndicatorPage.vue";
import { fetchJson, apiUrl } from "@/composables/useApi.js";
import { getPreferenceBoolean } from "@/composables/usePreferences.js";
import { updateWatched } from "@/composables/useMisc.js";

const route = useRoute();
const router = useRouter();

const results = ref(null);
const availableFilters = [
    "all",
    "videos",
    "channels",
    "playlists",
    "music_songs",
    "music_videos",
    "music_albums",
    "music_playlists",
    "music_artists",
];
const selectedFilter = ref(route.query.filter ?? "all");
let loading = false;

async function fetchResultsData() {
    return await fetchJson(apiUrl() + "/search", {
        q: route.query.search_query,
        filter: route.query.filter ?? "all",
    });
}

async function updateResults() {
    document.title = route.query.search_query + " - Piped";
    fetchResultsData().then(json => {
        results.value = json;
        updateWatched(results.value.items);
    });
}

function updateFilter() {
    router.replace({
        query: {
            search_query: route.query.search_query,
            filter: selectedFilter.value,
        },
    });
}

function handleScroll() {
    if (loading || !results.value || !results.value.nextpage) return;
    if (window.innerHeight + window.scrollY >= document.body.offsetHeight - window.innerHeight) {
        loading = true;
        fetchJson(apiUrl() + "/nextpage/search", {
            nextpage: results.value.nextpage,
            q: route.query.search_query,
            filter: route.query.filter ?? "all",
        }).then(json => {
            results.value.nextpage = json.nextpage;
            results.value.id = json.id;
            loading = false;
            json.items.map(stream => results.value.items.push(stream));
        });
    }
}

function handleRedirect() {
    const query = route.query.search_query;
    const url =
        /(?:http(?:s)?:\/\/)?(?:www\.)?youtube\.com(\/[/a-zA-Z0-9_?=&-]*)/gm.exec(query)?.[1] ??
        /(?:http(?:s)?:\/\/)?(?:www\.)?youtu\.be\/(?:watch\?v=)?([/a-zA-Z0-9_?=&-]*)/gm
            .exec(query)?.[1]
            .replace(/^/, "/watch?v=");
    if (url) {
        router.push(url);
        return true;
    }
}

function saveQueryToHistory() {
    if (!getPreferenceBoolean("searchHistory", false)) return;
    const query = route.query.search_query;
    if (!query) return;
    const searchHistory = JSON.parse(localStorage.getItem("search_history")) ?? [];
    if (searchHistory.includes(query)) {
        const index = searchHistory.indexOf(query);
        searchHistory.splice(index, 1);
    }
    searchHistory.unshift(query);
    if (searchHistory.length > 10) searchHistory.shift();
    localStorage.setItem("search_history", JSON.stringify(searchHistory));
}

onMounted(() => {
    if (handleRedirect()) return;
    updateResults();
    saveQueryToHistory();
});

onUpdated(() => {
    if (route.query.search_query !== undefined) {
        document.title = route.query.search_query + " - Piped";
    }
});

onActivated(() => {
    handleRedirect();
    window.addEventListener("scroll", handleScroll);
});

onDeactivated(() => {
    window.removeEventListener("scroll", handleScroll);
});

onUnmounted(() => {
    window.removeEventListener("scroll", handleScroll);
});
</script>
