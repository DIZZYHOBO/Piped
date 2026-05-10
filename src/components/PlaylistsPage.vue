<template>
    <div class="flex flex-wrap items-center gap-3 py-3">
        <h1 v-t="'titles.playlists'" class="text-2xl font-bold text-yt-text" />
        <span class="ml-auto flex flex-wrap items-center gap-2">
            <button
                v-t="'actions.create_playlist'"
                class="inline-flex h-9 cursor-pointer items-center gap-1.5 rounded-full bg-yt-text px-4 text-sm font-medium text-yt-bg hover:bg-yt-text-secondary"
                @click="showCreatePlaylistModal = true"
            />
            <button
                v-if="playlists.length > 0"
                v-t="'actions.export_to_json'"
                class="inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
                @click="exportPlaylists"
            />
            <input
                id="fileSelector"
                ref="fileSelector"
                type="file"
                class="hidden"
                multiple="multiple"
                @change="importPlaylists"
            />
            <label
                v-t="'actions.import_from_json_csv'"
                for="fileSelector"
                class="inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
            />
        </span>
    </div>

    <div class="grid grid-cols-1 gap-x-4 gap-y-10 pt-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5">
        <div v-for="playlist in playlists" :key="playlist.id">
            <router-link :to="`/playlist?list=${playlist.id}`" class="block">
                <div class="relative overflow-hidden rounded-xl">
                    <img class="aspect-video w-full object-cover" :src="playlist.thumbnail" alt="thumbnail" />
                    <span
                        class="absolute right-2 bottom-2 inline-flex items-center gap-1 rounded-md bg-black/85 px-2 py-1 text-xs font-medium text-white"
                    >
                        <i-fa6-solid-list />
                        <span v-text="`${playlist.videos} ${$t('video.videos')}`" />
                    </span>
                </div>
                <p
                    class="mt-3 line-clamp-2 text-sm/snug font-medium text-yt-text"
                    :title="playlist.name"
                    v-text="playlist.name"
                />
            </router-link>
            <div class="mt-2 flex gap-2">
                <button
                    v-t="'actions.edit_playlist'"
                    class="cursor-pointer rounded-full bg-yt-surface px-3 py-1.5 text-xs font-medium text-yt-text hover:bg-yt-surface-hover"
                    @click="showPlaylistEditModal(playlist)"
                />
                <button
                    v-t="'actions.delete_playlist'"
                    class="cursor-pointer rounded-full bg-yt-surface px-3 py-1.5 text-xs font-medium text-yt-text hover:bg-yt-surface-hover"
                    @click="playlistToDelete = playlist.id"
                />
            </div>
            <ModalComponent v-if="playlist.id == playlistToEdit" @close="playlistToEdit = null">
                <div class="flex flex-col gap-2">
                    <h2 v-t="'actions.edit_playlist'" />
                    <input
                        v-model="newPlaylistName"
                        class="h-9 rounded-md bg-yt-surface px-3 text-yt-text outline-none focus:border-blue-500"
                        type="text"
                        :placeholder="$t('actions.playlist_name')"
                    />
                    <input
                        v-model="newPlaylistDescription"
                        class="h-9 rounded-md bg-yt-surface px-3 text-yt-text outline-none focus:border-blue-500"
                        type="text"
                        :placeholder="$t('actions.playlist_description')"
                    />
                    <button
                        v-t="'actions.okay'"
                        class="ml-auto inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-text px-4 text-sm font-medium text-yt-bg hover:bg-yt-text-secondary"
                        @click="editPlaylist(playlist)"
                    />
                </div>
            </ModalComponent>
            <ConfirmModal
                v-if="playlistToDelete == playlist.id"
                :message="$t('actions.delete_playlist_confirm')"
                @close="playlistToDelete = null"
                @confirm="onDeletePlaylist(playlist.id)"
            />
        </div>
    </div>

    <h2 v-t="'titles.bookmarks'" class="mt-12 mb-4 text-2xl font-bold text-yt-text" />

    <div
        v-if="bookmarks"
        class="grid grid-cols-1 gap-x-4 gap-y-10 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5"
    >
        <router-link
            v-for="(playlist, index) in bookmarks"
            :key="playlist.playlistId"
            :to="`/playlist?list=${playlist.playlistId}`"
            class="block"
        >
            <div class="relative overflow-hidden rounded-xl">
                <img class="aspect-video w-full object-cover" :src="playlist.thumbnail" alt="thumbnail" />
                <span
                    class="absolute right-2 bottom-2 inline-flex items-center gap-1 rounded-md bg-black/85 px-2 py-1 text-xs font-medium text-white"
                    v-text="`${playlist.videos} ${$t('video.videos')}`"
                />
                <button
                    class="absolute top-2 right-2 z-10 grid size-8 place-items-center rounded-full bg-black/70 text-white hover:bg-black/85"
                    @click.prevent="removeBookmark(index)"
                >
                    <i-fa6-solid-bookmark />
                </button>
            </div>
            <p
                class="mt-3 line-clamp-2 text-sm/snug font-medium text-yt-text"
                :title="playlist.name"
                v-text="playlist.name"
            />
            <span class="mt-1.5 flex items-center gap-2 text-xs text-yt-text-secondary">
                <img class="size-6 rounded-full" :src="playlist.uploaderAvatar" />
                <span v-text="playlist.uploader" />
            </span>
        </router-link>
    </div>

    <CreatePlaylistModal
        v-if="showCreatePlaylistModal"
        @close="showCreatePlaylistModal = false"
        @created="fetchPlaylistsList"
    />
</template>

<script setup>
import { ref, onMounted, onActivated } from "vue";
import { useI18n } from "vue-i18n";
import ConfirmModal from "./ConfirmModal.vue";
import ModalComponent from "./ModalComponent.vue";
import CreatePlaylistModal from "./CreatePlaylistModal.vue";
import {
    getPlaylists,
    getPlaylist,
    createPlaylist,
    deletePlaylist,
    renamePlaylist,
    changePlaylistDescription,
    addVideosToPlaylist,
} from "@/composables/usePlaylists.js";
import { download } from "@/composables/useMisc.js";

const { t } = useI18n();

const fileSelector = ref(null);
const playlists = ref([]);
const bookmarks = ref([]);
const playlistToDelete = ref(null);
const playlistToEdit = ref(null);
const newPlaylistName = ref("");
const newPlaylistDescription = ref("");
const showCreatePlaylistModal = ref(false);

function fetchPlaylistsList() {
    getPlaylists().then(json => {
        playlists.value = json;
    });
}

function showPlaylistEditModal(playlist) {
    newPlaylistName.value = playlist.name;
    newPlaylistDescription.value = playlist.description;
    playlistToEdit.value = playlist.id;
}

function editPlaylist(selectedPlaylist) {
    const newName = newPlaylistName.value;
    const newDescription = newPlaylistDescription.value;
    if (newName != selectedPlaylist.name) {
        renamePlaylist(selectedPlaylist.id, newName).then(json => {
            if (json.error) alert(json.error);
            else selectedPlaylist.name = newName;
        });
    }
    if (newDescription != selectedPlaylist.description) {
        changePlaylistDescription(selectedPlaylist.id, newDescription).then(json => {
            if (json.error) alert(json.error);
            else selectedPlaylist.description = newDescription;
        });
    }
    playlistToEdit.value = null;
}

function onDeletePlaylist(id) {
    deletePlaylist(id).then(json => {
        if (json.error) alert(json.error);
        else playlists.value = playlists.value.filter(playlist => playlist.id !== id);
    });
    playlistToDelete.value = null;
}

async function exportPlaylists() {
    if (!playlists.value) return;
    let json = {
        format: "Piped",
        version: 1,
        playlists: [],
    };
    let tasks = playlists.value.map(playlist => fetchPlaylistJson(playlist.id));
    json.playlists = await Promise.all(tasks);
    download(JSON.stringify(json), "playlists.json", "application/json");
}

async function fetchPlaylistJson(playlistId) {
    let playlist = await getPlaylist(playlistId);
    return {
        name: playlist.name,
        type: "playlist",
        visibility: "private",
        videos: playlist.relatedStreams.map(stream => "https://youtube.com" + stream.url),
    };
}

async function importPlaylists() {
    const files = fileSelector.value.files;
    for (let file of files) {
        await importPlaylistFile(file);
    }
    window.location.reload();
}

async function importPlaylistFile(file) {
    let text = (await file.text()).trim();
    let tasks = [];
    if (file.name.slice(-4).toLowerCase() == ".csv") {
        const lines = text.split("\n");

        const playlistInfo = lines[1].split(",");
        let videoListStartIndex = 0;
        let playlistName = null;
        if (playlistInfo.length > 2) {
            playlistName = playlistInfo[4];
            videoListStartIndex = 4;
        }

        const playlist = {
            name: playlistName ?? file.name.replace(".csv", ""),
            videos: lines
                .slice(videoListStartIndex, lines.length)
                .filter(line => line != "")
                .slice(1)
                .map(line => `https://youtube.com/watch?v=${line.split(",")[0]}`),
        };
        tasks.push(createPlaylistWithVideos(playlist));
    } else if (text.includes('"Piped"')) {
        let parsedPlaylists = JSON.parse(text).playlists;
        if (!parsedPlaylists.length) {
            alert(t("actions.no_valid_playlists"));
            return;
        }
        for (let playlist of parsedPlaylists) {
            tasks.push(createPlaylistWithVideos(playlist));
        }
    } else {
        alert(t("actions.no_valid_playlists"));
        return;
    }
    await Promise.all(tasks);
}

async function createPlaylistWithVideos(playlist) {
    let newPlaylist = await createPlaylist(playlist.name);
    let videoIds = playlist.videos.map(url => url.substr(-11));
    await addVideosToPlaylist(newPlaylist.playlistId, videoIds);
}

async function loadPlaylistBookmarks() {
    if (!window.db) return;
    var tx = window.db.transaction("playlist_bookmarks", "readonly");
    var store = tx.objectStore("playlist_bookmarks");
    const cursorRequest = store.openCursor();
    cursorRequest.onsuccess = e => {
        const cursor = e.target.result;
        if (cursor) {
            bookmarks.value.push(cursor.value);
            cursor.continue();
        }
    };
}

async function removeBookmark(index) {
    var tx = window.db.transaction("playlist_bookmarks", "readwrite");
    var store = tx.objectStore("playlist_bookmarks");
    store.delete(bookmarks.value[index].playlistId);
    bookmarks.value.splice(index, 1);
}

onMounted(() => {
    fetchPlaylistsList();
    loadPlaylistBookmarks();
});

onActivated(() => {
    document.title = t("titles.playlists") + " - Piped";
});
</script>
