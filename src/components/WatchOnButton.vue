<script setup>
import { getPreferenceBoolean } from "@/composables/usePreferences.js";

defineProps({
    link: {
        type: String,
        required: true,
    },
    platform: {
        type: String,
        required: false,
        default: "YouTube",
    },
});
</script>

<template>
    <template v-if="getPreferenceBoolean('showWatchOnYouTube', false)">
        <!-- For large screens -->
        <a
            :href="link"
            class="inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover max-lg:hidden"
        >
            <i18n-t keypath="player.watch_on" tag="strong">{{ platform }}</i18n-t>
            <i-fa6-brands-youtube v-if="platform == 'YouTube'" class="mx-1.5" />
            <i-fa6-brands-odysee v-else-if="platform == 'Odysee'" class="mx-1.5" />
        </a>
        <!-- For small screens -->
        <a
            :href="link"
            class="inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover lg:hidden"
        >
            <i-fa6-brands-youtube v-if="platform == 'YouTube'" class="mx-1.5" />
            <i-fa6-brands-odysee v-else-if="platform == 'Odysee'" class="mx-1.5" />
        </a>
    </template>
</template>
