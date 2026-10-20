# Product

<!-- impeccable:product-schema 1 -->

## Platform

macos

(A native macOS menu-bar app built with Flutter, also shipped for Windows as a system-tray app.
Mobile apps are a future plan, so later work may move this to `adaptive`.)

## Users

- Bangladeshi Mac users at work, who want to keep track of the time without looking at a clock.
- Families and elders at home, who like hearing the time spoken in Bangla.
- Fans of the original Bangla Voice Clock for Windows (1998–2002).
- People for whom hearing the time matters more than seeing it, such as low-vision users.
- Future: a mobile app for blind and illiterate people, where the spoken time is the whole
  interface.

## Product Purpose

A free talking clock that announces the time aloud in natural Bangla: "এখন সময় সকাল সোয়া
দশটা". It lives in the menu bar, speaks every 15, 30 or 60 minutes, and stays out of the way.
Success is a clock people leave running all day because it sounds right and never annoys.

## Positioning

It speaks the time the way Bangladeshi people say it: traditional সোয়া / সাড়ে / পৌনে wording,
the part of the day (ভোর, সকাল, দুপুর, বিকাল, সন্ধ্যা, রাত), whole recorded phrases rather than
stitched words, and a voice with a Bangladeshi accent, not a Kolkata one. It is both the modern
successor of the 1998 Bangla Voice Clock (whose original voice ships, with permission, as the
Classic voice) and a fresh product in its own right.

## Operating Context

- Runs all day in the macOS menu bar, with no Dock icon. The menu-bar item shows the time in
  Bangla digits (or a logo), and its menu offers Speak now, mute and the interval.
- A small settings window opens from the menu, and once on first launch.
- Announcements play over whatever the user is doing, often in an office or a family room.

## Capabilities and Constraints

- Voices: "Areeba AI (ElevenLabs)" by Saiful Islam (AI-designed, Bangladeshi accent) and
  "Classic (1998)" by Moshfekah Ferdaus Mahita (the original app's voice, used with permission).
- Styles: traditional (quarter hours) and exact minute ("দশটা বেজে সাত মিনিট", or without
  বেজে, as the 1998 voice spoke). The classic voice only says quarter hours.
- Settings: interval, voice, volume, chime, notification, quiet hours, clock or logo in the menu
  bar, launch at login, light/dark appearance (light by default), and the interface language
  (Bangla by default, English optional).
- Free and open source; announcements work fully offline.
- Alarms and prayer times are planned but postponed.

## Brand Commitments

- Name: "Bangla Voice Clock" leads; "বাংলা ভয়েস ক্লক" follows.
- Credits always shown: the original app by Q A M Khaled Ferdaus, the Classic voice by
  Moshfekah Ferdaus Mahita, and "Developed by Saiful Islam" (github.com/saifulmd0).
- Never credit Claude or any AI assistant as a contributor or author.

## Evidence on Hand

- The two voice packs in `assets/voices/`, and the original app in `Reference/` (study only,
  not redistributed except the permitted voice).
- No testimonials, user counts or press exist; do not invent any.

## Product Principles

1. Sound right first: correct, natural Bangla, the way people actually say the time.
2. Calm by default: it lives in the background and should never startle or nag.
3. Respect the original: its author and voice are honoured, not hidden.
4. Hearing is the interface: everything that matters must work without reading.

## Accessibility & Inclusion

Users include elders and low-vision people, and later blind and illiterate users. Text must stay
large and high-contrast, controls must be clear, and spoken output is the primary channel.
