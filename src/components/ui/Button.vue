<template>
    <button
        :type="type"
        :class="[
            'inline-flex h-9 cursor-pointer items-center justify-center gap-1.5 rounded-full px-4 text-sm font-medium transition-colors',
            variant === 'primary'
                ? 'bg-yt-text text-yt-bg hover:bg-yt-text-secondary'
                : 'bg-yt-surface text-yt-text hover:bg-yt-surface-hover',
            customClass,
        ]"
        v-bind="$attrs"
    >
        <slot />
    </button>
</template>

<script setup>
defineOptions({
    name: "UiButton",
});

defineProps({
    type: {
        type: String,
        default: "button",
        validator: val => ["button", "submit"].includes(val),
    },
    variant: {
        type: String,
        default: "primary",
        validator: val => ["primary", "secondary"].includes(val),
    },
    customClass: {
        type: String,
        default: "",
    },
});
</script>
