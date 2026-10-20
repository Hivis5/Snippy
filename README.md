# Snippy

A lightweight macOS menu bar app for keeping your terminal commands and snippets one click away.

Snippy lives in your menu bar, opens as a popover, and lets you search, read, and copy your own command cheat sheets written in Markdown. Everything is stored locally on your Mac. No account, no network, no tracking.

<!-- Add a screenshot: ![Snippy screenshot](docs/screenshot.png) -->

## Features

- **Menu bar only:** no Dock icon, no app switcher entry.
- **Global shortcut:** toggle the popover from anywhere with `Option + W`.
- **Fast search:** matches titles, categories, `#tags`, and the full command body.
- **Category filters:** one-tap pills to narrow the list.
- **Markdown entries:** headings, paragraphs, bullet points, blockquotes, and inline formatting.
- **Code blocks with highlighting:** commands, flags, variables, and strings are colored, with a one-click **Copy** button.
- **Add, edit, delete:** manage entries from inside the app (`⌘N` for a new command, right-click an entry to edit or delete).
- **Local first:** data is saved as a single JSON file on your Mac.
- **Zero dependencies:** pure SwiftUI and AppKit.

## Requirements

- macOS 13.0 (Ventura) or later

## Install (using the DMG)

1. Go to the [**Releases**](https://github.com/YOUR_USERNAME/YOUR_REPO/releases) page and download `Snippy.dmg`.
2. Double-click `Snippy.dmg` to open it.
3. Drag **Snippy** into the **Applications** folder.
4. Eject the disk image (optional).
5. Open **Snippy** from Applications. A terminal icon appears in your menu bar.

### First launch: "app can't be opened" warning

Snippy is not notarized by Apple, so macOS may block it the first time you open it. Use either fix below.

**Option A: Terminal (recommended)**

```bash
xattr -cr /Applications/Snippy.app
```

Then open Snippy normally.

**Option B: System Settings**

1. Try to open Snippy once so macOS records the block.
2. Go to **System Settings → Privacy & Security**.
3. Scroll down and click **Open Anyway** next to the Snippy message.

You only need to do this once.

## Usage

| Action | How |
| --- | --- |
| Open or close Snippy | Click the menu bar icon, or press `Option + W` |
| Search | Type in the search bar (supports `#tags`) |
| Filter by category | Click a category pill |
| Copy a command | Click **Copy** on any code block |
| Add a command | Click **Add Command** or press `⌘N` |
| Edit or delete a command | Right-click an entry, or use the pencil icon in the detail view |
| Close the detail view | Click **X** or press `Esc` |
| Dismiss the popover | Hold `Option` and click **X** |
| Quit | Gear icon → **Quit Snippy** |

### Writing an entry

Entries are plain Markdown. Wrap commands in a fenced code block:

````markdown
### Find what's using a port

```bash
lsof -i :<PORT>
kill -9 <PID>
```

- `-i` lists network connections
````

Tip: use `<UPPERCASE>` placeholders for values you need to fill in.

## Where your data lives

Snippy stores your commands in:

```
~/Library/Application Support/QuickCmd/commands.json
```

Back up or sync that file however you like. Delete it to reset Snippy to the starter entry.

## Build from source

1. Clone the repo:
   ```bash
   git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
   cd YOUR_REPO
   ```
2. Open the `.xcodeproj` in Xcode.
3. Select the **Snippy** scheme and run (`⌘R`).

To run as a menu-bar-only app, make sure `LSUIElement` is set to `YES` in the target's Info tab.

## Uninstall

1. Quit Snippy from the gear menu.
2. Delete `Snippy.app` from Applications.
3. Optional: delete `~/Library/Application Support/QuickCmd` to remove your data.


---

Made by **Hitesh Vishal** | A Local First dev initiative
