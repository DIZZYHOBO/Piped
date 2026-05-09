<template>
    <div v-if="showVideo" class="flex flex-col">
        <router-link
            class="block"
            :to="{
                path: '/watch',
                query: {
                    v: item.url.substr(-11),
                    ...(playlistId && { list: playlistId }),
                    ...(index >= 0 && { index: index + 1 }),
                    ...(preferListen && { listen: 1 }),
                },
            }"
        >
            <VideoThumbnail :item="item" class="overflow-hidden rounded-xl" />
        </router-link>

        <div class="mt-3 flex gap-3">
            <router-link v-if="item.uploaderUrl" :to="item.uploaderUrl" class="shrink-0">
                <img
                    v-if="item.uploaderAvatar"
                    loading="lazy"
                    :src="item.uploaderAvatar"
                    class="size-9 rounded-full"
                    width="36"
                    height="36"
                />
            </router-link>

            <div class="min-w-0 flex-1">
                <router-link
                    :to="{
                        path: '/watch',
                        query: {
                            v: item.url.substr(-11),
                            ...(playlistId && { list: playlistId }),
                            ...(index >= 0 && { index: index + 1 }),
                            ...(preferListen && { listen: 1 }),
                        },
                    }"
                >
                    <p class="line-clamp-2 text-sm/snug font-medium text-yt-text" :title="title" v-text="title" />
                </router-link>

                <router-link
                    v-if="item.uploaderUrl && item.uploaderName && !hideChannel"
                    class="mt-1.5 inline-flex max-w-full items-center gap-1 text-xs text-yt-text-secondary hover:text-yt-text"
                    :to="item.uploaderUrl"
                    :title="item.uploaderName"
                >
                    <span class="truncate" v-text="item.uploaderName" />
                    <i-fa6-solid-check v-if="item.uploaderVerified" class="shrink-0" />
                </router-link>

                <div v-if="item.views >= 0 || item.uploadedDate" class="text-xs text-yt-text-secondary">
                    <span v-if="item.views >= 0" v-text="`${numberFormat(item.views)} views`" />
                    <span v-if="item.views >= 0 && (item.uploaded > 0 || item.uploadedDate)" class="px-1">·</span>
                    <span
                        v-if="item.uploaded > 0"
                        :title="new Date(item.uploaded).toLocaleString()"
                        v-text="timeAgo(item.uploaded)"
                    />
                    <span v-else-if="item.uploadedDate" v-text="item.uploadedDate" />
                </div>
            </div>

            <div class="flex shrink-0 items-start">
                <button
                    class="grid size-8 place-items-center rounded-full text-yt-text-secondary hover:bg-yt-surface hover:text-yt-text"
                    :title="$t('actions.share')"
                    @click="showActions = !showActions"
                >
                    <i-fa6-solid-ellipsis-vertical />
                </button>
            </div>
        </div>

        <!-- Inline action row (revealed on demand) -->
        <div
            v-if="showActions"
            class="mt-2 flex flex-wrap items-center gap-1 border-t border-yt-border pt-2 text-yt-text-secondary"
        >
            <router-link
                :to="{
                    path: '/watch',
                    query: {
                        v: item.url.substr(-11),
                        ...(playlistId && { list: playlistId }),
                        ...(index >= 0 && { index: index + 1 }),
                        ...(!preferListen && { listen: 1 }),
                    },
                }"
                class="grid size-8 place-items-center rounded-full hover:bg-yt-surface hover:text-yt-text"
                :aria-label="preferListen ? title : 'Listen to ' + title"
                :title="preferListen ? title : 'Listen to ' + title"
            >
                <i-fa6-solid-tv v-if="preferListen" />
                <i-fa6-solid-headphones v-else />
            </router-link>
            <button
                class="grid size-8 place-items-center rounded-full hover:bg-yt-surface hover:text-yt-text"
                :title="$t('actions.add_to_playlist')"
                @click="showPlaylistModal = !showPlaylistModal"
            >
                <i-fa6-solid-circle-plus />
            </button>
            <button
                class="grid size-8 place-items-center rounded-full hover:bg-yt-surface hover:text-yt-text"
                :title="$t('actions.share')"
                @click="showShareModal = !showShareModal"
            >
                <i-fa6-solid-share />
            </button>
            <button
                v-if="admin"
                ref="removeButton"
                class="grid size-8 place-items-center rounded-full hover:bg-yt-surface hover:text-yt-text"
                :title="$t('actions.remove_from_playlist')"
                @click="showConfirmRemove = true"
            >
                <i-fa6-solid-circle-minus />
            </button>
            <button
                v-if="showMarkOnWatched && isFeed"
                ref="watchButton"
                class="grid size-8 place-items-center rounded-full hover:bg-yt-surface hover:text-yt-text"
                @click="toggleWatched(item.url.substr(-11))"
            >
                <i-fa6-solid-eye-slash
                    v-if="item.watched && item.currentTime > item.duration * 0.9"
                    :title="$t('actions.mark_as_unwatched')"
                />
                <i-fa6-solid-eye v-else :title="$t('actions.mark_as_watched')" />
            </button>
        </div>

        <ConfirmModal
            v-if="showConfirmRemove"
            :message="$t('actions.delete_playlist_video_confirm')"
            @close="showConfirmRemove = false"
            @confirm="removeVideo(item.url.substr(-11))"
        />
        <PlaylistAddModal
            v-if="showPlaylistModal"
            :video-id="item.url.substr(-11)"
            :video-info="item"
            @close="showPlaylistModal = false"
        />
        <ShareModal
            v-if="showShareModal"
            :video-id="item.url.substr(-11)"
            :current-time="0"
            @close="showShareModal = false"
        />
    </div>
</template>

<script setup>
import { ref, computed, onMounted } from "vue";
import PlaylistAddModal from "./PlaylistAddModal.vue";
import ShareModal from "./ShareModal.vue";
import ConfirmModal from "./ConfirmModal.vue";
import VideoThumbnail from "./VideoThumbnail.vue";
import { numberFormat, timeAgo } from "@/composables/useFormatting.js";
import { getPreferenceBoolean } from "@/composables/usePreferences.js";
import { removeVideoFromPlaylist } from "@/composables/usePlaylists.js";

const props = defineProps({
    item: {
        type: Object,
        default: () => {
            return {};
        },
    },
    isFeed: {
        type: Boolean,
        default: false,
    },
    height: { type: String, default: "118" },
    width: { type: String, default: "210" },
    hideChannel: { type: Boolean, default: false },
    index: { type: Number, default: -1 },
    playlistId: { type: String, default: null },
    preferListen: { type: Boolean, default: false },
    admin: { type: Boolean, default: false },
});

const emit = defineEmits(["update:watched", "remove"]);

const removeButton = ref(null);
const showPlaylistModal = ref(false);
const showShareModal = ref(false);
const showVideo = ref(true);
const showConfirmRemove = ref(false);
const showMarkOnWatched = ref(false);
const showActions = ref(false);

const title = computed(() => {
    return props.item.dearrow?.titles[0]?.title ?? props.item.title;
});

function removeVideo() {
    removeButton.value.disabled = true;
    removeVideoFromPlaylist(props.playlistId, props.index).then(json => {
        if (json.error) alert(json.error);
        else emit("remove");
    });
}

function shouldShowVideo() {
    if (!props.isFeed || !getPreferenceBoolean("hideWatched", false)) return;

    const objectStore = window.db.transaction("watch_history", "readonly").objectStore("watch_history");
    const request = objectStore.get(props.item.url.substr(-11));
    request.onsuccess = event => {
        const video = event.target.result;
        if (video && (video.currentTime ?? 0) > video.duration * 0.9) {
            showVideo.value = false;
            return;
        }
    };
}

function shouldShowMarkOnWatched() {
    showMarkOnWatched.value = getPreferenceBoolean("watchHistory", false);
}

function toggleWatched(videoId) {
    if (window.db) {
        var tx = window.db.transaction("watch_history", "readwrite");
        var store = tx.objectStore("watch_history");
        var request = store.get(videoId);
        request.onsuccess = function (event) {
            var video = event.target.result;
            if (video) {
                video.watchedAt = Date.now();
            } else {
                video = {
                    videoId: videoId,
                    title: props.item.title,
                    duration: props.item.duration,
                    thumbnail: props.item.thumbnail,
                    uploaderUrl: props.item.uploaderUrl,
                    uploaderName: props.item.uploaderName,
                    watchedAt: Date.now(),
                };
            }
            video.currentTime = props.item.currentTime < props.item.duration * 0.9 ? props.item.duration : 0;
            store.put(video);
            emit("update:watched", [props.item.url]);
            shouldShowVideo();
        };
    }
}

onMounted(() => {
    shouldShowVideo();
    shouldShowMarkOnWatched();
});
</script>
