<template>
    <p v-text="message" />
    <button
        v-t="'actions.show_more'"
        class="inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
        @click="toggleTrace"
    />
    <p ref="stacktrace" class="whitespace-pre-wrap" hidden v-text="error" />
</template>

<script setup>
import { ref } from "vue";

defineProps({
    error: { type: String, default: null },
    message: { type: String, default: null },
});

const stacktrace = ref(null);

function toggleTrace() {
    stacktrace.value.hidden = !stacktrace.value.hidden;
}
</script>
