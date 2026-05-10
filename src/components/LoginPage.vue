<template>
    <div class="mx-auto mt-8 max-w-sm rounded-2xl bg-yt-surface p-6 text-yt-text">
        <div class="mb-2 flex items-center gap-2">
            <h1 v-t="'titles.login'" class="text-2xl font-bold" />
            <i-fa6-solid-circle-info class="cursor-pointer text-yt-text-secondary" :title="$t('info.login_note')" />
        </div>
        <p class="mb-5 text-sm text-yt-text-secondary">Sign in to sync subscriptions and history with the backend.</p>

        <form class="flex flex-col gap-3">
            <input
                v-model="username"
                class="h-10 rounded-lg bg-yt-bg px-3 text-yt-text outline-none focus:ring-2 focus:ring-yt-brand-red"
                type="text"
                autocomplete="username"
                :placeholder="$t('login.username')"
                :aria-label="$t('login.username')"
                @keyup.enter="login"
            />
            <input
                v-model="password"
                class="h-10 rounded-lg bg-yt-bg px-3 text-yt-text outline-none focus:ring-2 focus:ring-yt-brand-red"
                type="password"
                autocomplete="password"
                :placeholder="$t('login.password')"
                :aria-label="$t('login.password')"
                @keyup.enter="login"
            />
            <Button v-t="'titles.login'" class="mt-2 self-stretch" @click="login" />
        </form>
    </div>
</template>

<script setup>
import { ref, onMounted, onActivated } from "vue";
import { useRouter } from "vue-router";
import { useI18n } from "vue-i18n";
import { fetchJson, authApiUrl, getAuthToken, hashCode } from "@/composables/useApi.js";
import { setPreference } from "@/composables/usePreferences.js";
import Button from "./ui/Button.vue";

const router = useRouter();
const { t } = useI18n();

const username = ref(null);
const password = ref(null);

onMounted(() => {
    //TODO: Add Server Side check
    if (getAuthToken()) {
        router.push(import.meta.env.BASE_URL);
    }
});

onActivated(() => {
    document.title = t("titles.login") + " - Piped";
});

function login() {
    if (!username.value || !password.value) return;
    fetchJson(authApiUrl() + "/login", null, {
        method: "POST",
        body: JSON.stringify({
            username: username.value,
            password: password.value,
        }),
    }).then(resp => {
        if (resp.token) {
            setPreference("authToken" + hashCode(authApiUrl()), resp.token);
            window.location = import.meta.env.BASE_URL; // done to bypass cache
        } else alert(resp.error);
    });
}
</script>
