<template>
    <div class="mx-auto max-w-2xl">
        <h1 class="pt-3 pb-4 text-2xl font-bold text-yt-text">Import subscriptions</h1>

        <div class="rounded-2xl bg-yt-surface p-5 text-yt-text">
            <form class="flex flex-col gap-4">
                <div class="flex flex-wrap items-center gap-3">
                    <input
                        ref="fileSelector"
                        type="file"
                        class="block w-full text-sm text-yt-text-secondary file:mr-3 file:inline-flex file:h-9 file:cursor-pointer file:items-center file:rounded-full file:border-0 file:bg-yt-bg file:px-4 file:text-sm file:font-medium file:text-yt-text hover:file:bg-yt-surface-hover"
                        @change="fileChange"
                    />
                </div>
                <p class="text-sm text-yt-text-secondary">
                    <span
                        class="font-medium text-yt-text"
                        v-text="`${$t('info.selected_subscriptions')}: ${selectedSubscriptions}`"
                    />
                </p>
                <label class="inline-flex items-center gap-2 text-sm text-yt-text">
                    <UiCheckbox v-model="override" />
                    <span v-t="'actions.override'" />
                </label>
                <Button v-t="'actions.import'" class="self-start" @click="handleImport" />
            </form>
        </div>

        <h2 class="mt-8 mb-3 text-lg font-semibold text-yt-text">From YouTube</h2>
        <div class="rounded-xl bg-yt-surface p-4 text-sm/relaxed text-yt-text-secondary">
            Open
            <a class="text-yt-text underline" href="https://takeout.google.com/takeout/custom/youtube"
                >takeout.google.com/takeout/custom/youtube</a
            >. In "Select data to include", click on "All YouTube data included" and select only "subscriptions". Create
            the export, download the zip, extract <code class="text-yt-text">subscriptions.csv</code>, then import it
            above.
        </div>

        <h2 class="mt-6 mb-3 text-lg font-semibold text-yt-text">From Invidious</h2>
        <div class="rounded-xl bg-yt-surface p-4 text-sm/relaxed text-yt-text-secondary">
            Open
            <a class="text-yt-text underline" href="https://invidio.us/data_control">invidiou.us/data_control</a>. Click
            any of the export options, then import the resulting file above.
        </div>

        <h2 class="mt-6 mb-3 text-lg font-semibold text-yt-text">From NewPipe</h2>
        <div class="rounded-xl bg-yt-surface p-4 text-sm/relaxed text-yt-text-secondary">
            Go to the Feed tab → click the arrow next to "Subscriptions" → save the file → import it above.
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onActivated } from "vue";
import { useI18n } from "vue-i18n";
import Button from "./ui/Button.vue";
import UiCheckbox from "./ui/Checkbox.vue";
import { fetchJson, authApiUrl, getAuthToken, isAuthenticated } from "@/composables/useApi.js";
import { getLocalSubscriptions } from "@/composables/useSubscriptions.js";

const { t } = useI18n();

const fileSelector = ref(null);
const subscriptions = ref([]);
const override = ref(false);

const selectedSubscriptions = computed(() => subscriptions.value.length);

onActivated(() => {
    document.title = "Import - Piped";
});

function fileChange() {
    const file = fileSelector.value.files[0];
    file.text().then(text => {
        subscriptions.value = [];

        // Invidious
        if (text.indexOf("opml") != -1) {
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(text, "text/xml");
            xmlDoc.querySelectorAll("outline[xmlUrl]").forEach(item => {
                const url = item.getAttribute("xmlUrl");
                const id = url.slice(-24);
                subscriptions.value.push(id);
            });
        }
        // NewPipe
        else if (text.indexOf("subscriptions") != -1) {
            const json = JSON.parse(text);
            json.subscriptions
                // if service_id is undefined, chances are it's a freetube export
                .filter(item => item.service_id == 0 || item.service_id == undefined)
                .forEach(item => {
                    const url = item.url;
                    const id = url.slice(-24);
                    subscriptions.value.push(id);
                });
        }
        // Invidious JSON
        else if (text.indexOf("thin_mode") != -1) {
            const json = JSON.parse(text);
            subscriptions.value = json.subscriptions;
        }
        // FreeTube DB
        else if (text.indexOf("allChannels") != -1) {
            const lines = text.split("\n");
            for (let line of lines) {
                if (line === "") continue;
                const json = JSON.parse(line);
                json.subscriptions.forEach(item => {
                    subscriptions.value.push(item.id);
                });
            }
        }
        // Google Takeout JSON
        else if (text.indexOf("contentDetails") != -1) {
            const json = JSON.parse(text);
            json.forEach(item => {
                const id = item.snippet.resourceId.channelId;
                subscriptions.value.push(id);
            });
        }

        // Google Takeout CSV
        else if (file.name.length >= 5 && file.name.slice(-4).toLowerCase() == ".csv") {
            const lines = text.split("\n");
            for (let i = 1; i < lines.length; i++) {
                const line = lines[i];
                const id = line.slice(0, line.indexOf(","));
                if (id.length === 24) subscriptions.value.push(id);
            }
        }
    });
}

function handleImport() {
    if (isAuthenticated()) {
        fetchJson(
            authApiUrl() + "/import",
            {
                override: override.value,
            },
            {
                method: "POST",
                headers: {
                    Authorization: getAuthToken(),
                },
                body: JSON.stringify(subscriptions.value),
            },
        ).then(json => {
            if (json.message === "ok") window.location = "/feed";
        });
    } else {
        importSubscriptionsLocally(subscriptions.value);
        window.location = "/feed";
    }
}

function importSubscriptionsLocally(newChannels) {
    const subs = override.value
        ? [...new Set(newChannels)]
        : [...new Set((getLocalSubscriptions() ?? []).concat(newChannels))];
    // Sort for better cache hits
    subs.sort();
    try {
        localStorage.setItem("localSubscriptions", JSON.stringify(subs));
    } catch {
        alert(t("info.local_storage"));
    }
}
</script>
