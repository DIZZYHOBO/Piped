<template>
    <ModalComponent @close="$emit('close')">
        <h2 v-t="'actions.create_group'" />
        <div class="flex flex-col">
            <input
                v-model="groupName"
                class="my-4 h-9 rounded-lg bg-yt-surface px-3 text-yt-text outline-none focus:ring-2 focus:ring-yt-brand-red"
                type="text"
                :placeholder="$t('actions.group_name')"
            />
            <button
                v-t="'actions.create_group'"
                class="ml-auto inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-text px-4 text-sm font-medium text-yt-bg hover:bg-yt-text-secondary"
                @click="createGroup()"
            />
        </div>
    </ModalComponent>
</template>

<script setup>
import ModalComponent from "./ModalComponent.vue";
import { ref } from "vue";

const props = defineProps({
    onCreateGroup: {
        required: true,
        type: Function,
    },
});

const emit = defineEmits(["close"]);

const groupName = ref("");

function createGroup() {
    props.onCreateGroup(groupName.value);
    emit("close");
}
</script>
