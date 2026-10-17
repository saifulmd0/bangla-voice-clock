---
version: 1
slug: "lib-ui-settings-page-dart"
primary_target: "lib/ui/settings_page.dart"
related_targets: ["macos/Runner/Assets.xcassets"]
---

# Settings window and brand

Scope: the macOS settings window (Operate mode), the app icon and the menu-bar logo.
Audience: Bangladeshi Mac users at work, families and elders, fans of the 1998 app, people who rely on hearing the time.
Task: see when the clock will speak today, change how and when, hear it, and leave.
Constraints: native-feeling controls; Bangla first, English optional; large, high-contrast text for elders; credits always reachable.

## Direction contract

THESIS: The window owns the day as a dial of dots: today's schedule drawn, not listed, on a clear morning sky. It refuses both the grey grouped-list utility and the heavy earth palette of the first round, which the user found too dark; the logo must read as a clock first.

OWN-WORLD: Clear-sky blue (#2F74D0; #8AB8F5 at night) for the dial, the logo and every control; coral (#FF8A65) only for now and the twelve o'clock dot; ink #172338 on an airy #F5F9FF ground with white cards in light, a deep night-sky ground in dark. Hind Siliguri for Bangla and Latin. Fingertip dots are the only ornament: twelve on the logo, one per announcement on the dial.

STORY: The user understands at a glance when the clock speaks today, trusts it to stay quiet when asked, and sets it once.

FIRST VIEWPORT: A pale sky band (#E1EEFD) holds a 280pt dial box: a 24-hour ring with noon at the top, six day-part arcs labelled ভোর to রাত in ink, one blue dot per scheduled announcement, quiet hours left unpainted, a coral dot at now that glows while speaking; the time and next announcement sit inside in ink. Speak now sits under the band, then native grouped rows at one generous type size.

FORM: Dot Dial on Clear Sky, chosen by the user from a variants page (logo C, theme 2) after the Alpona Dial round (seed a0750fff). Logo: twelve dots, quarter hours larger, coral twelve, hands at ten o'clock; small icons keep the quarter dots only.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
