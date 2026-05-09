# Piped × YouTube 2025-26 — Visual Mockups

Static HTML/CSS mockups exploring how the Piped frontend would feel after
adopting the current YouTube layout language. **These are design references
only** — they don't run the Piped app, hit any API, or affect the Vue source.

## How to view

Either open `mockups/index.html` directly in a browser, or run a static server
from the repo root so the Piped logo (served from `/img/icons/logo.svg`) loads:

```sh
npx serve .
# or
python3 -m http.server 8080
```

Then visit `http://localhost:8080/mockups/`.

## Files

| File | What it shows |
| --- | --- |
| `index.html` | Tour landing — links to every page + theme toggle |
| `home.html` | Recommended grid, sticky chip filter row, Shorts shelf |
| `subscriptions.html` | Channel rail + uploads grouped by Today / Yesterday / This week |
| `trending.html` | Hero spotlight, region picker, ranked grid |
| `watch.html` | Two-column player, action pills, comments, recs rail (sidebar collapses to rail) |
| `channel.html` | Banner, identity row, tabs, featured video, latest videos |
| `search.html` | Filter bar, channel match card, result rows, playlist match |
| `library.html` | Quick links + History + Watch later + Playlists |
| `playlist.html` | Sticky hero panel + ordered video list |
| `styles.css` | All shared design tokens and component styles |
| `shell.js` | Injects top bar + sidebar; handles theme + sidebar toggles |

## Design decisions baked in

- **Dark theme is default**, light variant available via top-right toggle
  (persisted in `localStorage`).
- **YouTube red accents** (`#FF0000`) on the existing **Piped logo** — no logo
  change.
- **Collapsible YT-style sidebar**: 240 px expanded ↔ 72 px rail. Watch page
  defaults to rail to give the player room.
- **Comfortable density**: 340 px-min thumbnail grid, 12 px corner radius,
  generous vertical rhythm.
- **Shorts shelf** on Home (and replicated on Channel page).
- **Watch page** is two-column with right-rail recommendations, matching
  current YouTube.
- **Piped-specific touches preserved**: SponsorBlock pill in player controls,
  "Watch on YouTube" button on the Watch page.

## Next steps

Once the visual direction is approved, the work to port back to the Vue
codebase is roughly:

1. Update `src/app.css` with the tokens from `styles.css` (`--bg`, `--surface`,
   `--brand-red`, etc.) and replace the existing `--color-dark-*` vars.
2. Rewrite `NavBar.vue` to render the sticky top bar + mountable
   collapsible sidebar.
3. Add a new `SidebarMenu.vue` with the three sections (primary / you /
   subscriptions).
4. Restyle `VideoItem.vue`, `ContentItem.vue`, and `ChannelItem.vue` to match
   the card patterns shown here.
5. Restyle `WatchVideo.vue` to the two-column layout and migrate the
   recommendations panel.
6. Add a `ChipsBar.vue` component for the home/trending filter chips.
