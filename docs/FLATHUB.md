# Publishing on Flathub

[Flathub](https://flathub.org) is the main app store for Linux: it comes built in on Fedora,
Linux Mint, Pop!_OS, elementary OS, Zorin OS and KDE (Discover), and is one setup step away on
Ubuntu. Apps from it install with one click and update on their own.

Everything Flathub needs is in this repository:

| File | What it is |
|---|---|
| `linux/flatpak/io.github.saifulmd0.BanglaVoiceClock.yml` | The Flatpak manifest. CI builds it on every push (the **Build Flatpak** job). |
| `linux/packaging/io.github.saifulmd0.BanglaVoiceClock.metainfo.xml` | The store listing: name, summary, description, screenshots, releases. |
| `linux/packaging/io.github.saifulmd0.BanglaVoiceClock.desktop` | The app's launcher entry. |
| `linux/packaging/icons/` | The app icon (128–512 px) and the panel icon. |
| `tool/linux/flathub_manifest.sh` | Writes the Flathub copy of the manifest for a release. |

The app ID, `io.github.saifulmd0.BanglaVoiceClock`, is tied to the GitHub account, so Flathub
verifies it through GitHub with no domain needed.

## Before submitting

- **Make the repository public.** The listing's screenshots load from
  `raw.githubusercontent.com`, and Flathub reviewers read the source.
- **Choose a licence.** The metainfo says `LicenseRef-proprietary` until a `LICENSE` file is
  added; change `<project_license>` to match (for example `MIT` or `GPL-3.0-or-later`).
- **Publish a release** with the Linux files (pushing a `v*` tag does it), and add it to the
  metainfo's `<releases>`.

## Submitting (once)

Follow [Flathub's submission guide](https://docs.flathub.org/docs/for-app-authors/submission).
In short:

1. Fork [flathub/flathub](https://github.com/flathub/flathub) and branch from `new-pr`.
2. Add the manifest for the release, written by:

   ```sh
   tool/linux/flathub_manifest.sh v0.4.0 > io.github.saifulmd0.BanglaVoiceClock.yml
   ```

3. Add Flathub's shared modules, which the manifest uses:

   ```sh
   git submodule add https://github.com/flathub/shared-modules.git
   ```

4. Open a pull request against `new-pr` titled "Add io.github.saifulmd0.BanglaVoiceClock".
   Reviewers build it, check the listing and permissions, and may ask for changes.
5. Once merged, Flathub creates `github.com/flathub/io.github.saifulmd0.BanglaVoiceClock` and
   gives you access to it, and the app appears on flathub.org within a few hours.

## Each new version

Flathub's bot watches nothing here by default, so after each release:

```sh
tool/linux/flathub_manifest.sh v0.5.0 > io.github.saifulmd0.BanglaVoiceClock.yml
```

then commit that to the Flathub repository (a pull request builds it first). Remember to add the
release to the metainfo here before tagging, since the tarball carries it.

## Why these permissions

| Permission | Why |
|---|---|
| `--socket=pulseaudio` | To speak (PulseAudio, or PipeWire's stand-in for it), and to list outputs for **Play through**. |
| `--talk-name=org.kde.StatusNotifierWatcher` | The panel (tray) icon and its menu. |
| `--system-talk-name=org.freedesktop.login1` | To hear when the computer wakes, so the next announcement is on time. |
| `--socket=wayland`, `--socket=fallback-x11`, `--share=ipc`, `--device=dri` | The window. |

There is no network permission: the Flatpak leaves update checks to Flathub. Opening at login
goes through the Background portal, which asks the user the first time.
