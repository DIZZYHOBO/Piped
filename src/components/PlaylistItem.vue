<template>
    <div class="flex flex-col">
        <router-link :to="props.item.url" class="block">
            <div class="relative overflow-hidden rounded-xl">
                <img loading="lazy" class="aspect-video w-full object-cover" :src="props.item.thumbnail" />
                <span
                    v-if="props.item.videos >= 0"
                    class="absolute right-2 bottom-2 inline-flex items-center gap-1 rounded-md bg-black/85 px-2 py-1 text-xs font-medium text-white"
                >
                    <i-fa6-solid-list />
                    <span v-text="`${props.item.videos} videos`" />
                </span>
            </div>
        </router-link>

        <div class="mt-3">
            <router-link :to="props.item.url">
                <p
                    class="line-clamp-2 text-sm/snug font-medium text-yt-text"
                    :title="props.item.name"
                    v-text="props.item.name"
                />
            </router-link>

            <router-link
                v-if="props.item.uploaderUrl"
                class="mt-1.5 inline-flex items-center gap-1 text-xs text-yt-text-secondary hover:text-yt-text"
                :to="props.item.uploaderUrl"
            >
                <span v-text="props.item.uploaderName" />
                <i-fa6-solid-check v-if="props.item.uploaderVerified" class="shrink-0" />
            </router-link>
            <span
                v-else-if="props.item.uploaderName"
                class="mt-1.5 block text-xs text-yt-text-secondary"
                v-text="props.item.uploaderName"
            />

            <p class="mt-1 text-xs text-yt-text-secondary">
                <span>Playlist</span>
            </p>

            <p
                v-if="props.item.description"
                class="mt-2 line-clamp-2 text-xs text-yt-text-secondary"
                v-text="props.item.description"
            />
        </div>
    </div>
</template>

<script setup>
const props = defineProps({
    item: {
        type: Object,
        required: true,
    },
});
</script>
