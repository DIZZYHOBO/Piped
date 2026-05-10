<template>
    <button
        type="button"
        class="absolute right-3 size-5 cursor-pointer rounded-full bg-yt-surface text-center text-xs/5 text-yt-text hover:bg-yt-surface-hover"
        :aria-label="$t('actions.clear')"
        @click="$emit('clear')"
    >
        ⨉
    </button>
</template>

<script setup>
import { useI18n } from "vue-i18n";

defineEmits(["clear"]);

const { t: $t } = useI18n();
</script>
