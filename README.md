# Audio Device Restorer

When OBS silently switches an audio device, restore your saved setup with **one click or a hotkey** — including volume, mute and (optionally) the filter settings, including VST plugin settings (the VST plugin itself is not backed up).

> Tested on: OBS Studio 32.2.2, Windows 11. Languages: EN / JP / KR / ID / FR / TW (selector at the top of the settings).
> Version 1.3.0 · Author: BlackDream feat. ChromeBread

The settings are organised into framed groups: **Presets · Items to restore · Auto-save slots · Automation · Filters (VST settings) · Dock · Move presets to another PC**. (OBS scripts cannot color group backgrounds, so groups are shown as titled boxes.)

## Screenshots

|Script 1/2|Script 2/2|Privacy Check|日本語 "Show file paths..." "Help" CustomBrowserDock|
|---|---|---|---|
|![](https://github.com/user-attachments/assets/831bded3-3206-4c13-b644-657b248e7b94)|![](https://github.com/user-attachments/assets/1dd3068a-8b59-47c5-b8b4-8c9f9b870fdf)|![](https://github.com/user-attachments/assets/3eab24d1-8c79-4d9a-a7d0-82ee7090e88a)|![](https://github.com/user-attachments/assets/5ecc202b-d9a4-4570-b8d9-eadfa07a32b0)|

## What is saved

All *Audio Input Capture* and *Audio Output Capture* sources (including the global Desktop Audio and Mic/Aux) and the audio device of **Video Capture Device** sources (including the "use custom audio device" switch and output mode). For each source the preset stores:

- Device
- Volume
- Mute
- Balance
- Monitoring type
- Sync offset
- Filters (the filter chain including **VST plugin settings** — not the VST plugin itself)

## Items to restore

In the **Items to restore** group you tick exactly what a restore changes. Everything is ticked by default except **Filters**:

| Checkbox | What is restored |
|---|---|
| Audio device | The selected device (and the Video Capture Device "custom audio device" switch / output mode) |
| Volume | Fader volume |
| Mute | Mute on/off |
| Balance | Left / right balance |
| Monitoring type | Monitor off / monitor only / monitor and output |
| Sync offset | Audio sync offset |
| Filters | **OFF by default.** Restores the source's filter chain (including VST **settings**) saved in the preset. Filters that are not in the preset are removed from that source. |

## Setup

1. In OBS open **Tools → Scripts → ＋** and select `audio_device_restorer.lua`.
2. Set your sources up the way you want (choose **specific devices** rather than "Default", which follows the Windows default device and changes with it).
3. In the **Presets** group enter a **preset name** (e.g. `Streaming`) and click **Save current state**.
4. Whenever devices change, click **▶ Restore preset**.

### Hotkey

Open **Settings → Hotkeys** and assign a key to **"Restore audio devices (Audio Device Restorer)"**. You can also bind it to a Stream Deck button.

## Other features

| Feature | Description |
|---|---|
| Multiple presets | Save as many named presets as you like (`Streaming`, `Gaming`, `Call`, ...) |
| Check differences | Shows differences between the current devices and the saved preset |
| Auto-restore on change | Checks every 3 s and restores automatically if a device differs (off by default) |
| Auto-restore on OBS start | Restores 3 s after OBS finishes loading (off by default) |

## Auto-save slots (undo for accidental saves)

Before a preset is lost, the script automatically keeps a copy in one of **9 auto-save slots**. A slot is created just before:

- **Save current state** overwrites an existing preset,
- **Delete preset** removes a preset,
- **Import presets** overwrites a preset with the same name,
- **Recover** replaces a preset (so even a recovery can be undone).

Each slot title starts with a timestamp, e.g. `2026-10-18 14:05:33  Streaming`. Only the **latest 9** slots are kept; the oldest is dropped automatically.

To undo a mistake: pick the slot in the **Auto-save slots** drop-down, then click **Recover from auto-save slot**. The preset is restored under its original name. Slots are stored in `audio_device_presets.json` and are listed in the dock as well.

## Filters (VST settings)

Presets already contain each source's filters (applied when **Filters** is ticked in *Items to restore*). The **Filters (VST settings)** group additionally lets you move filter settings by themselves:

1. **Export filter settings** — choose a `.json` file in *Export to* and click the button. Every audio source that has at least one filter is saved, including the settings of VST plugins.
2. **Import filter settings** — choose the file in *Import from* and click the button. Filters are applied to the sources **with the same name** (existing filters of those sources are replaced).

**Only the settings are saved — the VST plugin itself (the plugin files) is NOT backed up.** The same VST plugin must be installed on the target PC (for VST 2.x also at the same plugin path) for an imported filter to work. Requires an OBS version that provides the filter backup API; otherwise a message is written to the Script Log.

## Privacy: file paths are hidden by default

Folder and file paths can reveal personal information (for example your Windows user name) when your screen is shared. Therefore these are **hidden every time the settings are opened**:

- the export / import file fields (filters and presets),
- the Dock URL,
- the folder shown in the Help text.

Click **Show file paths…** (below the language selector). A *Privacy check* box asks whether to show them and reminds you to check that you are **not streaming or recording**. If streaming or recording is active, it says so and the button changes to **Show anyway (LIVE)**. Click **Hide file paths** to hide them again.

Messages in the Script Log never contain folder names — only file names. The hiding applies to this script's settings screen; the operating system's file-chooser window (**Browse**) naturally shows paths.

## Show presets in an OBS dock

The script generates `audio_presets_dock.html`, which lists every saved preset (source, device name, volume, mute, number of filters) and the auto-save slots. For the selected preset, rows whose device differs from the current one are highlighted in red. It refreshes automatically every 3 s.

1. Copy the text in the **Dock URL** field (hidden until you click **Show file paths…**) of the script settings (`file:///.../audio_presets_dock.html`).
2. In OBS open **Docks → Custom Browser Docks**. (Click **Show file paths…** first to reveal the Dock URL.)
3. Enter a dock name (e.g. `Audio Presets`), paste the URL, and click **Apply**.

The dock is **read-only**. Use the script's buttons or the hotkey to restore.

## Move presets to another PC

1. On the old PC click **Show file paths…**, choose a file in **Export file (.json)** (e.g. on a USB drive) and click **Export all presets**.
2. On the new PC register the same script, choose that file in **Import file (.json)**, and click **Import presets (merge)**. Presets with the same name are overwritten.
3. Select a preset and restore it.

- Device IDs differ between PCs, so devices are matched by **ID first, then by display name**. The same hardware (same display name) is restored correctly; devices that cannot be found are skipped with a warning in the log.
- Sources whose **names do not exist** in the new OBS are skipped. Create sources with the same names first.
- If export / import fails, try a path with only ASCII characters.

## Help button and related files

At the very bottom of the settings there is a small **Help** button. Clicking it shows the version, build date, author and the list of files that belong to this script (the folder is shown only after **Show file paths…**), so you can find them when uninstalling:

| File | Purpose |
|---|---|
| `audio_device_restorer.lua` | The script itself |
| `audio_device_presets.json` | Presets **and** the 9 auto-save slots (one file) |
| `audio_presets_dock.html` | Auto-generated dock page |
| `audio_device_presets.luadata` | Old presets file (only exists if migrated from an old version) |
| *your exported `.json` files* | Wherever you saved them |

All files except the exports are located in the same folder as the script. Hotkey bindings and script settings live inside OBS and disappear when you remove the script from **Tools → Scripts**. If you added the dock, remove it under **Docks → Custom Browser Docks**.

## Notes

- Presets are stored next to the script (git-ignored). Put the script in a folder you can write to.
- If a saved device is not currently connected, restoring that source's device is skipped and a warning is logged.
- With auto-restore on, save the new state first (or turn auto-restore off) when you change devices on purpose.
- Use the **Script Log** button to see messages.
