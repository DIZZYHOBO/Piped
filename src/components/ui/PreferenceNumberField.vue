<template>
    <NumberFieldRoot
        :id="id"
        :model-value="modelValue"
        :min="min"
        :max="max"
        :step="step"
        class="inline-flex h-9 items-center rounded-md bg-yt-surface text-yt-text"
        @update:model-value="handleUpdate"
    >
        <NumberFieldDecrement
            class="inline-flex h-full w-8 items-center justify-center rounded-l-md border-r border-yt-border text-base transition-colors hover:bg-yt-surface-hover focus-visible:ring-2 focus-visible:ring-yt-brand-red disabled:cursor-not-allowed disabled:opacity-50"
            aria-label="Decrease value"
        >
            −
        </NumberFieldDecrement>
        <NumberFieldInput
            class="h-full w-16 bg-transparent px-2 text-center text-yt-text outline-none focus-visible:ring-2 focus-visible:ring-yt-brand-red"
        />
        <NumberFieldIncrement
            class="inline-flex h-full w-8 items-center justify-center rounded-r-md border-l border-yt-border text-base transition-colors hover:bg-yt-surface-hover focus-visible:ring-2 focus-visible:ring-yt-brand-red disabled:cursor-not-allowed disabled:opacity-50"
            aria-label="Increase value"
        >
            +
        </NumberFieldIncrement>
    </NumberFieldRoot>
</template>

<script setup>
import { NumberFieldDecrement, NumberFieldIncrement, NumberFieldInput, NumberFieldRoot } from "reka-ui";

defineProps({
    id: {
        type: String,
        required: true,
    },
    modelValue: {
        type: Number,
        required: true,
    },
    min: {
        type: Number,
        default: undefined,
    },
    max: {
        type: Number,
        default: undefined,
    },
    step: {
        type: Number,
        default: 1,
    },
});

const emit = defineEmits(["update:modelValue", "change"]);

function handleUpdate(value) {
    emit("update:modelValue", value ?? 0);
    emit("change", value ?? 0);
}
</script>
