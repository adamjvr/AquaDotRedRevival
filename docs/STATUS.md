# AquaDotRedRevival Status

**Current milestone:** Phase 4 — Authenticity Closure
**Tested baseline entering closure:** `a5795e1` (Phase 4H provenance)
**Primary runtime target:** native macOS
**Shared platform target:** iPadOS

## Working

- All **205 recovered standard mazes** are bundled and CRC-verifiable.
- Fixed-step topology, collisions, same/adjacent-side wraps and automatic progression work.
- Original and Remastered graphics modes share gameplay state/coordinates.
- Campaign selection uses the recovered weighted family/variant structure with deterministic Revival RNG.
- Persistent campaign save/resume, Game Over, end-level accounting and high-score tables are live.
- Original executable Skill scoring is integrated.
- The ordinary eight-strategy roster is live: Hunter, Blocker, Sneaker, Hound Dog, Lone Wolf, Hermit, Protector and Mantis.
- Protector/Mantis/Hermit use binary-backed advanced state/timing behavior where recovered.
- Neon is an appearance substitution over the underlying strategy, matching the executable architecture.
- **Reaper/Night enemy generation is restored**, including full-version availability gating and the 50/50 Hunter-vs-random strategy split.
- Reaper uses reconstructed runtime composites derived from the preserved `Night-Bugs`, alpha and wing component sheets; reconstructed assets are labeled as such.
- Shared enemy warp behavior now uses recovered style multipliers rather than guessed post-warp delays.
- Infection/cure propagation now follows the recovered orthogonal per-dot wave topology.
- Original recovered audio uses persistent pooled AVAudioEngine playback.
- The Phase 4H spotted main-menu AquaDot and README runtime screenshot are preserved.

## Explicit remaining boundaries

- historical absolute velocity unit → modern cells/second mapping;
- complete legacy infection timing formula;
- libc-rand bitstream/seed identity;
- several lower-level advanced-AI chooser details translated onto the cached graph;
- original high-score name-entry interaction;
- broad physical-device iPadOS regression and release hardening.

## Next major phase

After Phase 4 authenticity closure survives native regression/soak testing, **Phase 5** is release/platform hardening. **Phase 6** is the native editor revival.
