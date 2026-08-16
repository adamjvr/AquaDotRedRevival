# Phase 3D — Runtime Closure: Names, Controllers, and Campaign Soak

Phase 3D closes three runtime gaps that can be implemented without inventing unrecovered original constants.

## 1. Crash-safe high-score name entry

The recovered original source architecture proves a dedicated high-score-entry state:

- `Opening.cc`: `initHighScoreEntrySprites`, `_highScore_installApplicationEventHandler`, `_highScore_handleApplicationEvent`, `_finishHighScoreEntry`
- `Prefs.cc`: `isThisAtHighScore`, `insertNewHighScore`, `getHighScoreNameAndNumber`, `anonymous`
- `AnimatedText.cc`: high-score sprite initialization, highlight/fade, letter copying, and text copying

Phase 3 previously committed the terminal score immediately as `anonymous`. Phase 3D keeps that crash-safety property: Game Over still writes the score before its 2.5-second presentation finishes. After the presentation, the shell enters a dedicated name-entry route; submitting a name mutates that already-durable record by UUID. If the app is killed before entry, the score remains safely stored as `anonymous` rather than disappearing.

The exact original entry-screen pixel layout, entry length rules, and qualification thresholds have **not** been proved from the material currently integrated into Revival. Therefore the SwiftUI entry panel is explicitly a modern shell around a recovered state transition, not a claim of pixel-identical original presentation.

## 2. Native GameController bridge

The recovered release linked classic HID Utilities and contains `HID_pollJoysticks` / `HID_loadConfig`, proving physical-controller support existed in the original architecture. Phase 3D connects modern Apple `GameController` input to the platform-neutral `AquaDotInputEvent` boundary already used by keyboard/touch/pointer input.

Modern mapping:

- D-pad / left stick: movement
- A / primary button: activate available special power
- B / secondary button: cancel/unpause
- Menu: pause

The mapping is intentionally documented as **Revival reconstruction** because exact historical physical button assignments remain unrecovered. Simulation behavior is unchanged.

## 3. Long campaign and checkpoint soak

`tools/aquadot_phase3d_campaign_soak.swift` compiles directly with production `AquaDotCampaignSelector.swift` and runs all three recovered numeric difficulty modes for a configurable number of selections.

It checks:

- every selected index remains inside the 205-maze catalog;
- all 41 families and all 205 family/variant combinations are eventually visited in each mode;
- the recent-family ring never exceeds 10 entries and contains valid family IDs;
- forbidden immediate repeats of a lower-than-current-maximum variant never occur;
- complete selector state repeatedly survives JSON encode/decode and produces an identical 64-selection future sequence;
- recent-window family repeats are reported, not blindly rejected, because the recovered selector contains an explicit duplicate-rejection escape path.

## Deliberately still unresolved

Phase 3D does **not** fake closure on these reverse-engineering targets:

1. `_drawMazePiece` complete `mazePieceIndex[4]` neighborhood/boundary mapping.
2. Exact historical numeric weights and thresholds for Secret Skill scoring.
3. Remaining advanced bug movement/personality constants not already locked by Phase 3B.
4. Historical UI labels for campaign difficulty modes 0/1/2.
5. Pixel-identical historical high-score entry artwork/interaction details.

Those stay marked as evidence-dependent work rather than receiving plausible-looking invented values.
