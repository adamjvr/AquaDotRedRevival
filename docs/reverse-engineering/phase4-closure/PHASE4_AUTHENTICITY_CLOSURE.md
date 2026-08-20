# Phase 4 Authenticity Closure — Reaper, Shared Enemy Motion, Infection/Cure

This document records what this closure pass treats as **recovered**, what is a **modern translation**, and what remains unresolved. The source of truth is the shipped i386 executable plus preserved game assets and guide material.

## Reaper / Night enemy

### Recovered

- `setupEnemy` treats source colour **8** as a special path before Neon substitution; Reapers are therefore never Neon.
- ordinary enemies initialize legacy velocity field `0xbbc` to float **50000** (`0x47435000`); colour 8 rewrites it to float **10000** (`0x461c4000`). The exact recovered ratio is **0.2**.
- the full-version colour-8 setup draws a 0.5 probability and selects either ordinary Hunter strategy ID **0** or special strategy ID **12**. Thus the shipped Reaper split is 50/50 **Hunter Reaper** vs **Random Reaper**.
- strategy 12's chooser selects a cardinal start direction and scans cyclically for a valid non-reversing direction.
- `createEnemyFileName` maps the Night path to `::Resources:aquadot!red -- Sprites:Bugs:Night-Bugs.png`.
- vulnerable/Munch collision handling occurs before dangerous contact handling, so Reapers remain edible while vulnerable.

### Translation boundary

The original velocity fields are not claimed to be direct cells/second. Revival applies the recovered **0.2 ratio** to its fixed-step base bug velocity. Dangerous Reaper contact is mapped onto Revival's Energy model using the recovered fast-contact/status-transition behavior; this is not labeled a unit-identical port of the old status renderer.

## Shared warp motion

`setEnemyV` writes a `warpStyle`-like field at enemy offset `0xba4`:

- style 1 → `0x3fc00000` = **1.5**
- style 3 → `0x3f000000` = **0.5**
- style 4 → `0x3e800000` = **0.25**

Recovered setup dispatch maps Reaper to 1.5 (the guide's slingshot behavior), Hunter/Blocker/Sneaker/Lone Wolf to 0.5, and Hound Dog/Protector/Mantis/Hermit to 0.25. Phase 4 replaces the old generic/Hermit guessed post-warp pause with these per-segment velocity multipliers.

## Infection / cure propagation

The old Revival used cached maze shortest-path distance to transform all dots in a radius. Binary inspection of the MazeSprouts/MazeDots path shows a different spatial contract: each active infection/cure record considers the four immediate grid neighbors `(x-1,y)`, `(x+1,y)`, `(x,y-1)`, `(x,y+1)` and creates further records from qualifying source dots.

Consequences now restored:

- propagation is **cardinal and per-dot**;
- diagonals require multiple cardinal generations;
- disconnected gaps stop the wave;
- a wrap link does not make two distant grid cells infection-adjacent;
- cure uses the same record/wave topology rather than globally flipping all transformed dots at once.

The exact old per-record timing equation is still not fully reduced. Revival therefore keeps its existing goodie-age/delay envelope but now uses the recovered propagation topology.

## Campaign/RNG audit

Phase 3C's `selectRandomLevel2` reconstruction was rechecked in this pass. The weighted variant table, recent-family rejection window and non-repeat rule remain consistent with the recovered control flow. No speculative rewrite was made merely to increase diff size.

Remaining RNG boundary: the project-local deterministic generators intentionally do not claim libc `rand()` bitstream identity.

## Reaper artwork

The runtime images in this phase are **reconstructed composites**, not recovered flattened historical masters:

- body RGB: preserved `Night-Bugs.png` strip;
- body alpha: preserved `Alpha-Bugs.gif` frame strip;
- wings: preserved `Bug-Wings.gif` phases;
- Original output: 64×64 static composite;
- Remastered output: 512×512 high-resolution derivative using the same source components.

The generator is stored at `tools/aquadot_phase4_generate_reaper_asset.py` for reproducibility.

## Evidence landmarks

- `setupEnemy`: around `0x1d35e`; normal velocity `0x1d7aa`, Reaper velocity `0x1d93f`, 50/50 strategy branch `0x1d998..0x1d9c6`.
- `chooseDirection`: strategy-12 dispatch visible around `0x1c7d3` with the recovered random chooser path downstream.
- `setEnemyV`: warp factors around `0x209cc`, `0x20a2b`, `0x20a3d`.
- `createEnemyFileName`: compilation-unit evidence identifies the Night sprite resource.
- MazeSprouts/MazeDots infection/cure routines: recovered cardinal-neighbor record architecture; see the preserved reverse-engineering archive for raw disassembly.

## Honesty rule

Recovered constants/branch structure are labeled recovered. SpriteKit/fixed-step adapters and unresolved timing/unit mappings remain explicitly labeled translations. This phase does not claim bit-identical original execution.
