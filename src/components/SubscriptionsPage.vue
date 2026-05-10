<template>
    <div class="flex items-center gap-3 py-3">
        <h1 v-t="'titles.subscriptions'" class="text-2xl font-bold text-yt-text" />
        <span
            v-if="subscriptions.length > 0"
            class="text-sm text-yt-text-secondary"
            v-text="`${subscriptions.length} channels`"
        />
    </div>

    <!-- Import / export action row -->
    <div class="flex flex-wrap items-center gap-2 pb-3">
        <router-link
            v-t="'actions.import_from_json_csv'"
            to="/import"
            class="inline-flex h-9 items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
        />
        <button
            v-t="'actions.export_to_json'"
            class="inline-flex h-9 items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
            @click="exportHandler"
        />
        <label
            for="fileSelector"
            class="inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
            v-text="`${$t('actions.import_from_json')} (${$t('titles.channel_groups')})`"
        />
        <input
            id="fileSelector"
            ref="fileSelector"
            type="file"
            class="hidden"
            multiple="multiple"
            @change="importGroupsHandler"
        />
        <button
            class="inline-flex h-9 items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
            @click="exportGroupsHandler"
            v-text="`${$t('actions.export_to_json')} (${$t('titles.channel_groups')})`"
        />
    </div>

    <!-- Channel-group chips -->
    <nav class="-mx-1 flex flex-wrap gap-2 border-y border-yt-border bg-yt-bg px-1 py-3">
        <button
            v-for="group in channelGroups"
            :key="group.groupName"
            class="inline-flex h-8 shrink-0 items-center gap-2 rounded-lg border px-3 text-sm font-medium transition-colors"
            :class="
                selectedGroup === group
                    ? 'border-transparent bg-yt-text text-yt-bg'
                    : 'border-yt-border bg-yt-surface text-yt-text hover:bg-yt-surface-hover'
            "
            @click="selectGroup(group)"
        >
            <span v-text="group.groupName !== '' ? group.groupName : $t('video.all')" />
            <template v-if="group.groupName != '' && selectedGroup == group">
                <i-fa6-solid-pen class="ml-1 cursor-pointer" @click.stop="showEditGroupModal = true" />
                <i-fa6-solid-circle-minus class="cursor-pointer" @click.stop="groupToDelete = group.groupName" />
            </template>
        </button>
        <ConfirmModal
            v-if="groupToDelete != null"
            :message="$t('actions.delete_group_confirm')"
            @close="groupToDelete = null"
            @confirm="deleteGroup(groupToDelete)"
        />
        <button
            class="grid size-8 place-items-center rounded-full bg-yt-surface text-yt-text hover:bg-yt-surface-hover"
            :title="$t('actions.create_playlist')"
            @click="showCreateGroupModal = true"
        >
            <i-fa6-solid-circle-plus />
        </button>
    </nav>

    <!-- Channel cards grid -->
    <div class="grid grid-cols-1 gap-4 py-6 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5">
        <div
            v-for="subscription in filteredSubscriptions"
            :key="subscription.url"
            class="flex flex-col items-center rounded-2xl bg-yt-surface p-4 text-center"
        >
            <router-link :to="subscription.url" class="flex flex-col items-center">
                <img :src="subscription.avatar" class="size-20 rounded-full" width="80" height="80" />
                <span class="mt-3 line-clamp-2 text-sm font-medium text-yt-text" v-text="subscription.name" />
            </router-link>
            <button
                v-t="`actions.${subscription.subscribed ? 'unsubscribe' : 'subscribe'}`"
                class="mt-3 cursor-pointer rounded-full px-4 py-1.5 text-sm font-medium transition-colors"
                :class="
                    subscription.subscribed
                        ? 'bg-yt-bg text-yt-text hover:bg-yt-surface-hover'
                        : 'bg-yt-text text-yt-bg hover:bg-yt-text-secondary'
                "
                @click="handleButton(subscription)"
            />
        </div>
    </div>

    <CreateGroupModal
        v-if="showCreateGroupModal"
        :on-create-group="createGroup"
        @close="showCreateGroupModal = false"
    />

    <ModalComponent v-if="showEditGroupModal" @close="showEditGroupModal = false">
        <div class="mt-3 mb-5 flex justify-between">
            <input
                v-model="editedGroupName"
                type="text"
                class="h-9 rounded-lg bg-yt-surface px-3 text-yt-text outline-none focus:ring-2 focus:ring-yt-brand-red"
            />
            <button
                v-t="'actions.okay'"
                class="inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
                :placeholder="$t('actions.group_name')"
                @click="editGroupName()"
            />
        </div>
        <div class="mt-3 mb-2 flex h-[80vh] flex-col overflow-y-scroll pr-2">
            <div v-for="subscription in subscriptions" :key="subscription.name">
                <div class="mr-3 flex items-center justify-between">
                    <a :href="subscription.url" target="_blank" class="flex items-center overflow-hidden">
                        <img :src="subscription.avatar" class="size-8 rounded-full" />
                        <span class="ml-2">{{ subscription.name }}</span>
                    </a>
                    <UiCheckbox
                        :model-value="selectedGroup.channels.includes(subscription.url.substr(-24))"
                        @update:model-value="checkedChange(subscription)"
                    />
                </div>
                <hr />
            </div>
        </div>
    </ModalComponent>
</template>

<script setup>
import { ref, computed, onMounted, onActivated } from "vue";
import ModalComponent from "./ModalComponent.vue";
import CreateGroupModal from "./CreateGroupModal.vue";
import ConfirmModal from "./ConfirmModal.vue";
import UiCheckbox from "./ui/Checkbox.vue";
import { fetchJson, authApiUrl, getAuthToken, isAuthenticated } from "@/composables/useApi.js";
import { fetchSubscriptions, handleLocalSubscriptions } from "@/composables/useSubscriptions.js";
import { getChannelGroups, createOrUpdateChannelGroup, deleteChannelGroup } from "@/composables/useChannelGroups.js";
import { download } from "@/composables/useMisc.js";

const fileSelector = ref(null);
const subscriptions = ref([]);
const selectedGroup = ref({
    groupName: "",
    channels: [],
});
const channelGroups = ref([]);
const showCreateGroupModal = ref(false);
const showEditGroupModal = ref(false);
const editedGroupName = ref("");
const groupToDelete = ref(null);

const filteredSubscriptions = computed(() => {
    return selectedGroup.value.groupName == ""
        ? subscriptions.value
        : subscriptions.value.filter(channel => selectedGroup.value.channels.includes(channel.url.substr(-24)));
});

function handleButton(subscription) {
    const channelId = subscription.url.split("/")[2];
    if (isAuthenticated()) {
        fetchJson(authApiUrl() + (subscription.subscribed ? "/unsubscribe" : "/subscribe"), null, {
            method: "POST",
            body: JSON.stringify({
                channelId: channelId,
            }),
            headers: {
                Authorization: getAuthToken(),
                "Content-Type": "application/json",
            },
        });
    } else {
        handleLocalSubscriptions(channelId);
    }
    subscription.subscribed = !subscription.subscribed;
}

function exportHandler() {
    const subs = [];
    subscriptions.value.forEach(subscription => {
        subs.push({
            url: "https://www.youtube.com" + subscription.url,
            name: subscription.name,
            service_id: 0,
        });
    });
    const json = JSON.stringify({
        app_version: "",
        app_version_int: 0,
        subscriptions: subs,
    });
    download(json, "subscriptions.json", "application/json");
}

function selectGroup(group) {
    selectedGroup.value = group;
    editedGroupName.value = group.groupName;
}

function createGroup(newGroupName) {
    if (!newGroupName || channelGroups.value.some(group => group.groupName == newGroupName)) return;

    const newGroup = {
        groupName: newGroupName,
        channels: [],
    };
    channelGroups.value.push(newGroup);
    createOrUpdateChannelGroup(newGroup);

    showCreateGroupModal.value = false;
}

function editGroupName() {
    const oldGroupName = selectedGroup.value.groupName;
    const newGroupName = editedGroupName.value;

    if (!newGroupName || newGroupName == oldGroupName) return;
    if (channelGroups.value.some(group => group.groupName == newGroupName)) return;

    selectedGroup.value.groupName = newGroupName;
    createOrUpdateChannelGroup(selectedGroup.value);
    deleteChannelGroup(oldGroupName);

    showEditGroupModal.value = false;
}

function deleteGroup(group) {
    deleteChannelGroup(group);
    channelGroups.value = channelGroups.value.filter(g => g.groupName != group);
    selectedGroup.value = channelGroups.value[0] || {};
    groupToDelete.value = null;
}

function checkedChange(subscription) {
    const channelId = subscription.url.substr(-24);
    selectedGroup.value.channels = selectedGroup.value.channels.includes(channelId)
        ? selectedGroup.value.channels.filter(channel => channel != channelId)
        : selectedGroup.value.channels.concat(channelId);
    createOrUpdateChannelGroup(selectedGroup.value);
}

async function importGroupsHandler() {
    const files = fileSelector.value.files;
    for (let file of files) {
        const groups = JSON.parse(await file.text()).groups;
        for (let group of groups) {
            createOrUpdateChannelGroup(group);
            channelGroups.value.push(group);
        }
    }
}

function exportGroupsHandler() {
    const json = {
        format: "Piped",
        version: 1,
        groups: channelGroups.value.slice(1),
    };
    download(JSON.stringify(json), "channel_groups.json", "application/json");
}

onMounted(() => {
    fetchSubscriptions().then(json => {
        if (json.error) {
            alert(json.error);
            return;
        }

        subscriptions.value = json;
        subscriptions.value.forEach(subscription => (subscription.subscribed = true));
    });

    channelGroups.value.push(selectedGroup.value);
    if (!window.db) return;

    (async () => {
        const groups = await getChannelGroups();
        channelGroups.value.push(...groups);
    })();
});

onActivated(() => {
    document.title = "Subscriptions - Piped";
});
</script>
