import { getPreferenceBoolean, getPreferenceString } from "./usePreferences.js";

// True when the item is a YouTube live stream (no real duration, not a Short).
export function isLiveStream(video) {
    return video && !video.isShort && (video.duration === 0 || video.duration === null || video.duration < 0);
}

// User toggle: hide live streams from feed / trending / channel grids.
// Default ON because most live items don't play through the proxy reliably.
export function hideLiveEnabled() {
    return getPreferenceBoolean("hideLive", true);
}

// Returns a new array with live streams removed when the preference is on.
export function filterHiddenStreams(videos) {
    if (!Array.isArray(videos)) return videos;
    if (!hideLiveEnabled()) return videos;
    return videos.filter(v => !isLiveStream(v));
}

export async function updateWatched(videos) {
    if (window.db && getPreferenceBoolean("watchHistory", false)) {
        var tx = window.db.transaction("watch_history", "readonly");
        var store = tx.objectStore("watch_history");
        videos.map(async video => {
            var request = store.get(video.url.substr(-11));
            request.onsuccess = function (event) {
                if (event.target.result) {
                    video.watched = event.target.result.currentTime != 0;
                    video.currentTime = event.target.result.currentTime;
                }
            };
        });
    }
}

export function download(text, filename, mimeType) {
    var file = new Blob([text], { type: mimeType });

    const elem = document.createElement("a");

    elem.href = URL.createObjectURL(file);
    elem.download = filename;
    elem.click();
    elem.remove();
}

export function getHomePage() {
    switch (getPreferenceString("homepage", "trending")) {
        case "trending":
            return "/trending";
        case "feed":
            return "/feed";
        default:
            return undefined;
    }
}
