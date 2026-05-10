<template>
    <div class="flex items-center gap-3 pt-3 pb-2">
        <h1 v-t="'titles.feed'" class="text-2xl font-bold text-yt-text" />
        <span class="ml-auto flex items-center gap-2">
            <router-link
                to="/subscriptions"
                class="inline-flex h-9 items-center gap-1.5 rounded-full bg-yt-surface px-3 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
            >
                <i-fa6-solid-users />
                <span v-t="'titles.subscriptions'" />
            </router-link>
            <a
                :href="getRssUrl"
                class="inline-flex size-9 items-center justify-center rounded-full bg-yt-surface text-yt-text hover:bg-yt-surface-hover"
                :aria-label="$t('actions.rss_feed')"
            >
                <i-fa6-solid-rss />
            </a>
            <SortingSelector by-key="uploaded" @apply="order => videos.sort(order)" />
        </span>
    </div>

    <!-- Filter chips: type filter + channel groups -->
    <nav class="sticky top-(--topbar-h) z-20 -mx-1 scrollbar-hidden flex gap-2 overflow-x-auto bg-yt-bg px-1 py-3">
        <button
            v-for="filter in availableFilters"
            :key="filter"
            v-t="`video.${filter}`"
            class="shrink-0 rounded-lg border px-3 py-1.5 text-sm font-medium transition-colors"
            :class="
                selectedFilter === filter
                    ? 'border-transparent bg-yt-text text-yt-bg'
                    : 'border-yt-border bg-yt-surface text-yt-text hover:bg-yt-surface-hover'
            "
            @click="
                selectedFilter = filter;
                onFilterChange();
            "
        />
        <span v-if="channelGroups.length" class="mx-1 self-center text-yt-text-secondary">·</span>
        <button
            class="shrink-0 rounded-lg border px-3 py-1.5 text-sm font-medium transition-colors"
            :class="
                selectedGroupName === ''
                    ? 'border-transparent bg-yt-text text-yt-bg'
                    : 'border-yt-border bg-yt-surface text-yt-text hover:bg-yt-surface-hover'
            "
            @click="selectedGroupName = ''"
        >
            <span v-t="'video.all'" />
        </button>
        <button
            v-for="group in channelGroups"
            :key="group.groupName"
            class="shrink-0 rounded-lg border px-3 py-1.5 text-sm font-medium transition-colors"
            :class="
                selectedGroupName === group.groupName
                    ? 'border-transparent bg-yt-text text-yt-bg'
                    : 'border-yt-border bg-yt-surface text-yt-text hover:bg-yt-surface-hover'
            "
            @click="selectedGroupName = group.groupName"
            v-text="group.groupName"
        />
    </nav>

    <LoadingIndicatorPage
        :show-content="videosStore != null"
        class="grid grid-cols-1 gap-x-4 gap-y-10 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5"
    >
        <template v-for="video in filteredVideos" :key="video.url">
            <VideoItem v-if="shouldShowVideo(video)" :is-feed="true" :item="video" @update:watched="onUpdateWatched" />
        </template>
    </LoadingIndicatorPage>
</template>

<script setup>
import { ref, computed, onMounted, onActivated, onDeactivated, onUnmounted } from "vue";
import { useI18n } from "vue-i18n";
import VideoItem from "./VideoItem.vue";
import SortingSelector from "./SortingSelector.vue";
import LoadingIndicatorPage from "./LoadingIndicatorPage.vue";
import { authApiUrl, getAuthToken, isAuthenticated } from "@/composables/useApi.js";
import { getPreferenceBoolean, getPreferenceString, setPreference } from "@/composables/usePreferences.js";
import { fetchFeed, getUnauthenticatedChannels, fetchDeArrowContent } from "@/composables/useSubscriptions.js";
import { getChannelGroups } from "@/composables/useChannelGroups.js";
import { updateWatched, isLiveStream, hideLiveEnabled } from "@/composables/useMisc.js";

const { t } = useI18n();

let currentVideoCount = 0;
const videoStep = 100;
const videosStore = ref(null);
const videos = ref([]);
const availableFilters = ["all", "shorts", "videos"];
const selectedFilter = ref("all");
const selectedGroupName = ref("");
const channelGroups = ref([]);

const getRssUrl = computed(() => {
    if (isAuthenticated()) return authApiUrl() + "/feed/rss?authToken=" + getAuthToken();
    else return authApiUrl() + "/feed/unauthenticated/rss?channels=" + getUnauthenticatedChannels();
});

const filteredVideos = computed(() => {
    const selectedGroup = channelGroups.value.filter(group => group.groupName == selectedGroupName.value);

    let vids = videos.value;
    if (getPreferenceBoolean("hideWatched", false)) vids = vids.filter(video => !video.watched);
    if (hideLiveEnabled()) vids = vids.filter(video => !isLiveStream(video));

    return selectedGroupName.value == ""
        ? vids
        : vids.filter(video => selectedGroup[0].channels.includes(video.uploaderUrl.substr(-24)));
});

function loadMoreVideos() {
    if (!videosStore.value) return;
    currentVideoCount = Math.min(currentVideoCount + videoStep, videosStore.value.length);
    if (videos.value.length != videosStore.value.length) {
        fetchDeArrowContent(videosStore.value.slice(videos.value.length, currentVideoCount));
        videos.value = videosStore.value.slice(0, currentVideoCount);
    }
}

function handleScroll() {
    if (window.innerHeight + window.scrollY >= document.body.offsetHeight - window.innerHeight) {
        loadMoreVideos();
    }
}

function onUpdateWatched(urls = null) {
    if (urls === null) {
        if (videos.value.length > 0) updateWatched(videos.value);
        return;
    }

    const subset = videos.value.filter(({ url }) => urls.includes(url));
    if (subset.length > 0) updateWatched(subset);
}

function shouldShowVideo(video) {
    switch (selectedFilter.value.toLowerCase()) {
        case "shorts":
            return video.isShort;
        case "videos":
            return !video.isShort;
        default:
            return true;
    }
}

function onFilterChange() {
    setPreference("feedFilter", selectedFilter.value);
}

onMounted(() => {
    fetchFeed().then(resp => {
        if (resp.error) {
            alert(resp.error);
            return;
        }

        videosStore.value = resp;
        loadMoreVideos();
        updateWatched(videos.value);
    });

    selectedFilter.value = getPreferenceString("feedFilter") ?? "all";

    if (!window.db) return;

    (async () => {
        const groups = await getChannelGroups();
        channelGroups.value.push(...groups);
    })();
});

onActivated(() => {
    document.title = t("titles.feed") + " - Piped";
    if (videos.value.length > 0) updateWatched(videos.value);
    window.addEventListener("scroll", handleScroll);
});

onDeactivated(() => {
    window.removeEventListener("scroll", handleScroll);
});

onUnmounted(() => {
    window.removeEventListener("scroll", handleScroll);
});
</script>
