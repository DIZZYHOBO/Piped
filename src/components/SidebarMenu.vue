<template>
    <aside
        :class="[
            'sticky top-(--topbar-h) hidden h-[calc(100vh-var(--topbar-h))] shrink-0 overflow-y-auto bg-yt-bg py-3 md:block',
            collapsed ? 'w-(--sidebar-rail-w)' : 'w-(--sidebar-w)',
        ]"
    >
        <!-- Primary -->
        <section class="border-b border-yt-border px-2 pb-2">
            <NavLink to="/" :collapsed="collapsed" exact>
                <template #icon><i-fa6-solid-house /></template>
                Home
            </NavLink>
            <NavLink to="/feed" :collapsed="collapsed">
                <template #icon><i-fa6-solid-rectangle-list /></template>
                Subscriptions
            </NavLink>
        </section>

        <!-- You -->
        <section v-if="!collapsed" class="border-b border-yt-border p-2">
            <h3 class="px-3 pt-1 pb-2 text-sm font-medium text-yt-text-secondary">You</h3>
            <NavLink v-if="shouldShowHistory" to="/history" :collapsed="collapsed">
                <template #icon><i-fa6-solid-clock-rotate-left /></template>
                History
            </NavLink>
            <NavLink to="/playlists" :collapsed="collapsed">
                <template #icon><i-fa6-solid-list /></template>
                Playlists
            </NavLink>
            <NavLink to="/subscriptions" :collapsed="collapsed">
                <template #icon><i-fa6-solid-users /></template>
                Channels
            </NavLink>
        </section>

        <!-- Explore -->
        <section :class="['p-2', !collapsed && 'border-b border-yt-border']">
            <h3 v-if="!collapsed" class="px-3 pt-1 pb-2 text-sm font-medium text-yt-text-secondary">Explore</h3>
            <NavLink to="/trending" :collapsed="collapsed">
                <template #icon><i-fa6-solid-fire /></template>
                Trending
            </NavLink>
        </section>

        <!-- Account / settings -->
        <section v-if="!collapsed" class="p-2">
            <NavLink v-if="shouldShowLogin" to="/login" :collapsed="collapsed">
                <template #icon><i-fa6-solid-user /></template>
                Sign in
            </NavLink>
            <NavLink v-if="shouldShowRegister" to="/register" :collapsed="collapsed">
                <template #icon><i-fa6-solid-user-plus /></template>
                Register
            </NavLink>
            <NavLink to="/preferences" :collapsed="collapsed">
                <template #icon><i-fa6-solid-gear /></template>
                Settings
            </NavLink>
            <NavLink to="/import" :collapsed="collapsed">
                <template #icon><i-fa6-solid-file-import /></template>
                Import
            </NavLink>
        </section>
    </aside>
</template>

<script setup>
import { computed, h } from "vue";
import { RouterLink } from "vue-router";
import { getPreferenceBoolean } from "@/composables/usePreferences.js";
import { getAuthToken } from "@/composables/useApi.js";

defineProps({
    collapsed: { type: Boolean, default: false },
});

const shouldShowLogin = computed(() => getAuthToken() == null);
const shouldShowRegister = computed(() => shouldShowLogin.value);
const shouldShowHistory = computed(() => getPreferenceBoolean("watchHistory", false));

// Inline NavLink renderer — kept here so SidebarMenu has no extra files to wire up.
const NavLink = {
    props: {
        to: { type: String, required: true },
        collapsed: { type: Boolean, default: false },
        exact: { type: Boolean, default: false },
    },
    setup(props, { slots }) {
        return () =>
            h(
                RouterLink,
                {
                    to: props.to,
                    "active-class": "bg-yt-surface font-medium",
                    "exact-active-class": props.exact ? "bg-yt-surface font-medium" : "",
                    class: [
                        "group flex items-center rounded-[10px] text-yt-text transition-colors hover:bg-yt-surface",
                        props.collapsed ? "h-[74px] flex-col gap-1 px-1 py-3 text-[10px]" : "h-10 gap-6 px-3 text-sm",
                    ],
                },
                {
                    default: () => [
                        slots.icon ? h("span", { class: "text-xl" }, slots.icon()) : null,
                        slots.default ? h("span", {}, slots.default()) : null,
                    ],
                },
            );
    },
};
</script>
