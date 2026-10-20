---
name: Bangla Voice Clock
description: A Bangla talking clock for the macOS menu bar, drawn as a dial of dots on a clear morning sky.
colors:
  sky-blue: "#2F74D0"
  sky-blue-night: "#8AB8F5"
  on-sky-night: "#08264D"
  coral: "#FF8A65"
  coral-edge: "#C7471F"
  ink: "#172338"
  ink-night: "#E8EFFA"
  ink-muted: "#4A5A73"
  ink-muted-night: "#A9B7CC"
  section-blue: "#2B5A9E"
  section-blue-night: "#A3BEE6"
  ground: "#F5F9FF"
  ground-night: "#0F1724"
  band: "#E1EEFD"
  band-night: "#172A45"
  tile: "#EEF5FF"
  cloud-white: "#FFFFFF"
  card-night: "#0B121D"
  track: "#E3EBF6"
  track-night: "#1F2D44"
  thumb-night: "#3B5078"
  hairline: "#DCE5F1"
  hairline-night: "#2A3850"
  outline: "#7B8BA4"
  outline-night: "#7E8DA6"
typography:
  display:
    fontFamily: "Hind Siliguri"
    fontSize: "38pt"
    fontWeight: 600
    lineHeight: 1.2
  headline:
    fontFamily: "Hind Siliguri"
    fontSize: "22pt"
    fontWeight: 700
  title:
    fontFamily: "Hind Siliguri"
    fontSize: "16pt"
    fontWeight: 700
  row:
    fontFamily: "Hind Siliguri"
    fontSize: "16pt"
    fontWeight: 500
  body:
    fontFamily: "Hind Siliguri"
    fontSize: "16pt"
    fontWeight: 400
    lineHeight: 1.35
  label:
    fontFamily: "Hind Siliguri"
    fontSize: "15pt"
    fontWeight: 600
  dial-label:
    fontFamily: "Hind Siliguri"
    fontSize: "14pt"
    fontWeight: 600
rounded:
  popup: "8pt"
  card: "14pt"
  tile: "22pt"
  full: "9999px"
spacing:
  xxs: "4pt"
  xs: "8pt"
  sm: "12pt"
  md: "16pt"
  lg: "20pt"
components:
  button-speak:
    backgroundColor: "{colors.sky-blue}"
    textColor: "{colors.cloud-white}"
    typography: "{typography.label}"
    rounded: "{rounded.full}"
    padding: "14pt 22pt"
  button-speak-dark:
    backgroundColor: "{colors.sky-blue-night}"
    textColor: "{colors.on-sky-night}"
  dial-band:
    backgroundColor: "{colors.band}"
    textColor: "{colors.ink}"
    padding: "20pt 0"
    size: "280pt"
  dial-band-dark:
    backgroundColor: "{colors.band-night}"
    textColor: "{colors.ink-night}"
  group-card:
    backgroundColor: "{colors.cloud-white}"
    rounded: "{rounded.card}"
  group-card-dark:
    backgroundColor: "{colors.card-night}"
  segmented-track:
    backgroundColor: "{colors.track}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    padding: "3pt"
  segmented-track-dark:
    backgroundColor: "{colors.track-night}"
    textColor: "{colors.ink-night}"
  segmented-thumb:
    backgroundColor: "{colors.cloud-white}"
  segmented-thumb-dark:
    backgroundColor: "{colors.thumb-night}"
  popup-button:
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.popup}"
    padding: "8pt 8pt 8pt 14pt"
  section-title:
    textColor: "{colors.section-blue}"
    typography: "{typography.title}"
  section-title-dark:
    textColor: "{colors.section-blue-night}"
  text-link:
    textColor: "{colors.sky-blue}"
    typography: "{typography.label}"
  text-link-dark:
    textColor: "{colors.sky-blue-night}"
  logo-tile:
    backgroundColor: "{colors.tile}"
    rounded: "{rounded.tile}"
    size: "96pt"
    padding: "14pt"
---

# Design System: Bangla Voice Clock

## Overview

**Creative North Star: "Dot Dial on Clear Sky"**

The day is a dial of dots on a clear morning sky. The settings window opens on a pale sky band holding the current half of the day as a 12-hour clock face, twelve at the top, with one blue fingertip dot for every announcement the clock will make and a coral dot for now. The day is drawn, not listed. Below the band the window turns quiet and native: an airy blue-white ground, white outlined cards, macOS controls tinted sky blue. The dial is the one loud thing; everything under it stays out of its way.

Density is low and type is large, because the users include elders and low-vision people. Every row uses the same generous 16pt and is ranked by weight. Bangla leads and English follows, both set in Hind Siliguri, so switching language never changes the voice of the page.

The logo is the same dial idea reduced to a clock: twelve dots, the four quarter hours larger, the twelve in coral, two round-capped hands at ten o'clock. It was chosen by the user from four logos (logo C) together with this theme (theme 2 of four), replacing the earlier Alpona Dial world, which read too dark and earthy. One painter draws the logo in the app, the app icon and the menu-bar template, so the icons can never drift from the logo.

**Key Characteristics:**
- A pale sky band holding a 280pt day dial, and nothing else.
- Sky blue for the dial, the logo and every control; coral only for now and the logo's twelve.
- Ink, not white, for every word on the band.
- Fingertip dots are the only ornament: twelve on the logo, one per announcement on the dial.
- One row size (16pt), ranked by weight.
- Native macOS control forms (Cupertino switch and slider, plus a macOS-style segmented control and pop-up button), and option cards for one-of-many choices.
- Flat chrome: depth comes from hairline borders and tonal grounds, not shadows.

## Colors

A clear-sky palette: one confident blue, one warm coral for now, deep blue-black ink on airy blue-white, and a night-sky counterpart for dark mode.

### Primary
- **Clear Sky Blue** (sky-blue): the dial's arcs (at 45% opacity) and announcement dots, the logo's dots and hands, the Speak now fill, switch tracks when on, the chosen option card and its radio, the slider, footer links and the text cursor. White on it holds 4.6:1.
- **Night Sky Blue** (sky-blue-night): the same roles in dark mode, with deep navy ink (on-sky-night) on the filled button (7.4:1).

### Secondary
- **Section Blue** (section-blue / section-blue-night): section titles above each card, a deeper blue than the controls so names read as names, not as things to press (6.5:1 on the light ground, 9.5:1 on the night ground).

### Tertiary
- **Coral** (coral): marks now. The now dot on the dial, ringed in the band colour; the soft halo while the clock speaks; the twelve o'clock dot of the full-colour logo. Nothing else.

### Neutral
- **Deep Ink** (ink): every word in light mode, including the day-part labels and the time on the band (14.9:1 on ground, 13.4:1 on band).
- **Muted Ink** (ink-muted): subtitles such as the style examples, and the next-announcement line in the dial (7.0:1 on white cards).
- **Airy Ground** (ground): the light window background.
- **Pale Sky Band** (band): the dial header band in light mode.
- **Logo Tile** (tile): the app-icon tile and the credits logo tile, in both modes.
- **Cloud White** (cloud-white): card fill and the raised segment in light mode, and the label on the filled button.
- **Track Blue-Grey** (track / track-night): the segmented-control track.
- **Hairline** (hairline / hairline-night): card borders.
- **Outline** (outline / outline-night): switch tracks when off, the pop-up button border and the unchosen radio ring.
- **Night Ground, Night Band, Night Card** (ground-night, band-night, card-night): the dark window background, the dark dial band and the dark card fill, deep night-sky blues.
- **Night Thumb** (thumb-night): the raised segment in dark mode, lifted well clear of the track (ink-night holds 7.0:1 on it).
- **Night Ink** (ink-night) and **Night Muted Ink** (ink-muted-night): text on dark surfaces.

### Named Rules
**The One Blue Rule.** Sky blue is the only colour a control, a dot or a hand may take. Section titles use a deeper blue; nothing else competes.

**The One Coral Rule.** Coral marks now, and the twelve on the logo. It never fills a control, never sets text and never decorates.

**The Ink On Sky Rule.** The band is pale and its words are ink. Blue is for what is drawn on it (arcs, dots), ink for what is read on it (time, day parts, next announcement).

## Typography

**Display Font:** Hind Siliguri (bundled; Regular, Medium 500, SemiBold 600, Bold 700)
**Body Font:** Hind Siliguri
**Label Font:** Hind Siliguri

**Character:** One family for Bangla and Latin alike, with a clear Bangla matra and open Latin forms, so a mixed line such as a voice name never changes voice mid-row.

### Hierarchy
- **Display** (600, 38pt, 1.2): the time inside the dial, in ink, scaled down to fit the open centre when needed.
- **Headline** (700, 22pt): the app name on the credits page.
- **Title** (700, 16pt): section titles above each grouped card, in section blue.
- **Row** (500, 16pt): row titles in cards (switches, radios, choice labels).
- **Body** (400, 16pt, 1.35): subtitles, credit details, and the next-announcement line in the dial (1.3 there, muted ink).
- **Label** (600, 15pt): segmented-control options, footer links and the pop-up button; the Speak now button sets it at 16pt.
- **Dial Label** (600, 14pt): the six day-part names around the ring, in ink.

### Named Rules
**The One Row Size Rule.** Every row is 16pt. Rank comes from weight (700 section, 500 title, 400 subtitle) and colour, never from shrinking text. Nothing a user reads in the settings goes below 14pt.

## Layout

A single scrolling column in a 480pt-wide window (minimum 420pt). The dial band runs edge to edge, 20pt above and below a 280pt dial box. The box is 280pt because the day-part labels sit outside a ring of about 240pt and need that room at the 480pt window width. The time and next announcement sit in the open centre, inset 64pt from the box sides. The Speak now button sits centred 16pt under the band.

Under it, content is inset 20pt from the window edges. Each settings group is a section title (8pt in, 4pt above the card) over a full-width outlined card, with 12pt between groups. Rows are standard list rows; a choice row puts its label above a full-width segmented control (16pt sides, 12pt top and bottom, 8pt between label and control). The footer centres two text links split by a middle dot, 12pt below the last card. Spacing steps are 4, 8, 12, 16 and 20pt.

Credits is a page pushed over the settings with a back button, not a modal: a 96pt logo tile, the app name 12pt below, then 16pt to one card of credit rows, with external links marked by an open-in-new icon.

## Elevation & Depth

The chrome is flat. Cards have no shadow (elevation 0) and separate from the ground by a hairline border and a lighter (or, at night, deeper) fill. The only control shadows are the switch knob the system draws and the raised thumb of the segmented control, which carries one soft shadow (offset 0,1, blur 3, black at 12% in light and 30% at night), never a hard ledge. Two drawn exceptions belong to the brand marks: the coral halo that blurs around the now dot while the clock speaks, and the soft drop shadow under the app-icon tile, following Apple's icon grid.

### Named Rules
**The Flat Chrome Rule.** Settings surfaces never take a custom shadow. Depth is tonal: ground, card, track, thumb.

## Shapes

Gently rounded containers: grouped cards at 14pt with a 1pt hairline; pop-up buttons at 8pt; the credits logo tile at 22pt on 96pt. The app icon is a rounded square at 80.47% of the canvas with a corner of 18.07% (Apple's 824/1024 grid), the mark at 62% of the canvas. Buttons are stadiums. Every brand form is a circle: dots, the dial's ring, the now dot, the logo's hub, round-capped hands.

The logo (one painter, three uses) keeps its geometry and changes its drawing by size:
- **Full colour** (credits tile, app icon above 64px): twelve dots on a ring at 80% of the radius, quarter-hour dots larger (10% of radius) than the others (6.2%), the twelve in coral; minute hand to twelve (50% of radius), hour hand to ten (36%), stroke 12% of radius with round caps, a hub dot at the centre.
- **Small icon** (64px and below): the same, drawn 1.25x heavier.
- **Tiny icon** (32px and below): only the four quarter-hour dots, because the eight small dots blur away. The minute hand stops at 42% of the radius, leaving a clear gap below the twelve dot so the two never merge into one bar, and the hour hand grows to 44% so it stays a hand rather than a smudge beside the hub.
- **Template, 2x** (36px menu bar, and the 18pt Logo segment icon in the app): one colour, no coral, all twelve dots, 1.2x weight.
- **Template, 1x** (18px menu bar): one colour, only the four quarter-hour dots and the tiny-icon hand lengths, 1.45x weight.

### Named Rules
**The Clock First Rule.** The logo must read as a clock before anything else. The hands show 10:00, not 10:08: V-shaped hands read as a tick mark at small sizes.

**The Quarter Dots Rule.** At 32px and below, and in the 1x menu-bar template, the logo keeps only the four quarter-hour dots.

## Components

### Buttons
- **Speak now:** the one filled button. Sky-blue fill with a white label (night blue with navy ink in dark mode), stadium shape, 22pt by 14pt padding, label at 600 16pt, with an outlined speaking-person icon.
- **Text links:** the footer's "Developed by" and "Credits", sky-blue label text, no fill.

### Cards / Containers
- **Corner Style:** 14pt.
- **Background:** cloud white on the airy ground; card-night on the night ground.
- **Shadow Strategy:** none (see Elevation & Depth).
- **Border:** 1pt hairline / hairline-night.
- **Internal Padding:** standard list-row insets; rows sit edge to edge inside the card.

### Segmented Control
A macOS sliding segmented control at full row width: a track-coloured track with 3pt padding, the chosen segment raised as a cloud-white thumb (night thumb in dark mode), labels at 600 15pt in ink, 6pt above and below. A segment may lead with an 18pt icon and a 6pt gap (the template logo for "Logo").

### Switches, Slider
Native Cupertino forms, tinted sky blue. Switch tracks are sky blue when on and the outline colour when off, so an off switch still reads as a switch. The volume slider is the adaptive (macOS) slider behind an outlined speaker icon.

### Option Cards
One-of-many choices (announcement style, voice) are cards, not bare radio rows: each option sits on its own 10pt-radius card, 8pt apart, inset 12pt in the section. Unchosen: Surface Low fill with a 1pt Outline Variant border and a 20pt radio ring (1.5pt Outline). Chosen: sky blue at 8% (16% at night) with a 1.5pt sky-blue border, and a sky-blue disc with an 8pt white centre. An option the voice can't speak is shown at half opacity.

### Pop-up Button
The quiet-hours time picker, built like a macOS pop-up menu rather than Material's underlined dropdown: an outlined 8pt box with the time ("রাত ১১:৩০") and an up-down chevron. It opens a 12pt panel with a hairline border holding two short choices instead of one long list: the 24 hours in a scrolling column ("রাত ১১টা", opened on the chosen hour) and the minutes, five apart, in a 3-by-4 grid (":৩০"). The chosen hour and minute are filled sky blue. Picking an hour keeps the panel open for the minute; picking a minute closes it.

### Day Dial (signature)
The current half of the day (midnight to noon, or noon to midnight) as a 12-hour clock face of dots on the pale sky band, twelve at the top, so the now dot sits where a clock's hour hand would. An earlier 24-hour ring (noon at the top) put 10:20 near the 11 position and was replaced at the user's request. The day-part arcs of that half (ভোর to রাত, cut at noon and midnight) in sky blue at 45% opacity, with small gaps between them; their ink labels sit just outside the dot row, pushed out by half their own extent. One blue dot per scheduled announcement, sized to its spacing so neighbours never merge and each can be counted; dots on the hour are larger. Quiet hours are simply left unpainted. When muted, the dots turn to outlines and never disappear, and the centre says announcements are off. Announcements already made today are dimmed to 35%, so the ones still to come stand out. Now is a coral dot with a deep coral edge (#C7471F, so it holds 3:1 on the pale band), ringed in the band colour and haloed in coral while the clock speaks. The time and the next announcement sit in the open centre.

## Do's and Don'ts

### Do:
- **Do** draw every brand mark from the dot-dial painter, choosing its variant by size: full colour above 64px, 1.25x weight at 64px and below, quarter dots only at 32px and below, template at 1.2x in the 2x menu bar and 1.45x with quarter dots only at 1x.
- **Do** keep the logo's hands at 10:00, minute hand to twelve, hour hand to ten.
- **Do** keep every settings row at 16pt and rank by weight: 700 for section titles, 500 for row titles, 400 for subtitles.
- **Do** tint every control sky blue (#2F74D0 light, #8AB8F5 dark) and use native macOS forms: Cupertino switch, adaptive slider, sliding segmented control, option cards, pop-up button.
- **Do** set every word on the band in ink, and draw only arcs and dots in blue.
- **Do** make every dial dot a real announcement; muted turns dots to outlines, quiet hours leave the ring bare.
- **Do** open secondary content such as credits as a pushed page with a back button.

### Don't:
- **Don't** put a list, a clock-face icon or any second element in the header band; the dial owns it.
- **Don't** use coral for anything but now and the logo's twelve, or any colour but sky blue for a control.
- **Don't** give the logo V-shaped hands (such as 10:08); at small sizes they read as a tick mark.
- **Don't** add ornament to the settings chrome; dots are the only ornament, and they live in the dial and the logo.
- **Don't** give cards or controls custom shadows; separate them with hairlines and tone.
- **Don't** shrink text to create hierarchy, or set any settings text below 14pt.
- **Don't** use Material's underlined dropdowns or filled segmented buttons where a macOS form exists.
- **Don't** open credits in a modal dialog.

## Settings that shape the look

- **Appearance:** Light (the default, the look the brand was designed in), Dark, or Match Mac. The window's title bar follows the same choice.
- **Look group** sits first under Speak now: appearance, then what the menu bar shows (time or logo).
- **A voice that only says quarter hours** (the classic voice) disables "মিনিট ধরে" and explains why in a note row (an info icon and one line of muted text inside the group). Style examples always show what the chosen voice really says.

