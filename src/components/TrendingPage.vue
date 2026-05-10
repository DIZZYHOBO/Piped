<template>
    <div class="flex items-center gap-3 pt-3 pb-2">
        <i-fa6-solid-fire class="text-2xl text-yt-brand-red" />
        <h1 v-t="'titles.trending'" class="text-2xl font-bold text-yt-text" />
    </div>

    <nav class="sticky top-(--topbar-h) z-20 -mx-1 scrollbar-hidden flex gap-2 overflow-x-auto bg-yt-bg px-1 py-3">
        <button class="shrink-0 rounded-lg bg-yt-text px-3 py-1.5 text-sm font-medium text-yt-bg">All</button>
        <button
            class="shrink-0 rounded-lg border border-yt-border bg-yt-surface px-3 py-1.5 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
        >
            Music
        </button>
        <button
            class="shrink-0 rounded-lg border border-yt-border bg-yt-surface px-3 py-1.5 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
        >
            Gaming
        </button>
        <button
            class="shrink-0 rounded-lg border border-yt-border bg-yt-surface px-3 py-1.5 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
        >
            News
        </button>
        <button
            class="shrink-0 rounded-lg border border-yt-border bg-yt-surface px-3 py-1.5 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
        >
            Live
        </button>
    </nav>

    <LoadingIndicatorPage
        :show-content="videos.length != 0"
        class="grid grid-cols-1 gap-x-4 gap-y-10 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5"
    >
        <VideoItem v-for="video in videos" :key="video.url" :item="video" height="118" width="210" />
    </LoadingIndicatorPage>
</template>

<script setup>
import { ref, onMounted, onActivated } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useI18n } from "vue-i18n";
import LoadingIndicatorPage from "./LoadingIndicatorPage.vue";
import VideoItem from "./VideoItem.vue";
import { fetchJson, apiUrl } from "@/composables/useApi.js";
import { getPreferenceString } from "@/composables/usePreferences.js";
import { updateWatched, filterHiddenStreams } from "@/composables/useMisc.js";
import { fetchDeArrowContent } from "@/composables/useSubscriptions.js";
import { getHomePage } from "@/composables/useMisc.js";

const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const videos = ref([]);

async function fetchTrending(region) {
    return await fetchJson(apiUrl() + "/trending", {
        region: region || "US",
    });
}

onMounted(() => {
    if (route.path == import.meta.env.BASE_URL && getPreferenceString("homepage", "trending") == "feed") {
        return;
    }
    let region = getPreferenceString("region", "US");

    fetchTrending(region).then(vids => {
        videos.value = filterHiddenStreams(vids);
        updateWatched(videos.value);
        fetchDeArrowContent(videos.value);
    });
});

onActivated(() => {
    document.title = t("titles.trending") + " - Piped";
    if (videos.value.length > 0) updateWatched(videos.value);
    if (route.path == import.meta.env.BASE_URL) {
        let homepage = getHomePage();
        if (homepage !== undefined) router.push(homepage);
    }
});
</script>
