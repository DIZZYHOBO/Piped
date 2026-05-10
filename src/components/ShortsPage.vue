<template>
    <div class="flex items-center gap-3 pt-3 pb-2">
        <span class="grid size-7 place-items-center rounded-md bg-linear-to-b from-[#ff4438] to-[#cc1d1d] text-white">
            <i-fa6-solid-bolt class="text-sm" />
        </span>
        <h1 class="text-2xl font-bold text-yt-text">Shorts</h1>
        <span v-if="shorts.length" class="text-sm text-yt-text-secondary" v-text="`${shorts.length} clips`" />
    </div>

    <nav class="sticky top-(--topbar-h) z-20 -mx-1 scrollbar-hidden flex gap-2 overflow-x-auto bg-yt-bg px-1 py-3">
        <button
            v-for="region in regions"
            :key="region.code"
            class="shrink-0 rounded-lg border px-3 py-1.5 text-sm font-medium transition-colors"
            :class="
                selectedRegion === region.code
                    ? 'border-transparent bg-yt-text text-yt-bg'
                    : 'border-yt-border bg-yt-surface text-yt-text hover:bg-yt-surface-hover'
            "
            @click="
                selectedRegion = region.code;
                refresh();
            "
            v-text="region.label"
        />
    </nav>

    <LoadingIndicatorPage
        :show-content="hasLoaded"
        class="grid grid-cols-2 gap-x-3 gap-y-8 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6"
    >
        <article v-for="(short, idx) in shorts" :key="short.url" class="group flex flex-col">
            <button
                type="button"
                class="relative block cursor-pointer overflow-hidden rounded-xl bg-yt-surface text-left"
                @click="openPlayer(idx)"
            >
                <img loading="lazy" class="aspect-9/16 w-full object-cover" :src="short.thumbnail" :alt="short.title" />
                <span
                    class="absolute inset-0 grid place-items-center bg-black/0 text-3xl text-white opacity-0 transition group-hover:bg-black/30 group-hover:opacity-100"
                >
                    <i-fa6-solid-play />
                </span>
                <span
                    v-if="short.views >= 0"
                    class="absolute bottom-2 left-2 rounded-md bg-black/85 px-2 py-1 text-xs font-medium text-white"
                    v-text="`${numberFormat(short.views)} views`"
                />
            </button>
            <h3
                class="mt-2 line-clamp-2 text-sm/snug font-medium text-yt-text"
                :title="short.title"
                v-text="short.title"
            />
            <router-link
                v-if="short.uploaderUrl && short.uploaderName"
                :to="short.uploaderUrl"
                class="mt-1 line-clamp-1 text-xs text-yt-text-secondary hover:text-yt-text"
            >
                {{ short.uploaderName }}
            </router-link>
        </article>

        <p
            v-if="hasLoaded && shorts.length === 0"
            class="col-span-full mt-12 text-center text-sm text-yt-text-secondary"
        >
            No shorts available for this region right now. Try another.
        </p>
    </LoadingIndicatorPage>

    <ShortsPlayer
        v-if="playerIndex !== null"
        :shorts="shorts"
        :initial-index="playerIndex"
        @close="playerIndex = null"
    />
</template>

<script setup>
import { ref, onMounted, onActivated } from "vue";
import LoadingIndicatorPage from "./LoadingIndicatorPage.vue";
import ShortsPlayer from "./ShortsPlayer.vue";
import { fetchJson, apiUrl } from "@/composables/useApi.js";
import { getPreferenceString } from "@/composables/usePreferences.js";
import { numberFormat } from "@/composables/useFormatting.js";
import { updateWatched } from "@/composables/useMisc.js";
import { fetchDeArrowContent } from "@/composables/useSubscriptions.js";

const shorts = ref([]);
const hasLoaded = ref(false);
const playerIndex = ref(null);
const selectedRegion = ref(getPreferenceString("region", "US"));

function openPlayer(idx) {
    playerIndex.value = idx;
}

const regions = [
    { code: "US", label: "United States" },
    { code: "GB", label: "United Kingdom" },
    { code: "CA", label: "Canada" },
    { code: "DE", label: "Germany" },
    { code: "FR", label: "France" },
    { code: "JP", label: "Japan" },
    { code: "BR", label: "Brazil" },
    { code: "IN", label: "India" },
];

async function refresh() {
    hasLoaded.value = false;
    const vids = await fetchJson(apiUrl() + "/trending", { region: selectedRegion.value });
    if (Array.isArray(vids)) {
        shorts.value = vids.filter(v => v?.isShort);
        updateWatched(shorts.value);
        fetchDeArrowContent(shorts.value);
    } else {
        shorts.value = [];
    }
    hasLoaded.value = true;
}

onMounted(refresh);

onActivated(() => {
    document.title = "Shorts - Piped";
});
</script>
