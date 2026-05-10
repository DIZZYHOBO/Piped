<template>
    <div class="mx-auto mt-8 max-w-sm rounded-2xl bg-yt-surface p-6 text-yt-text">
        <div class="mb-2 flex items-center gap-2">
            <h1 v-t="'titles.register'" class="text-2xl font-bold" />
            <i-fa6-solid-circle-info class="cursor-pointer text-yt-text-secondary" :title="$t('info.register_note')" />
        </div>
        <p class="mb-5 text-sm text-yt-text-secondary">Create an account on this Piped instance.</p>

        <form class="flex flex-col gap-3">
            <input
                v-model="username"
                class="h-10 rounded-lg bg-yt-bg px-3 text-yt-text outline-none focus:ring-2 focus:ring-yt-brand-red"
                type="text"
                autocomplete="username"
                :placeholder="$t('login.username')"
                :aria-label="$t('login.username')"
                @keyup.enter="register"
            />
            <div class="flex items-center gap-2">
                <input
                    v-model="password"
                    class="h-10 flex-1 rounded-lg bg-yt-bg px-3 text-yt-text outline-none focus:ring-2 focus:ring-yt-brand-red"
                    :type="showPassword ? 'text' : 'password'"
                    autocomplete="password"
                    :placeholder="$t('login.password')"
                    :aria-label="$t('login.password')"
                    @keyup.enter="register"
                />
                <PasswordToggle v-model="showPassword" />
            </div>
            <div class="flex items-center gap-2">
                <input
                    v-model="passwordConfirm"
                    class="h-10 flex-1 rounded-lg bg-yt-bg px-3 text-yt-text outline-none focus:ring-2 focus:ring-yt-brand-red"
                    :type="showConfirmPassword ? 'text' : 'password'"
                    autocomplete="password"
                    :placeholder="$t('login.password_confirm')"
                    :aria-label="$t('login.password_confirm')"
                    @keyup.enter="register"
                />
                <PasswordToggle v-model="showConfirmPassword" />
            </div>
            <Button v-t="'titles.register'" class="mt-2 self-stretch" @click="register" />
        </form>
    </div>
    <ConfirmModal
        v-if="showUnsecureRegisterDialog"
        :message="$t('info.register_no_email_note')"
        @close="showUnsecureRegisterDialog = false"
        @confirm="
            forceUnsecureRegister = true;
            showUnsecureRegisterDialog = false;
            register();
        "
    />
</template>

<script setup>
import { ref, onMounted, onActivated } from "vue";
import { useRouter } from "vue-router";
import { useI18n } from "vue-i18n";
import { isEmail } from "../utils/Misc.js";
import ConfirmModal from "./ConfirmModal.vue";
import Button from "./ui/Button.vue";
import PasswordToggle from "./ui/PasswordToggle.vue";
import { fetchJson, authApiUrl, getAuthToken, hashCode } from "@/composables/useApi.js";
import { setPreference } from "@/composables/usePreferences.js";

const router = useRouter();
const { t } = useI18n();

const username = ref(null);
const password = ref(null);
const passwordConfirm = ref(null);
const showPassword = ref(false);
const showConfirmPassword = ref(false);
const showUnsecureRegisterDialog = ref(false);
const forceUnsecureRegister = ref(false);

onMounted(() => {
    //TODO: Add Server Side check
    if (getAuthToken()) {
        router.push(import.meta.env.BASE_URL);
    }
});

onActivated(() => {
    document.title = "Register - Piped";
});

function register() {
    if (!username.value || !password.value) return;
    if (password.value != passwordConfirm.value) {
        alert(t("login.passwords_incorrect"));
        return;
    }
    if (isEmail(username.value) && !forceUnsecureRegister.value) {
        showUnsecureRegisterDialog.value = true;
        return;
    }
    fetchJson(authApiUrl() + "/register", null, {
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
