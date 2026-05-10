<template>
    <ModalComponent @close="$emit('close')">
        <div class="flex flex-col">
            <h2 v-t="'actions.create_playlist'" />
            <input
                ref="input"
                v-model="playlistName"
                type="text"
                class="mt-2 h-9 rounded-lg bg-yt-surface px-3 text-yt-text outline-none focus:ring-2 focus:ring-yt-brand-red"
            />
            <div class="mt-3 ml-auto flex w-min">
                <button
                    v-t="'actions.cancel'"
                    class="inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
                    @click="$emit('close')"
                />
                <button
                    v-t="'actions.okay'"
                    class="ml-2 inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
                    @click="onCreatePlaylist"
                />
            </div>
        </div>
    </ModalComponent>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from "vue";
import ModalComponent from "./ModalComponent.vue";
import { createPlaylist } from "@/composables/usePlaylists.js";

const emit = defineEmits(["created", "close"]);

const playlistName = ref("");
const input = ref(null);

function handleKeyDown(event) {
    if (event.code === "Enter") {
        onCreatePlaylist();
        event.preventDefault();
    }
}

function onCreatePlaylist() {
    if (!playlistName.value) return;

    createPlaylist(playlistName.value).then(response => {
        if (response.error) alert(response.error);
        else {
            emit("created", response.playlistId, playlistName.value);
            emit("close");
        }
    });
}

onMounted(() => {
    input.value.focus();
    window.addEventListener("keydown", handleKeyDown);
});

onUnmounted(() => {
    window.removeEventListener("keydown", handleKeyDown);
});
</script>
