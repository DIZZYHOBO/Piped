<template>
    <ModalComponent @close="$emit('close')">
        <h3 v-t="'titles.custom_instances'" class="my-4 font-bold" />
        <hr />
        <div class="text-center">
            <div>
                <div v-for="(customInstance, index) in customInstances" :key="customInstance.name">
                    <div class="flex items-center justify-between">
                        <span>{{ customInstance.name }} - {{ customInstance.api_url }}</span>
                        <i-fa6-solid-circle-minus
                            class="cursor-pointer"
                            @click="removeInstance(customInstance, index)"
                        />
                    </div>
                    <hr />
                </div>
            </div>
            <form class="flex flex-col items-end gap-2">
                <input
                    v-model="name"
                    class="h-9 w-full rounded-lg bg-yt-surface px-3 text-yt-text outline-none focus:ring-2 focus:ring-yt-brand-red"
                    type="text"
                    :placeholder="$t('preferences.instance_name')"
                />
                <input
                    v-model="url"
                    class="h-9 w-full rounded-lg bg-yt-surface px-3 text-yt-text outline-none focus:ring-2 focus:ring-yt-brand-red"
                    type="text"
                    :placeholder="$t('preferences.api_url')"
                    @keyup.enter="addInstance"
                />
                <button
                    v-t="'actions.add'"
                    class="inline-flex h-9 cursor-pointer items-center rounded-full bg-yt-surface px-4 text-sm font-medium text-yt-text hover:bg-yt-surface-hover"
                    @click.prevent="addInstance"
                />
            </form>
        </div>
    </ModalComponent>
</template>

<script setup>
import { ref, onMounted } from "vue";
import { useI18n } from "vue-i18n";
import ModalComponent from "./ModalComponent.vue";
import { getCustomInstances, addCustomInstance, removeCustomInstance } from "@/composables/useCustomInstances.js";

const { t } = useI18n();

defineEmits(["close"]);

const customInstances = ref([]);
const name = ref("");
const url = ref("");

onMounted(() => {
    customInstances.value = getCustomInstances();
});

function isValidInstanceUrl(str) {
    var a = document.createElement("a");
    a.href = str;
    return a.host && a.host != window.location.host;
}

async function addInstance() {
    const newInstance = {
        name: name.value,
        api_url: url.value,
    };

    if (!newInstance.name || !newInstance.api_url) {
        return;
    }
    if (!isValidInstanceUrl(newInstance.api_url)) {
        alert(t("actions.invalid_url"));
        return;
    }

    addCustomInstance(newInstance);
    name.value = "";
    url.value = "";
}

function removeInstance(instance, index) {
    customInstances.value.splice(index, 1);
    removeCustomInstance(instance);
}
</script>
