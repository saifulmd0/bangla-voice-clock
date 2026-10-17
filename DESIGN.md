---
name: Bangla Voice Clock
description: A Bangla talking clock for the macOS menu bar, drawn as an alpona of rice-paste line on fired earth.
colors:
  earth: "#9C3D26"
  earth-deep: "#7A2E1C"
  rice: "#F6F0E4"
  turmeric: "#E2A12B"
  leaf: "#2F6B3F"
  soot: "#231A16"
  rice-ground: "#FAF5EC"
  card-light: "#FFFDF8"
  track-light: "#EBE1D1"
  hairline-light: "#E2D5C3"
  outline-light: "#9C8878"
  ink-muted: "#5E4B40"
  earth-dark-ground: "#1C1310"
  card-dark: "#160F0C"
  track-dark: "#33251E"
  thumb-dark: "#5A463B"
  hairline-dark: "#3E2F26"
  outline-dark: "#8F7A6B"
  ink-night: "#F3EADC"
  ink-muted-night: "#CDB9A8"
  leaf-night: "#8CC79A"
  leaf-night-ink: "#0E2A16"
  earth-night: "#E08A6F"
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
    backgroundColor: "{colors.leaf}"
    textColor: "#FFFFFF"
    typography: "{typography.label}"
    rounded: "{rounded.full}"
    padding: "14pt 22pt"
  button-speak-dark:
    backgroundColor: "{colors.leaf-night}"
    textColor: "{colors.leaf-night-ink}"
  dial-header:
    backgroundColor: "{colors.earth}"
    textColor: "{colors.rice}"
    padding: "20pt 0"
    size: "280pt"
  dial-header-dark:
    backgroundColor: "{colors.earth-deep}"
    textColor: "{colors.rice}"
  group-card:
    backgroundColor: "{colors.card-light}"
    rounded: "{rounded.card}"
  group-card-dark:
    backgroundColor: "{colors.card-dark}"
  segmented-track:
    backgroundColor: "{colors.track-light}"
    textColor: "{colors.soot}"
    typography: "{typography.label}"
    padding: "3pt"
  segmented-thumb:
    backgroundColor: "{colors.card-light}"
  segmented-thumb-dark:
    backgroundColor: "{colors.thumb-dark}"
  popup-button:
    textColor: "{colors.soot}"
    rounded: "{rounded.popup}"
    padding: "8pt 8pt 8pt 14pt"
  section-title:
    textColor: "{colors.earth}"
    typography: "{typography.title}"
  section-title-dark:
    textColor: "{colors.earth-night}"
  text-link:
    textColor: "{colors.leaf}"
    typography: "{typography.label}"
---

# Design System: Bangla Voice Clock

## Overview

**Creative North Star: "The Alpona Dial"**

The whole world is alpona: a rice-paste line drawn on fired earth. The settings window opens on a terracotta band holding today as a ring, noon at the top and midnight at the bottom, with one rice-white dot for every announcement the clock will make. The day is drawn, not listed. Below the band the window turns quiet and native: warm rice ground, outlined grouped cards, macOS controls tinted leaf green. The dial is the one loud thing; everything under it stays out of its way.

Density is low and type is large, because the users include elders and low-vision people. Every row uses the same generous 16pt and is ranked by weight alone. Bangla leads and English follows, both set in Hind Siliguri, so switching language never changes the voice of the page.

The same rosette, a twelve-petal alpona with one petal per hour and the top petal lit in turmeric, is the logo, the app icon and (as a one-colour template) the menu-bar mark. It is drawn in code by one painter, so the icons can never drift from the logo in the app.

**Key Characteristics:**
- A fired-earth header band holding a 280pt day dial, and nothing else.
- Rice-white line on earth for every brand surface; turmeric only for "now" and the lit petal.
- Leaf green is the one control accent.
- One row size (16pt), ranked by weight.
- Native macOS control forms (Cupertino switch, slider, sliding segmented control, radio, pop-up button).
- Flat chrome: depth comes from hairline borders and tonal grounds, not shadows.

## Colors

An earthen palette of terracotta, rice paste, turmeric and leaf, warm in both light and dark.

### Primary
- **Fired Earth** (earth): the ground of the dial header band in light mode, the app-icon tile and the credits logo tile. Section titles use it as ink on the rice ground (6.2:1).
- **Banked Earth** (earth-deep): the dial header band in dark mode. Full fired earth glares next to the near-black dark ground at night, so the band drops to this deeper fire; rice text holds about 8.3:1 on it.
- **Rice Paste** (rice): every line, dot, label and number drawn on earth: dial arcs (at 75% opacity), announcement dots, day-part labels, the clock and next-announcement text, the rosette's petals.

### Secondary
- **Leaf** (leaf): the single control accent in light mode: the Speak now button, switch tracks when on, the chosen radio, the slider, footer links, the text cursor.
- **Night Leaf** (leaf-night): the same role in dark mode, with dark leaf ink (leaf-night-ink) on the filled button (7.9:1).

### Tertiary
- **Turmeric** (turmeric): marks now. The now dot on the dial (ringed in earth), the soft halo while the clock is speaking, and the top petal of the full-colour rosette. Nothing else.

### Neutral
- **Soot** (soot): body ink on the light ground (15.7:1).
- **Rice Ground** (rice-ground): the light window background.
- **Card Rice** (card-light): grouped-card fill and the segmented thumb in light mode.
- **Track Sand** (track-light): the segmented-control track in light mode.
- **Hairline Sand** (hairline-light): card borders in light mode.
- **Warm Outline** (outline-light / outline-dark): off switch tracks and the pop-up button border; mixed with the card colour for the unchosen radio ring.
- **Muted Earth Ink** (ink-muted): subtitles such as the style examples (7.6:1).
- **Night Earth** (earth-dark-ground): the dark window background, a near-black brown.
- **Night Card / Track / Thumb / Hairline** (card-dark, track-dark, thumb-dark, hairline-dark): the dark counterparts of the card, segmented track, raised segment and border.
- **Night Rice Ink** (ink-night) and **Night Muted Ink** (ink-muted-night): text on the dark ground.
- **Night Earth Ink** (earth-night): section titles in dark mode.

### Named Rules
**The Rice-On-Earth Rule.** Brand surfaces are rice line on earth, never the reverse. The dial, the icon tile and the logo tile are earth; what is drawn on them is rice, with turmeric for one thing.

**The One Accent Rule.** Leaf green is the only colour a control may take. Earth names sections; turmeric names now; neither ever fills a control.

**The Night Fire Rule.** In dark mode the earth band drops to earth-deep. Full earth beside the night ground glares.

## Typography

**Display Font:** Hind Siliguri (bundled; Regular, Medium 500, SemiBold 600, Bold 700)
**Body Font:** Hind Siliguri
**Label Font:** Hind Siliguri

**Character:** One family for Bangla and Latin alike, with a clear Bangla matra and open Latin forms, so a mixed line such as a voice name never changes voice mid-row.

### Hierarchy
- **Display** (600, 38pt, 1.2): the time inside the dial, rice on earth, scaled down to fit the ring when needed.
- **Headline** (700, 22pt): the app name on the credits page.
- **Title** (700, 16pt): section titles above each grouped card, in earth ink.
- **Row** (500, 16pt): row titles in cards (switches, radios, choice labels).
- **Body** (400, 16pt, 1.35): subtitles and the next-announcement line in the dial (1.3 there).
- **Label** (600, 15pt): segmented-control options; the Speak now button sets it at 16pt.
- **Dial Label** (600, 14pt): the six day-part names around the ring, rice on earth.

### Named Rules
**The One Row Size Rule.** Every row is 16pt. Rank comes from weight (700 section, 500 title, 400 subtitle) and colour, never from shrinking text. Nothing a user reads in the settings goes below 14pt.

## Layout

A single scrolling column in a 480pt-wide window (minimum 420pt). The dial header band runs edge to edge, 20pt above and below a 280pt dial box. The box is wider than the contract's 240pt because the day-part labels sit outside a ring of about 240pt and need that room at 480pt. The Speak now button sits centred under the band.

Under it, content is inset 20pt from the window edges. Each settings group is a section title (8pt in, 4pt above the card) over a full-width outlined card, with 12pt between groups. Rows are standard list rows; a choice row puts its label above a full-width segmented control (16pt sides, 12pt top and bottom, 8pt between label and control). The footer centres two text links split by a middle dot. Spacing steps are 4, 8, 12, 16 and 20pt.

Credits is a page pushed over the settings with a back button, not a modal: a 96pt earth tile holding the rosette, the app name, then one card of credit rows.

## Elevation & Depth

The chrome is flat. Cards have no shadow (elevation 0) and separate from the ground by a hairline border and a lighter fill. The only shadows are the ones the system draws itself: the raised thumb of the Cupertino segmented control and the switch knob. Two drawn exceptions belong to the brand marks: the turmeric halo that blurs around the now dot while the clock speaks, and the soft drop shadow under the app-icon tile, following Apple's icon grid.

### Named Rules
**The Flat Chrome Rule.** Settings surfaces never take a custom shadow. Depth is tonal: ground, card, track, thumb.

## Shapes

Gently rounded containers: grouped cards at 14pt with a 1pt hairline; pop-up buttons at 8pt; the credits logo tile at 22pt on 96pt. The app icon is a rounded square at 80.47% of the canvas with a corner of 18.07% (Apple's 824/1024 grid). Buttons are stadiums. The day dial is a circle of six arcs with small gaps between them, a row of dots, and a centre left open for the time.

The rosette scales by changing how it is drawn, not just its size:
- **Full** (above 64px): twelve teardrop petals, fingertip dots between the tips, top petal in turmeric.
- **Small** (64px and below): eight petals, heavier line (1.7x), no dots.
- **Template, 2x** (36px menu bar and the in-app segment icon): eight petals, one colour, no accent, 1.5x line.
- **Template, 1x** (18px menu bar): six petals at 2.1x line, because eight read as a cog at that size.

## Components

### Buttons
- **Speak now:** the one filled button. Leaf fill, white label (night leaf with dark leaf ink in dark mode), stadium shape, 22pt by 14pt padding, label at 600 16pt, with an outlined speaking-person icon.
- **Text links:** the footer's "Developed by" and "Credits", leaf text, no fill.

### Cards / Containers
- **Corner Style:** 14pt.
- **Background:** card-light / card-dark on the rice or night ground.
- **Shadow Strategy:** none (see Elevation).
- **Border:** 1pt hairline-light / hairline-dark.
- **Internal Padding:** standard list-row insets; rows sit edge to edge inside the card.

### Segmented Control
A macOS sliding segmented control at full row width: a track-light track with 3pt padding, the chosen segment raised as a card-light thumb (thumb-dark at night), labels at 600 15pt in body ink, 6pt above and below. A segment may lead with an 18pt icon (the template rosette for "Logo").

### Switches, Radios, Slider
Native Cupertino forms, tinted leaf. Switch tracks are leaf when on and the warm outline when off. Radios are leaf when chosen; the unchosen ring mixes the card colour with the outline (35% in light, 55% in dark) so it still shows. The volume slider is the adaptive (macOS) slider behind an outlined speaker icon.

### Pop-up Button
The quiet-hours hour picker, built like a macOS pop-up menu rather than Material's underlined dropdown: an outlined 8pt box with the value and an up-down chevron, opening a 24-item menu with a check by the current hour.

### Day Dial (signature)
Today as an alpona ring on the earth band. Noon at the top, midnight at the bottom. Six day-part arcs (ভোর to রাত) in rice at 75% opacity, with gaps between them; their labels sit just outside the dot row, pushed out by half their own extent. One rice dot per scheduled announcement, sized to its spacing so neighbours never merge and each can be counted; dots on the hour are larger. Quiet hours are simply left unpainted. When muted, the dots turn to outlines and never disappear. Now is a turmeric dot ringed in earth, haloed in turmeric while the clock speaks. The time and the next announcement sit in the open centre.

## Do's and Don'ts

### Do:
- **Do** draw every brand mark from the rosette painter, choosing its variant by size: full above 64px, small at 64px and below, template with eight petals at 2x and six at 1x in the menu bar.
- **Do** keep every settings row at 16pt and rank by weight: 700 for section titles, 500 for row titles, 400 for subtitles.
- **Do** tint every control leaf (#2F6B3F light, #8CC79A dark) and use native macOS forms: Cupertino switch, adaptive slider, sliding segmented control, Cupertino radio, pop-up button.
- **Do** put the dial band on earth-deep (#7A2E1C) in dark mode.
- **Do** make every dial dot a real announcement; muted turns dots to outlines, quiet hours leave the ring bare.
- **Do** open secondary content such as credits as a pushed page with a back button.

### Don't:
- **Don't** put a list, a clock-face icon or any second element in the header band; the dial owns it.
- **Don't** use turmeric for anything but now and the lit petal, or earth for any control fill.
- **Don't** add ornament (dot rows, petals, borders) to the settings chrome; it lives in the dial and the rosette.
- **Don't** give cards or controls custom shadows; separate them with hairlines and tone.
- **Don't** shrink text to create hierarchy, or set any settings text below 14pt.
- **Don't** use Material's underlined dropdowns or filled segmented buttons where a macOS form exists.
- **Don't** open credits in a modal dialog.
