<template>
    <div class="flex flex-col items-center text-center">
        <router-link :to="item.url" class="flex flex-col items-center">
            <img loading="lazy" class="aspect-square w-32 rounded-full" :src="item.thumbnail" :alt="item.name" />
            <p class="mt-3 line-clamp-2 text-base/tight font-medium text-yt-text">
                <span v-text="item.name" />
                <i-fa6-solid-check v-if="item.verified" class="ml-1 inline shrink-0" />
            </p>
        </router-link>

        <p v-if="item.uploader" class="mt-1 text-xs text-yt-text-secondary">
            <span v-text="item.uploader" />
            <i-fa6-solid-check v-if="item.uploaderVerified" class="ml-1 inline" />
        </p>

        <p
            v-if="item.subscribers >= 0"
            class="mt-1 text-xs text-yt-text-secondary"
            v-text="`${numberFormat(item.subscribers)} subscribers`"
        />

        <p
            v-if="item.videos >= 0"
            class="text-xs text-yt-text-secondary"
            v-text="`${item.videos} ${$t('video.videos')}`"
        />

        <p
            v-if="item.description"
            class="mt-2 line-clamp-2 max-w-xs text-sm text-yt-text-secondary"
            v-text="item.description"
        />

        <button
            v-if="subscribed != null"
            class="mt-3 cursor-pointer rounded-full px-4 py-2 text-sm font-medium transition-colors"
            :class="
                subscribed
                    ? 'bg-yt-surface text-yt-text hover:bg-yt-surface-hover'
                    : 'bg-yt-text text-yt-bg hover:bg-yt-text-secondary'
            "
            @click="subscribeHandler"
            v-text="$t('actions.' + (subscribed ? 'unsubscribe' : 'subscribe'))"
        />
    </div>
</template>

<script setup>
import { ref, computed, onMounted } from "vue";
import { fetchSubscriptionStatus, toggleSubscriptionState } from "@/composables/useSubscriptions.js";
import { numberFormat } from "@/composables/useFormatting.js";

const props = defineProps({
    item: {
        type: Object,
        required: true,
    },
});

const subscribed = ref(null);

const channelId = computed(() => props.item.url.substr(-24));

async function updateSubscribedStatus() {
    subscribed.value = await fetchSubscriptionStatus(channelId.value);
}

function subscribeHandler() {
    toggleSubscriptionState(channelId.value, subscribed.value).then(success => {
        if (success) subscribed.value = !subscribed.value;
    });
}

onMounted(() => {
    updateSubscribedStatus();
});
</script>
