<template>
    <ModalComponent @close="$emit('close')">
        <div>
            <h3 class="text-xl" v-text="message" />
            <div class="mt-8 ml-auto flex w-min gap-2">
                <button
                    v-t="'actions.cancel'"
                    class="inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
                    @click="$emit('close')"
                />
                <button
                    v-t="'actions.okay'"
                    class="inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
                    @click="$emit('confirm')"
                />
            </div>
        </div>
    </ModalComponent>
</template>

<script setup>
import { onMounted, onUnmounted } from "vue";
import ModalComponent from "./ModalComponent.vue";

defineProps({
    message: {
        type: String,
        required: true,
    },
});

const emit = defineEmits(["close", "confirm"]);

function handleKeyDown(event) {
    if (event.code === "Enter") {
        emit("confirm");
        event.preventDefault();
    }
}

onMounted(() => {
    window.addEventListener("keydown", handleKeyDown);
});

onUnmounted(() => {
    window.removeEventListener("keydown", handleKeyDown);
});
</script>
