# Phase 2 — OG-derived remaster + behavioral reconstruction

Phase 2 sits directly on the Phase 1 original-data runtime. It does **not** replace the recovered maze model, CRC, topology, or fixed-step architecture. It adds the systems that make the running reconstruction look and behave substantially more like the shipped game.

## Runtime graph

```text
205 untouched original mazes
          │
          ▼
  parser / recovered CRC
          │
          ▼
 recovered maze topology
          │
   ┌──────┼───────────┐
   ▼      ▼           ▼
 player  dot system   bug system
   │      │           │
   └──────┼───────────┘
          ▼
 fixed-step simulation
       │         │
       ▼         ▼
 game events   game state
       │         │
       ▼         ▼
 original audio  OG/remaster renderer
       └────┬────┘
            ▼
       macOS + iPadOS
```

## Evidence-backed rules implemented now

The following behaviors come from the shipped strategy guide and/or recovered module/function structure rather than generic maze-game assumptions:

- Normal=10, Candy=50, Crusty=30, Petrified=100, Yummy=250, Yuk=1000, Munch=250.
- Munch dots are optional for level completion.
- Yummy converts nearby required dots to Candy while present.
- Yuk converts nearby dots to Crusty; an uneaten expired Yuk petrifies them, while eating it restores them.
- Yummy powers: Invisible, Untouchable, Quick, Dreamy, Energetic, Scary.
- Yuk powers: Slow, Blind, Sick, Tasty.
- Space/tap activates an available Yummy power; Yuk powers activate immediately.
- Munch makes bugs edible and awards successive 500/1000/2000/4000 bug values.
- Sick/Blind/Tasty/Slow multiply Munch bug values by 2/3/5/10 respectively. Sick blocks every collectible except Yummy/Yuk, matching the guide text.
- multiplier increments to x5 and drops by one after life loss, minimum x1.
- score extra lives at 25k, 75k, 150k, 250k, then every 100k.
- the four original E-H start slots receive a distinct roster drawn from the first four documented/reconstructed color personalities: Hunter, Blocker, Sneaker and Hound Dog; the original binary shows start slot and enemy color/personality are selected separately.
- the bug system navigates the same recovered wrap-aware graph as the player; bugs receive a short reconstructed slowdown through warps and a post-Munch recovery pause, both behaviors explicitly described by the guide.
- Blind fades distant bugs and reveals them as they approach AquaDot; damage uses the documented yellow player/energy pulse.
- Yummy/Yuk active-state colors use the recovered cyan/green/purple/yellow AquaDot underlay frames rather than generic runtime tinting.

## Constants still marked as reconstruction

Exact original values have not yet been binary-matched for every timing constant. They are intentionally centralized instead of being scattered through the engine:

- base player and bug speeds;
- exact special-power drain rate;
- Munch duration;
- goodie spawn interval/lifetime;
- exact infection radius;
- exact energy gain/loss rates;
- exact Blocker/Sneaker targeting distances.

These values can be replaced later without changing file parsing, rendering, or topology.

## Rendering policy

The complete recovered graphics archive remains immutable in `preservation/`. Phase 2 creates runtime derivatives that retain explicit provenance.

- **Player:** recovered underlay + recovered ring/spot masks are composited into five authoritative runtime states (normal red, Munch aqua, Yummy green, Yuk purple, damage yellow); Remastered uses cleaned 4x derivatives of those same states.
- **Bugs:** first four guide-confirmed OG bug composites become transparent runtime sprites; Remastered uses cleaned 4x derivatives.
- **Dynamic dots/goodies:** sliced from recovered game sprite sheets and restored at higher resolution.
- **Walls:** geometry is the exact recovered wall mask. `_drawLineIntersections` was mapped to the exact 4×13 `(lines)`-atlas frame indices, so the renderer overlays the recovered per-theme original frame on top of a scalable layered SpriteKit bevel body. This retains OG junction micro-detail at Retina sizes. The separate 9w/10w piece-selection path is still a later binary-match target.
- **HUD:** retains the recovered 800-pixel original panel and renders dynamic energy/special waves above it.

Original and Remastered modes share **identical gameplay coordinates and simulation**.

## Audio policy

The shipped `.adrs` files are Ogg/Vorbis bitstreams. Phase 2 preserves all 81 original `.adrs` sound bytes in `preservation/aquadot_original_audio_adrs.zip`. Forty-four runtime sounds are decoded losslessly to ALAC `.m4a` for AVFoundation playback on modern macOS/iPadOS, including all six level tracks and every Yummy/Yuk ability start+loop pair. No lossy transcode is introduced.

## Controls

### Mac

- Arrows / WASD — movement
- Space — activate available Yummy power (original behavior)
- P or Escape — pause
- `[` / `]` — previous/next recovered standard maze
- `O` — Original graphics mode
- `R` — Remastered graphics mode
- backtick — preservation/debug overlay

### iPad

- swipe — movement
- tap — activate available Yummy power
- hardware keyboard mirrors Mac movement/Space/P/Escape

## Debug overlay

The overlay retains raw wall-mask display and now reports live player, dot, Munch and bug personality/mode/node state. This exists specifically to support later original-binary behavioral matching.
