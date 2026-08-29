# CARBO visual direction

The active visual target is the `pilot_v2_2026-08-18` concept set.

## Palette

- Void `#090711`: world/UI negative space
- Ink `#17101f`: card and character cutout bodies
- Paper `#fff0d7`: text, faces, and high-readability cores
- Magenta `#f20b88`: primary attacks, health, major framing
- Cyan `#08c8cf`: friendly utility and deliberate print misregistration
- Acid yellow `#f4df19`: focus, countdown, active combo card
- Violet `#6735d9`: secondary enemy and occult accents

## Shape rules

- Prefer blunt polygons, jagged low-segment arcs, and uneven 2–5 px outlines.
- Use at most one hard inner color field; avoid soft gradients and material rendering.
- Offset cyan or magenta copies by 3–7 px to mimic cheap screen-print registration.
- Halftone and hatch fields must remain sparse enough to preserve combat readability.
- Active UI state uses yellow; failure uses danger pink; disabled state loses saturation.

## Motion rules

- Combo cards enter as one group from the right, then settle with alternating tilt.
- The active card jumps upward and rotates briefly before being crossed out.
- Combat impacts use short-lived starbursts and broken radial strokes, not soft bloom.
- Telegraphs use segmented countdown arcs and remain readable for their full duration.

The shared implementation lives in `res://ui/ArtDirection.gd` and `res://ui/ZineBackdrop.gd`.

