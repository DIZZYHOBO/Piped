<template>
    <div class="flex gap-3 py-3">
        <img
            loading="lazy"
            :src="comment.thumbnail"
            class="size-10 shrink-0 rounded-full"
            height="40"
            width="40"
            alt="Avatar"
        />

        <div class="min-w-0 flex-1">
            <div v-if="comment.pinned" class="mb-1 inline-flex items-center gap-1.5 text-xs text-yt-text-secondary">
                <i-fa6-solid-thumbtack />
                <span
                    v-t="{
                        path: 'comment.pinned_by',
                        args: { author: uploader },
                    }"
                />
            </div>

            <div class="mb-0.5 flex items-center gap-1.5 text-sm">
                <router-link class="font-medium text-yt-text hover:text-yt-text-secondary" :to="comment.commentorUrl">{{
                    comment.author
                }}</router-link>
                <i-fa6-solid-check v-if="comment.verified" class="text-xs text-yt-text-secondary" />
                <span class="text-xs text-yt-text-secondary" v-text="comment.commentedTime" />
            </div>

            <CollapsableText :text="comment.commentText" :visible-limit="500" />

            <div class="mt-2 flex items-center gap-3 text-xs text-yt-text-secondary">
                <span class="inline-flex items-center gap-1.5">
                    <i-fa6-solid-thumbs-up />
                    <span v-text="numberFormat(comment.likeCount)" />
                </span>
                <i-fa6-solid-heart
                    v-if="comment.hearted"
                    class="text-yt-brand-red"
                    :title="$t('actions.creator_liked')"
                />
                <img
                    v-if="comment.creatorReplied"
                    :src="uploaderAvatarUrl"
                    class="size-5 rounded-full"
                    :title="$t('actions.creator_replied')"
                />
            </div>

            <template v-if="comment.repliesPage && (!loadingReplies || !showingReplies)">
                <button
                    class="mt-2 inline-flex h-8 cursor-pointer items-center gap-1.5 rounded-full px-3 text-xs font-medium text-yt-brand-red hover:bg-yt-surface"
                    @click="loadReplies"
                >
                    <i-fa6-solid-turn-down />
                    <span v-text="`${$t('actions.reply_count', comment.replyCount)}`" />
                </button>
            </template>
            <template v-if="showingReplies">
                <button
                    class="mt-2 inline-flex h-8 cursor-pointer items-center gap-1.5 rounded-full px-3 text-xs font-medium text-yt-brand-red hover:bg-yt-surface"
                    @click="hideReplies"
                >
                    <i-fa6-solid-turn-up />
                    <span v-t="'actions.hide_replies'" />
                </button>
            </template>

            <div v-if="replies" v-show="showingReplies" class="mt-2 border-l border-yt-border pl-2">
                <div v-for="reply in replies" :key="reply.commentId" class="w-full">
                    <!-- eslint-disable-next-line vue/no-undef-components -->
                    <CommentItem :comment="reply" :uploader="uploader" :video-id="videoId" />
                </div>
                <button
                    v-if="nextpage"
                    class="mt-2 inline-flex h-8 cursor-pointer items-center gap-1.5 rounded-full px-3 text-xs font-medium text-yt-brand-red hover:bg-yt-surface"
                    @click="loadReplies"
                >
                    <i-fa6-solid-turn-down />
                    <span v-t="'actions.load_more_replies'" />
                </button>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref } from "vue";
import CollapsableText from "./CollapsableText.vue";
import { fetchJson, apiUrl } from "@/composables/useApi.js";
import { numberFormat } from "@/composables/useFormatting.js";

const props = defineProps({
    comment: {
        type: Object,
        default: () => {
            return {};
        },
    },
    uploader: { type: String, default: null },
    uploaderAvatarUrl: { type: String, default: null },
    videoId: { type: String, default: null },
});

const loadingReplies = ref(false);
const showingReplies = ref(false);
const replies = ref([]);
const nextpage = ref(null);

async function loadReplies() {
    if (!showingReplies.value && loadingReplies.value) {
        showingReplies.value = true;
        return;
    }
    loadingReplies.value = true;
    showingReplies.value = true;
    fetchJson(apiUrl() + "/nextpage/comments/" + props.videoId, {
        nextpage: nextpage.value || props.comment.repliesPage,
    }).then(json => {
        replies.value = replies.value.concat(json.comments);
        nextpage.value = json.nextpage;
    });
}

async function hideReplies() {
    showingReplies.value = false;
}
</script>
