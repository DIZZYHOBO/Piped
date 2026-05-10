<template>
    <div v-if="video && isEmbed" class="absolute top-0 left-0 z-50 size-full bg-black">
        <VideoPlayer
            ref="videoPlayer"
            :video="video"
            :sponsors="sponsors"
            :selected-auto-play="false"
            :selected-auto-loop="selectedAutoLoop"
            :is-embed="isEmbed"
        />
    </div>
    <div id="theaterModeSpot" class="mx-[-1vw]"></div>
    <LoadingIndicatorPage :show-content="video != null && !isEmbed" class="w-full">
        <ErrorHandler v-if="video && video.error" :message="video.message" :error="video.error" />
        <Transition>
            <ToastComponent v-if="shouldShowToast" @dismissed="dismiss">
                <i18n-t keypath="info.next_video_countdown">{{ counter }}</i18n-t>
            </ToastComponent>
        </Transition>
        <div v-show="!video.error" class="flex gap-5">
            <div class="min-w-0 flex-auto">
                <Teleport defer to="#theaterModeSpot" :disabled="!theaterMode">
                    <div class="flex flex-row">
                        <keep-alive>
                            <VideoPlayer
                                ref="videoPlayer"
                                :video="video"
                                :sponsors="sponsors"
                                :selected-auto-play="selectedAutoPlayEnabled"
                                :selected-auto-loop="selectedAutoLoop"
                                @timeupdate="onTimeUpdate"
                                @ended="onVideoEnded"
                                @navigate-next="navigateNext"
                            />
                        </keep-alive>
                        <button
                            v-if="!isMobile"
                            :class="theaterMode ? '-ml-5' : '-mr-5'"
                            class="z-10 text-white"
                            @click="
                                theaterMode = !theaterMode;
                                setPreference('theaterMode', theaterMode);
                            "
                        >
                            <div>
                                <i-fa6-solid-chevron-left v-if="theaterMode" />
                                <i-fa6-solid-chevron-right v-else />
                            </div>
                        </button>
                    </div>
                </Teleport>
                <div v-if="video && isMobile">
                    <PlaylistVideos
                        v-if="playlist"
                        :playlist-id="playlistId"
                        :playlist="playlist"
                        :selected-index="index"
                        :prefer-listen="isListening"
                    />
                    <ChaptersBar
                        v-if="video?.chapters?.length > 0 && showChapters"
                        :mobile-layout="true"
                        :chapters="video.chapters"
                        :player-position="currentTime"
                        @seek="navigate"
                    />
                </div>
                <!-- video title -->
                <h1 class="mt-3 text-xl/snug font-semibold wrap-break-word text-yt-text" v-text="video.title" />

                <!-- Channel row + action pills -->
                <div class="my-3 flex flex-wrap items-center gap-3">
                    <!-- Channel info -->
                    <div class="flex items-center gap-3">
                        <img
                            loading="lazy"
                            height="40"
                            width="40"
                            :src="video.uploaderAvatar"
                            alt=""
                            class="size-10 rounded-full"
                        />
                        <div class="flex flex-col leading-tight">
                            <router-link
                                v-if="video.uploaderUrl"
                                class="flex items-center gap-1 text-base font-medium text-yt-text hover:text-yt-text-secondary"
                                :to="video.uploaderUrl"
                            >
                                {{ video.uploader }}
                                <i-fa6-solid-check v-if="video.uploaderVerified" class="text-xs" />
                            </router-link>
                            <span
                                v-if="video.uploaderSubscriberCount >= 0"
                                class="text-xs text-yt-text-secondary"
                                v-text="`${numberFormat(video.uploaderSubscriberCount)} subscribers`"
                            />
                        </div>
                        <button
                            class="ml-3 cursor-pointer rounded-full px-4 py-2 text-sm font-medium transition-colors"
                            :class="
                                subscribed
                                    ? 'bg-yt-surface text-yt-text hover:bg-yt-surface-hover'
                                    : 'bg-yt-text text-yt-bg hover:bg-yt-text-secondary'
                            "
                            @click="subscribeHandler"
                            v-text="$t('actions.' + (subscribed ? 'unsubscribe' : 'subscribe'))"
                        />
                    </div>

                    <PlaylistAddModal
                        v-if="showModal"
                        :video-id="getVideoId()"
                        :video-info="video"
                        @close="showModal = !showModal"
                    />
                    <ShareModal
                        v-if="showShareModal"
                        :video-id="getVideoId()"
                        :current-time="currentTime"
                        :playlist-id="playlistId"
                        :playlist-index="index"
                        @close="showShareModal = !showShareModal"
                    />

                    <!-- Action pill row -->
                    <div class="ml-auto flex flex-wrap items-center gap-2">
                        <!-- Likes / dislikes as a single pill -->
                        <div
                            v-if="video.likes >= 0"
                            class="inline-flex h-9 items-stretch overflow-hidden rounded-full bg-yt-surface text-yt-text"
                        >
                            <span class="inline-flex items-center gap-1.5 px-3 hover:bg-yt-surface-hover">
                                <i-fa6-solid-thumbs-up />
                                <span v-text="addCommas(video.likes)" />
                            </span>
                            <span class="border-l border-yt-border" />
                            <span class="inline-flex items-center gap-1.5 px-3 hover:bg-yt-surface-hover">
                                <i-fa6-solid-thumbs-down />
                                <span v-text="video.dislikes >= 0 ? addCommas(video.dislikes) : '?'" />
                            </span>
                        </div>
                        <span
                            v-else
                            class="inline-flex h-9 items-center rounded-full bg-yt-surface px-3 text-sm text-yt-text-secondary"
                        >
                            <strong v-t="'video.ratings_disabled'" />
                        </span>

                        <button
                            class="inline-flex h-9 cursor-pointer items-center gap-1.5 rounded-full bg-yt-surface px-3 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
                            @click="showShareModal = !showShareModal"
                        >
                            <i-fa6-solid-share />
                            <span v-t="'actions.share'" class="max-lg:hidden" />
                        </button>
                        <button
                            class="inline-flex h-9 cursor-pointer items-center gap-1.5 rounded-full bg-yt-surface px-3 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
                            @click="showModal = !showModal"
                        >
                            <i-fa6-solid-circle-plus />
                            <span class="max-lg:hidden">{{ $t("actions.add_to_playlist") }}</span>
                        </button>
                        <button
                            class="inline-flex h-9 cursor-pointer items-center gap-1.5 rounded-full bg-yt-surface px-3 text-sm font-medium text-yt-text hover:bg-yt-surface-hover max-md:hidden"
                            @click="downloadCurrentFrame"
                        >
                            <i-fa6-solid-download />
                            <span class="max-lg:hidden">{{ $t("actions.download_frame") }}</span>
                        </button>
                        <router-link
                            :to="toggleListenUrl"
                            :aria-label="(isListening ? 'Watch ' : 'Listen to ') + video.title"
                            :title="(isListening ? 'Watch ' : 'Listen to ') + video.title"
                            class="inline-flex size-9 items-center justify-center rounded-full bg-yt-surface text-yt-text hover:bg-yt-surface-hover"
                        >
                            <i-fa6-solid-tv v-if="isListening" />
                            <i-fa6-solid-headphones v-else />
                        </router-link>
                        <a
                            v-if="video.uploaderUrl"
                            aria-label="RSS feed"
                            title="RSS feed"
                            role="button"
                            :href="`${apiUrl()}/feed/unauthenticated/rss?channels=${video.uploaderUrl.split('/')[2]}`"
                            target="_blank"
                            class="inline-flex size-9 items-center justify-center rounded-full bg-yt-surface text-yt-text hover:bg-yt-surface-hover"
                        >
                            <i-fa6-solid-rss />
                        </a>
                        <WatchOnButton :link="youtubeVideoHref" />
                        <WatchOnButton
                            v-if="video.lbryId"
                            :link="`https://odysee.com/${video.lbryId}`"
                            platform="Odysee"
                        />
                    </div>
                </div>

                <!-- Description card (views/date + collapsible body) -->
                <div class="mb-4 rounded-xl bg-yt-surface p-3 text-sm text-yt-text">
                    <div class="flex flex-wrap items-center gap-2 text-xs font-medium text-yt-text-secondary">
                        <span v-t="{ path: 'video.views', args: { views: addCommas(video.views) } }" />
                        <span :title="new Date(video.uploadDate).toLocaleString()" v-text="uploadDate" />
                        <button
                            v-t="`actions.${showDesc ? 'minimize_description' : 'show_description'}`"
                            class="ml-auto cursor-pointer text-yt-text hover:text-yt-text-secondary"
                            @click="showDesc = !showDesc"
                        />
                    </div>

                    <div
                        v-for="metaInfo in video?.metaInfo ?? []"
                        :key="metaInfo.title"
                        class="my-2 rounded-lg bg-yt-bg px-3 py-2 text-yt-text-secondary"
                    >
                        <span>{{ metaInfo.description ?? metaInfo.title }}</span>
                        <a v-for="(link, linkIndex) in metaInfo.urls" :key="linkIndex" :href="link" class="underline">{{
                            metaInfo.urlTexts[linkIndex]
                        }}</a
                        ><br />
                    </div>

                    <span
                        v-show="video?.chapters?.length > 0"
                        class="mt-2 inline-flex items-center gap-2 text-xs text-yt-text-secondary"
                    >
                        <UiCheckbox id="showChapters" v-model="showChapters" />
                        <label v-t="'actions.show_chapters'" for="showChapters" />
                    </span>

                    <template v-if="showDesc">
                        <!-- eslint-disable-next-line vue/no-v-html -->
                        <div
                            class="mt-2 text-sm/relaxed wrap-break-word text-yt-text [&_a]:underline [&_a]:brightness-75"
                            v-html="purifiedDescription"
                        />

                        <div
                            v-if="sponsors && sponsors.segments"
                            class="mt-2 text-xs text-yt-text-secondary"
                            v-text="`${$t('video.sponsor_segments')}: ${sponsors.segments.length}`"
                        />
                        <div
                            v-if="video.category"
                            class="text-xs text-yt-text-secondary"
                            v-text="`${$t('video.category')}: ${video.category}`"
                        />
                        <div
                            class="text-xs text-yt-text-secondary"
                            v-text="`${$t('video.license')}: ${video.license}`"
                        />
                        <div
                            class="text-xs text-yt-text-secondary capitalize"
                            v-text="`${$t('video.visibility')}: ${video.visibility}`"
                        />

                        <div v-if="video.tags" class="mt-2 flex flex-wrap gap-2">
                            <router-link
                                v-for="tag in video.tags"
                                :key="tag"
                                class="inline-flex h-7 items-center rounded-full bg-yt-bg px-3 text-xs text-yt-text hover:bg-yt-surface-hover"
                                :to="`/results?search_query=${encodeURIComponent(tag)}`"
                                >{{ tag }}</router-link
                            >
                        </div>
                    </template>
                </div>

                <!-- Playback options -->
                <div class="mb-4 flex flex-wrap items-center gap-4 text-sm text-yt-text-secondary">
                    <span class="inline-flex items-center gap-2">
                        <UiCheckbox id="chkAutoLoop" v-model="selectedAutoLoop" @change="onChange($event)" />
                        <label v-t="'actions.loop_this_video'" for="chkAutoLoop" />
                    </span>
                    <span class="inline-flex items-center gap-2">
                        <label v-t="'actions.auto_play_next_video'" for="chkAutoPlay" />
                        <select
                            id="chkAutoPlay"
                            v-model.number="selectedAutoPlay"
                            class="h-8 rounded-md bg-yt-surface px-2 text-yt-text"
                            @change="onChange($event)"
                        >
                            <option v-t="'actions.never'" value="0" />
                            <option v-t="'actions.playlists_only'" value="1" />
                            <option v-t="'actions.always'" value="2" />
                        </select>
                    </span>
                    <button
                        v-t="`actions.${showRecs ? 'minimize_recommendations' : 'show_recommendations'}`"
                        class="ml-auto cursor-pointer rounded-full bg-yt-surface px-3 py-1.5 text-yt-text hover:bg-yt-surface-hover"
                        @click="showRecs = !showRecs"
                    />
                </div>
                <div v-if="isMobile">
                    <div v-show="showRecs">
                        <ContentItem
                            v-for="related in video.relatedStreams"
                            :key="related.url"
                            :item="related"
                            :prefer-listen="isListening"
                            class="mb-4"
                            height="94"
                            width="168"
                        />
                    </div>
                </div>

                <!-- Comments -->
                <div class="flex flex-col">
                    <div class="mb-3 flex items-center gap-4 text-yt-text">
                        <h2
                            v-if="!comments?.disabled"
                            class="text-lg font-semibold"
                            v-text="
                                `${$t('video.comments') ?? 'Comments'} · ${numberFormat(comments?.commentCount ?? 0)}`
                            "
                        />
                        <button
                            v-if="!comments?.disabled"
                            class="ml-auto cursor-pointer text-sm text-yt-text-secondary hover:text-yt-text"
                            @click="toggleCommentsVisibility"
                            v-text="$t(showComments ? 'actions.minimize_comments' : 'actions.show_comments')"
                        />
                    </div>
                    <div v-if="!showComments" class=""></div>
                    <div v-else-if="!comments" class="">
                        <p v-t="'comment.loading'" class="mt-8 text-center text-yt-text-secondary"></p>
                    </div>
                    <div v-else-if="comments.disabled" class="">
                        <p v-t="'comment.disabled'" class="mt-8 text-center text-yt-text-secondary"></p>
                    </div>
                    <div v-else ref="commentsEl" class="">
                        <CommentItem
                            v-for="comment in comments.comments"
                            :key="comment.commentId"
                            :comment="comment"
                            :uploader="video.uploader"
                            :uploader-avatar-url="video.uploaderAvatar"
                            :video-id="getVideoId()"
                        />
                    </div>
                </div>
            </div>
            <div v-if="video && showDesktopSidebar" class="w-96 flex-none">
                <ChaptersBar
                    v-if="video?.chapters?.length > 0 && showChapters"
                    :mobile-layout="isMobile"
                    :chapters="video.chapters"
                    :player-position="currentTime"
                    @seek="navigate"
                />
                <PlaylistVideos
                    v-if="playlist"
                    :playlist-id="playlistId"
                    :playlist="playlist"
                    :selected-index="index"
                    :prefer-listen="isListening"
                />
                <div v-show="showRecs">
                    <ContentItem
                        v-for="related in video.relatedStreams"
                        :key="related.url"
                        :item="related"
                        :prefer-listen="isListening"
                        class="mb-4"
                        height="94"
                        width="168"
                    />
                </div>
            </div>
        </div>
    </LoadingIndicatorPage>
</template>

<script setup>
import { ref, computed, onMounted, onActivated, onDeactivated, onUnmounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import VideoPlayer from "./VideoPlayer.vue";
import ContentItem from "./ContentItem.vue";
import ErrorHandler from "./ErrorHandler.vue";
import CommentItem from "./CommentItem.vue";
import ChaptersBar from "./ChaptersBar.vue";
import PlaylistAddModal from "./PlaylistAddModal.vue";
import ShareModal from "./ShareModal.vue";
import PlaylistVideos from "./PlaylistVideos.vue";
import WatchOnButton from "./WatchOnButton.vue";
import LoadingIndicatorPage from "./LoadingIndicatorPage.vue";
import ToastComponent from "./ToastComponent.vue";
import UiCheckbox from "./ui/Checkbox.vue";
import { parseTimeParam } from "@/utils/Misc";
import { purifyHTML, rewriteDescription } from "@/utils/HtmlUtils";
import { fetchJson, apiUrl } from "@/composables/useApi.js";
import {
    getPreferenceBoolean,
    getPreferenceNumber,
    getPreferenceString,
    getPreferenceJSON,
    setPreference,
} from "@/composables/usePreferences.js";
import { numberFormat, addCommas } from "@/composables/useFormatting.js";
import {
    fetchSubscriptionStatus,
    toggleSubscriptionState,
    fetchDeArrowContent,
} from "@/composables/useSubscriptions.js";
import { updateWatched } from "@/composables/useMisc.js";
import { getPlaylist } from "@/composables/usePlaylists.js";

const route = useRoute();
const router = useRouter();

const smallViewQuery = window.matchMedia("(max-width: 640px)");

const videoPlayer = ref(null);
const commentsEl = ref(null);

const video = ref(null);
const playlistId = ref(null);
const playlist = ref(null);
const index = ref(null);
const sponsors = ref(null);
const selectedAutoLoop = ref(false);
const selectedAutoPlay = ref(null);
const showComments = ref(true);
const showDesc = ref(false);
const showRecs = ref(true);
const showChapters = ref(true);
const comments = ref(null);
const subscribed = ref(false);
const channelId = ref(null);
const active = ref(true);
const smallView = ref(smallViewQuery.matches);
const showModal = ref(false);
const showShareModal = ref(false);
const isMobile = ref(true);
const currentTime = ref(0);
const shouldShowToast = ref(false);
let timeoutCounter = null;
const counter = ref(0);
const theaterMode = ref(false);
let loading = false;

const isListening = computed(() => {
    return getPreferenceBoolean("listen", false);
});

const selectedAutoPlayEnabled = computed(() => {
    return Number(selectedAutoPlay.value) >= 1;
});

const showDesktopSidebar = computed(() => {
    return (
        !isMobile.value &&
        (showRecs.value || Boolean(playlist.value) || (video.value?.chapters?.length > 0 && showChapters.value))
    );
});

const toggleListenUrl = computed(() => {
    const url = new URL(window.location.href);
    url.searchParams.set("listen", isListening.value ? "0" : "1");
    url.searchParams.set("t", Math.floor(currentTime.value));
    return url.pathname + url.search;
});

const isEmbed = computed(() => {
    return String(route.path).indexOf("/embed/") == 0;
});

const uploadDate = computed(() => {
    return new Date(video.value.uploadDate).toLocaleString(undefined, {
        month: "short",
        day: "numeric",
        year: "numeric",
    });
});

const defaultCounter = computed(() => {
    return getPreferenceNumber("autoPlayNextCountdown", 5);
});

const purifiedDescription = computed(() => {
    return purifyHTML(video.value.description);
});

const youtubeVideoHref = computed(() => {
    let link = `https://youtu.be/${getVideoId()}?t=${Math.round(currentTime.value)}`;
    if (playlistId.value) link += `&list=${playlistId.value}`;
    return link;
});

function fetchVideo() {
    return fetchJson(apiUrl() + "/streams/" + getVideoId());
}

async function fetchSponsors() {
    var selectedSkip = getPreferenceString("selectedSkip", "sponsor,interaction,selfpromo,music_offtopic").split(",");
    const skipOptions = getPreferenceJSON("skipOptions");
    if (skipOptions !== undefined) {
        selectedSkip = Object.keys(skipOptions).filter(k => skipOptions[k] !== undefined && skipOptions[k] !== "no");
    }

    const sponsorsData = await fetchJson(apiUrl() + "/sponsors/" + getVideoId(), {
        category: JSON.stringify(selectedSkip),
    });

    sponsorsData?.segments?.forEach(segment => {
        const option = skipOptions?.[segment.category];
        segment.autoskip = option === undefined || option === "auto";
    });

    const minSegmentLength = Math.max(getPreferenceNumber("minSegmentLength", 0), 0);
    sponsorsData.segments = sponsorsData.segments?.filter(segment => {
        const length = segment.segment[1] - segment.segment[0];
        return length >= minSegmentLength;
    });

    return sponsorsData;
}

function toggleCommentsVisibility() {
    showComments.value = !showComments.value;
    if (showComments.value && comments.value === null) {
        fetchCommentsData();
    }
}

function fetchCommentsData() {
    return fetchJson(apiUrl() + "/comments/" + getVideoId());
}

function onChange() {
    setPreference("autoplay", selectedAutoPlay.value, true);
}

async function getVideoData() {
    await fetchVideo()
        .then(data => {
            video.value = data;
            video.value.id = getVideoId();
        })
        .then(() => {
            if (!video.value.error) {
                document.title = video.value.title + " - Piped";
                channelId.value = video.value.uploaderUrl.split("/")[2];
                if (!isEmbed.value) fetchSubscribedStatus();

                const parser = new DOMParser();
                const xmlDoc = parser.parseFromString(video.value.description, "text/html");
                xmlDoc.querySelectorAll("a").forEach(elem => {
                    if (!elem.innerText.match(/(?:[\d]{1,2}:)?(?:[\d]{1,2}):(?:[\d]{1,2})/))
                        elem.outerHTML = elem.getAttribute("href");
                });
                xmlDoc.querySelectorAll("br").forEach(elem => (elem.outerHTML = "\n"));
                video.value.description = rewriteDescription(xmlDoc.querySelector("body").innerHTML);
                updateWatched(video.value.relatedStreams);

                fetchDeArrowContent(video.value.relatedStreams);
            }
        });
}

async function getPlaylistData() {
    if (playlistId.value) {
        playlist.value = await getPlaylist(playlistId.value);
        await fetchPlaylistPages().then(() => {
            if (!(index.value >= 0)) {
                for (let i = 0; i < playlist.value.relatedStreams.length; i++)
                    if (playlist.value.relatedStreams[i].url.substr(-11) == getVideoId()) {
                        index.value = i + 1;
                        router.replace({
                            query: { ...route.query, index: index.value },
                        });
                        break;
                    }
            }
        });
        await fetchPlaylistPages();
    }
}

async function fetchPlaylistPages() {
    if (playlist.value.nextpage) {
        await fetchJson(apiUrl() + "/nextpage/playlists/" + playlistId.value, {
            nextpage: playlist.value.nextpage,
        }).then(json => {
            playlist.value.relatedStreams.push(...json.relatedStreams);
            playlist.value.nextpage = json.nextpage;
            fetchDeArrowContent(json.relatedStreams);
        });
        await fetchPlaylistPages();
    }
}

async function getSponsors() {
    if (getPreferenceBoolean("sponsorblock", true)) fetchSponsors().then(data => (sponsors.value = data));
}

async function getComments() {
    comments.value = await fetchCommentsData();
}

async function fetchSubscribedStatus() {
    if (!channelId.value) return;
    subscribed.value = await fetchSubscriptionStatus(channelId.value);
}

function subscribeHandler() {
    toggleSubscriptionState(channelId.value, subscribed.value).then(success => {
        if (success) subscribed.value = !subscribed.value;
    });
}

function handleClick(event) {
    if (!event || !event.target) return;
    if (!event.target.matches("a[href]")) return;
    const target = event.target;
    if (!target.getAttribute("href")) return;
    if (handleTimestampLinks(target)) {
        event.preventDefault();
    }
}

function handleTimestampLinks(target) {
    try {
        const url = new URL(target.getAttribute("href"), document.baseURI);
        if (url.searchParams.size > 2 || url.searchParams.get("v") !== getVideoId() || !url.searchParams.has("t")) {
            return false;
        }
        const time = parseTimeParam(url.searchParams.get("t"));
        if (time) {
            navigate(time);
        }
        return true;
    } catch (e) {
        console.error(e);
    }
    return false;
}

function handleScroll() {
    if (loading || !comments.value || !comments.value.nextpage) return;
    if (window.innerHeight + window.scrollY >= commentsEl.value?.offsetHeight - window.innerHeight) {
        loading = true;
        fetchJson(apiUrl() + "/nextpage/comments/" + getVideoId(), {
            nextpage: comments.value.nextpage,
        }).then(json => {
            comments.value.nextpage = json.nextpage;
            loading = false;
            comments.value.comments = comments.value.comments.concat(json.comments);
        });
    }
}

function getVideoId() {
    if (route.query.video_ids) {
        const videos_list = route.query.video_ids.split(",");
        index.value = Number(route.query.index ?? 0);
        return videos_list[index.value];
    }

    return route.query.v || route.params.v;
}

function navigate(time) {
    videoPlayer.value.seek(time);
}

function onTimeUpdate(time) {
    currentTime.value = time;
}

function onVideoEnded() {
    if (
        !selectedAutoLoop.value &&
        ((selectedAutoPlay.value >= 1 && playlist.value?.relatedStreams?.length > index.value) ||
            (selectedAutoPlay.value >= 2 && video.value.relatedStreams.length > 0))
    ) {
        showToast();
    }
}

function showToast() {
    counter.value = defaultCounter.value;
    if (counter.value < 1) {
        navigateNext();
        return;
    }
    if (timeoutCounter) clearInterval(timeoutCounter);
    timeoutCounter = setInterval(() => {
        counter.value--;
        if (counter.value === 0) {
            dismiss();
            navigateNext();
        }
    }, 1000);
    shouldShowToast.value = true;
}

function dismiss() {
    clearInterval(timeoutCounter);
    shouldShowToast.value = false;
}

function navigateNext() {
    const params = route.query;
    const video_ids = route.query.video_ids?.split(",") ?? [];
    let url;
    if (playlist.value) {
        url = playlist.value?.relatedStreams?.[index.value]?.url ?? video.value.relatedStreams[0].url;
    } else if (video_ids.length > index.value + 1) {
        url = `${route.path}?index=${index.value + 1}`;
    } else {
        url = video.value.relatedStreams[0].url;
    }
    const searchParams = new URLSearchParams();
    for (var param in params)
        switch (param) {
            case "v":
            case "t":
                break;
            case "index":
                if (playlist.value && index.value < playlist.value.relatedStreams.length)
                    searchParams.set("index", index.value + 1);
                break;
            case "list":
                if (index.value < playlist.value.relatedStreams.length) searchParams.set("list", params.list);
                break;
            default:
                searchParams.set(param, params[param]);
                break;
        }
    searchParams.set("fullscreen", videoPlayer.value.isFullScreenEnabled());
    const paramStr = searchParams.toString();
    if (paramStr.length > 0) url += "&" + paramStr;
    router.push(url);
}

function downloadCurrentFrame() {
    const videoEl = document.querySelector("video");
    const canvas = document.createElement("canvas");
    canvas.width = videoEl.videoWidth;
    canvas.height = videoEl.videoHeight;

    const context = canvas.getContext("2d");
    context.drawImage(videoEl, 0, 0, canvas.width, canvas.height);

    let link = document.createElement("a");
    const ct = Math.round(videoEl.currentTime * 1000) / 1000;
    link.download = `${video.value.title}_${ct}s.png`;
    link.href = canvas.toDataURL();
    link.click();
}

onMounted(() => {
    isMobile.value = window.innerWidth < 1024;
    window.addEventListener("resize", () => {
        isMobile.value = window.innerWidth < 1024;
    });
    getVideoData().then(() => {
        (async () => {
            const videoId = getVideoId();
            if (window.db && getPreferenceBoolean("watchHistory", false) && !video.value.error) {
                var tx = window.db.transaction("watch_history", "readwrite");
                var store = tx.objectStore("watch_history");
                var request = store.get(videoId);
                request.onsuccess = function (event) {
                    var vid = event.target.result;
                    if (vid) {
                        vid.watchedAt = Date.now();
                    } else {
                        vid = {
                            videoId: videoId,
                            title: video.value.title,
                            duration: video.value.duration,
                            thumbnail: video.value.thumbnailUrl,
                            uploaderUrl: video.value.uploaderUrl,
                            uploaderName: video.value.uploader,
                            watchedAt: Date.now(),
                        };
                    }
                    store.put(vid);
                };
            }
        })();
        if (active.value) videoPlayer.value.loadVideo();
    });
    playlistId.value = route.query.list;
    index.value = Number(route.query.index);
    getPlaylistData();
    getSponsors();
    if (!isEmbed.value && showComments.value) getComments();
    if (isEmbed.value) document.querySelector("html").style.overflow = "hidden";
    window.addEventListener("click", handleClick);
    window.addEventListener("resize", () => {
        smallView.value = smallViewQuery.matches;
    });
});

onActivated(() => {
    active.value = true;
    theaterMode.value = getPreferenceBoolean("theaterMode", window.innerWidth < (window.innerHeight * 4) / 3 + 467);
    selectedAutoPlay.value = getPreferenceNumber("autoplay", 1);
    showComments.value = !getPreferenceBoolean("minimizeComments", false);
    showDesc.value = !getPreferenceBoolean("minimizeDescription", true);
    showRecs.value = !getPreferenceBoolean("minimizeRecommendations", false);
    showChapters.value = !getPreferenceBoolean("minimizeChapters", false);
    if (video.value?.duration) {
        document.title = video.value.title + " - Piped";
        videoPlayer.value.loadVideo();
    }
    window.addEventListener("scroll", handleScroll);
});

onDeactivated(() => {
    active.value = false;
    window.removeEventListener("scroll", handleScroll);
    dismiss();
});

onUnmounted(() => {
    window.removeEventListener("scroll", handleScroll);
    window.removeEventListener("click", handleClick);
    dismiss();
});
</script>

<style>
.v-enter-from,
.v-leave-to {
    opacity: 0;
    transform: translateX(100%) scale(0.5);
}
</style>
