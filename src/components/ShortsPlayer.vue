<template>
    <div
        ref="root"
        class="fixed inset-0 z-50 flex flex-col bg-black text-white"
        tabindex="-1"
        @keydown.esc="$emit('close')"
    >
        <!-- Top bar -->
        <header
            class="pointer-events-none absolute inset-x-0 top-0 z-30 flex items-center justify-between bg-linear-to-b from-black/70 to-transparent p-3"
        >
            <div class="pointer-events-auto flex items-center gap-2">
                <button
                    type="button"
                    class="grid size-10 place-items-center rounded-full bg-black/50 hover:bg-black/70"
                    aria-label="Close shorts"
                    @click="$emit('close')"
                >
                    <i-fa6-solid-xmark />
                </button>
                <span class="font-semibold tracking-tight">Shorts</span>
            </div>
            <button
                type="button"
                class="pointer-events-auto grid size-10 place-items-center rounded-full bg-black/50 hover:bg-black/70"
                :aria-label="muted ? 'Unmute' : 'Mute'"
                @click="toggleMute"
            >
                <i-fa6-solid-volume-xmark v-if="muted" />
                <i-fa6-solid-volume-high v-else />
            </button>
        </header>

        <!-- Swipe container -->
        <div
            ref="scroller"
            class="scrollbar-hidden h-full snap-y snap-mandatory overflow-y-scroll"
            @scroll.passive="onScroll"
        >
            <section
                v-for="(short, idx) in shorts"
                :key="short.url"
                :ref="el => (slideEls[idx] = el)"
                :data-index="idx"
                class="relative h-dvh w-full snap-start snap-always"
            >
                <!-- Backdrop poster while loading -->
                <img
                    v-if="!streamUrls[idx]"
                    :src="short.thumbnail"
                    class="absolute inset-0 size-full object-contain blur-sm brightness-50"
                />

                <!-- Video -->
                <video
                    v-if="streamUrls[idx]"
                    :ref="el => (videoEls[idx] = el)"
                    :src="streamUrls[idx]"
                    class="absolute inset-0 size-full object-contain"
                    :muted="muted"
                    loop
                    playsinline
                    @click="togglePlay(idx)"
                    @loadeddata="onVideoReady(idx)"
                />

                <!-- Loading spinner -->
                <div v-if="!streamUrls[idx]" class="absolute inset-0 grid place-items-center">
                    <span class="animate-spin text-3xl"><i-fa6-solid-circle-notch /></span>
                </div>

                <!-- Bottom-left meta -->
                <div class="pointer-events-none absolute inset-x-0 bottom-0 z-20 px-4 pt-16 pb-8">
                    <div class="pointer-events-auto flex items-center gap-3">
                        <router-link v-if="short.uploaderUrl" :to="short.uploaderUrl" class="flex items-center gap-2">
                            <img v-if="short.uploaderAvatar" :src="short.uploaderAvatar" class="size-8 rounded-full" />
                            <span class="text-sm font-medium" v-text="short.uploaderName" />
                        </router-link>
                        <button
                            type="button"
                            class="ml-2 rounded-full bg-white px-3 py-1.5 text-xs font-semibold text-black hover:bg-white/90"
                            @click="onSubscribe(short)"
                        >
                            Subscribe
                        </button>
                    </div>
                    <p
                        class="pointer-events-auto mt-3 line-clamp-2 max-w-[80%] text-sm/snug"
                        :title="short.title"
                        v-text="short.title"
                    />
                </div>

                <!-- Right-side action rail -->
                <div class="absolute right-2 bottom-24 z-20 flex flex-col items-center gap-5">
                    <button type="button" class="flex flex-col items-center gap-1 text-white">
                        <span
                            class="grid size-12 place-items-center rounded-full bg-black/50 backdrop-blur-sm hover:bg-black/70"
                        >
                            <i-fa6-solid-thumbs-up class="text-lg" />
                        </span>
                        <span class="text-[11px] leading-none font-medium drop-shadow-sm">{{
                            short.likes >= 0 ? compactNumber(short.likes) : "Like"
                        }}</span>
                    </button>
                    <button type="button" class="flex flex-col items-center gap-1 text-white">
                        <span
                            class="grid size-12 place-items-center rounded-full bg-black/50 backdrop-blur-sm hover:bg-black/70"
                        >
                            <i-fa6-solid-thumbs-down class="text-lg" />
                        </span>
                        <span class="text-[11px] leading-none font-medium drop-shadow-sm">Dislike</span>
                    </button>
                    <button
                        type="button"
                        class="flex flex-col items-center gap-1 text-white"
                        @click="openComments(idx)"
                    >
                        <span
                            class="grid size-12 place-items-center rounded-full bg-black/50 backdrop-blur-sm hover:bg-black/70"
                        >
                            <i-fa6-solid-comment class="text-lg" />
                        </span>
                        <span class="text-[11px] leading-none font-medium drop-shadow-sm">{{
                            comments[idx]?.commentCount >= 0 ? compactNumber(comments[idx].commentCount) : "Comments"
                        }}</span>
                    </button>
                    <button type="button" class="flex flex-col items-center gap-1 text-white" @click="onShare(short)">
                        <span
                            class="grid size-12 place-items-center rounded-full bg-black/50 backdrop-blur-sm hover:bg-black/70"
                        >
                            <i-fa6-solid-share class="text-lg" />
                        </span>
                        <span class="text-[11px] leading-none font-medium drop-shadow-sm">Share</span>
                    </button>
                    <button type="button" class="flex flex-col items-center gap-1 text-white" @click="openWatch(short)">
                        <span
                            class="grid size-12 place-items-center rounded-full bg-black/50 backdrop-blur-sm hover:bg-black/70"
                        >
                            <i-fa6-solid-arrow-up-right-from-square class="text-lg" />
                        </span>
                        <span class="text-[11px] leading-none font-medium drop-shadow-sm">Watch</span>
                    </button>
                </div>
            </section>

            <!-- Sentinel -->
            <div v-if="shorts.length" class="h-1" />
        </div>

        <!-- Comments modal -->
        <ModalComponent v-if="commentsOpen != null" @close="commentsOpen = null">
            <div class="max-h-[70vh] w-[min(540px,90vw)] overflow-y-auto pr-1">
                <h2 class="mb-3 text-lg font-semibold text-yt-text">Comments</h2>
                <p
                    v-if="!commentsLoaded[commentsOpen]"
                    v-t="'comment.loading'"
                    class="mt-4 text-center text-yt-text-secondary"
                />
                <p
                    v-else-if="comments[commentsOpen]?.disabled"
                    v-t="'comment.disabled'"
                    class="mt-4 text-center text-yt-text-secondary"
                />
                <CommentItem
                    v-for="comment in comments[commentsOpen]?.comments ?? []"
                    :key="comment.commentId"
                    :comment="comment"
                    :uploader="shorts[commentsOpen]?.uploaderName"
                    :uploader-avatar-url="shorts[commentsOpen]?.uploaderAvatar"
                    :video-id="shorts[commentsOpen]?.url.substr(-11)"
                />
            </div>
        </ModalComponent>

        <!-- Share modal -->
        <ShareModal v-if="shareVideoId" :video-id="shareVideoId" :current-time="0" @close="shareVideoId = null" />
    </div>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted, onBeforeUnmount, nextTick, watch } from "vue";
import { useRouter } from "vue-router";
import ModalComponent from "./ModalComponent.vue";
import ShareModal from "./ShareModal.vue";
import CommentItem from "./CommentItem.vue";
import { fetchJson, apiUrl } from "@/composables/useApi.js";
import { numberFormat } from "@/composables/useFormatting.js";

const props = defineProps({
    shorts: { type: Array, required: true },
    initialIndex: { type: Number, default: 0 },
});

defineEmits(["close"]);

const router = useRouter();

const root = ref(null);
const scroller = ref(null);
const slideEls = reactive({});
const videoEls = reactive({});

const streamUrls = reactive({});
const comments = reactive({});
const commentsLoaded = reactive({});
const commentsOpen = ref(null);
const shareVideoId = ref(null);

const muted = ref(false);
const currentIdx = ref(props.initialIndex);

let observer;

function compactNumber(n) {
    if (n == null || n < 0) return "";
    return numberFormat(n);
}

async function fetchStream(idx) {
    if (streamUrls[idx]) return;
    const short = props.shorts[idx];
    if (!short) return;
    const id = short.url.substr(-11);
    try {
        const data = await fetchJson(apiUrl() + "/streams/" + id);
        if (!data) return;
        // Prefer a muxed video stream (has audio); fall back to HLS / first videoOnly.
        const muxed =
            (data.videoStreams || []).find(s => s && !s.videoOnly && s.url) ||
            (data.videoStreams || []).find(s => s && s.url);
        const url = muxed?.url || data.hls;
        if (url) streamUrls[idx] = url;
    } catch (e) {
        console.warn("Failed to load short stream", e);
    }
}

function setActiveSlide(idx) {
    if (idx === currentIdx.value && videoEls[idx]) {
        // Ensure it's playing.
        videoEls[idx].play?.().catch(() => {});
        return;
    }
    // Pause the previous one.
    const prev = videoEls[currentIdx.value];
    if (prev && !prev.paused) prev.pause();
    currentIdx.value = idx;
    // Preload the active and the next two slides' streams.
    for (let i = idx; i <= idx + 2 && i < props.shorts.length; i++) fetchStream(i);
    // Try to play the active one (may already be ready).
    nextTick(() => {
        const v = videoEls[idx];
        if (v) v.play?.().catch(() => {});
    });
}

function onVideoReady(idx) {
    if (idx === currentIdx.value) videoEls[idx]?.play?.().catch(() => {});
}

function togglePlay(idx) {
    const v = videoEls[idx];
    if (!v) return;
    if (v.paused) v.play().catch(() => {});
    else v.pause();
}

function toggleMute() {
    muted.value = !muted.value;
}

function onScroll() {
    // Cheap fallback in case IntersectionObserver misses a fast scroll.
    if (!scroller.value) return;
    const top = scroller.value.scrollTop;
    const h = scroller.value.clientHeight || window.innerHeight;
    const idx = Math.round(top / h);
    if (idx !== currentIdx.value && props.shorts[idx]) setActiveSlide(idx);
}

async function openComments(idx) {
    commentsOpen.value = idx;
    if (commentsLoaded[idx]) return;
    const id = props.shorts[idx]?.url.substr(-11);
    if (!id) return;
    try {
        comments[idx] = await fetchJson(apiUrl() + "/comments/" + id);
    } catch (e) {
        console.warn("Failed to load comments", e);
    } finally {
        commentsLoaded[idx] = true;
    }
}

function onShare(short) {
    shareVideoId.value = short.url.substr(-11);
}

function openWatch(short) {
    router.push({ path: "/watch", query: { v: short.url.substr(-11) } });
}

function onSubscribe(short) {
    // Lightweight: just navigate to the channel; a full subscribe flow lives there.
    if (short.uploaderUrl) router.push(short.uploaderUrl);
}

function onKey(e) {
    if (e.key === "Escape") return;
    if (e.key === "ArrowDown" || e.key === "j") {
        e.preventDefault();
        scrollToIndex(currentIdx.value + 1);
    } else if (e.key === "ArrowUp" || e.key === "k") {
        e.preventDefault();
        scrollToIndex(currentIdx.value - 1);
    } else if (e.key === " " || e.key === "Spacebar") {
        e.preventDefault();
        togglePlay(currentIdx.value);
    } else if (e.key === "m") {
        e.preventDefault();
        toggleMute();
    }
}

function scrollToIndex(idx) {
    if (idx < 0 || idx >= props.shorts.length || !scroller.value) return;
    const target = slideEls[idx];
    if (target) target.scrollIntoView({ behavior: "smooth", block: "start" });
}

watch(
    () => props.initialIndex,
    n => scrollToIndex(n),
);

onMounted(() => {
    // Set initial scroll position without animation.
    nextTick(() => {
        const target = slideEls[props.initialIndex];
        if (target) target.scrollIntoView({ block: "start" });
        currentIdx.value = props.initialIndex;
        // Preload the first few streams.
        for (let i = props.initialIndex; i < props.initialIndex + 3 && i < props.shorts.length; i++) fetchStream(i);
        root.value?.focus();
    });

    observer = new IntersectionObserver(
        entries => {
            // Pick whichever entry is most visible.
            const best = entries
                .filter(e => e.isIntersecting)
                .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
            if (best) {
                const i = Number(best.target.dataset.index);
                if (!Number.isNaN(i)) setActiveSlide(i);
            }
        },
        { threshold: [0.5, 0.75, 1] },
    );
    nextTick(() => {
        Object.values(slideEls).forEach(el => el && observer.observe(el));
    });

    window.addEventListener("keydown", onKey);
});

onBeforeUnmount(() => {
    observer?.disconnect();
    Object.values(videoEls).forEach(v => v?.pause?.());
});

onUnmounted(() => {
    window.removeEventListener("keydown", onKey);
});
</script>
