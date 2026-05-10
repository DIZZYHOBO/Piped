<template>
    <button
        type="button"
        class="ml-2 inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
        :aria-label="modelValue ? $t('actions.hide_password') : $t('actions.show_password')"
        :aria-pressed="modelValue"
        @click="$emit('update:modelValue', !modelValue)"
    >
        <i-fa6-solid-eye v-if="!modelValue" />
        <i-fa6-solid-eye-slash v-else />
    </button>
</template>

<script setup>
import { useI18n } from "vue-i18n";

defineProps({
    modelValue: {
        type: Boolean,
        required: true,
    },
});

defineEmits(["update:modelValue"]);

const { t: $t } = useI18n();
</script>
