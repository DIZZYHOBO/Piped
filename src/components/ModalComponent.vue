<template>
    <DialogRoot :open="true" @update:open="onOpenChange">
        <DialogPortal>
            <DialogOverlay class="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm transition-opacity" />
            <DialogContent
                class="fixed top-1/2 left-1/2 z-50 w-min min-w-[20vw] -translate-1/2 rounded-2xl bg-yt-bg p-6 text-yt-text shadow-xl ring-1 ring-yt-border focus:outline-none"
            >
                <DialogClose as-child>
                    <button
                        type="button"
                        class="absolute top-2 right-2 grid size-9 place-items-center rounded-full text-yt-text-secondary hover:bg-yt-surface hover:text-yt-text"
                    >
                        <i-fa6-solid-xmark />
                    </button>
                </DialogClose>
                <slot></slot>
            </DialogContent>
        </DialogPortal>
    </DialogRoot>
</template>

<script setup>
import { DialogClose, DialogContent, DialogOverlay, DialogPortal, DialogRoot } from "reka-ui";

const emit = defineEmits(["close"]);

function onOpenChange(open) {
    if (!open) {
        emit("close");
    }
}
</script>
