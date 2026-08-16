# Phase 3 — Campaign Authenticity Architecture

Phase 3 starts where the 2.1.x stabilization line leaves off: the core game is playable and stable enough that the next errors are no longer "can we run a recovered maze?" but "does a complete run behave like AquaDot!red?"

This first Phase 3 build restores four pieces of the original campaign shell that were still conspicuously absent: **Game Over, end-level score accounting, beginning-of-level autosaves, and persistent high scores.** It also adds campaign-wide and wall-atlas audit tools so later reverse-engineering work has a hard regression boundary.

## Source-of-truth rules restored

The shipped strategy guide explicitly states:

- exhausting Energy costs a life;
- when AquaDot is out of lives, **the game ends**;
- at the end of a level, **Bonus + Skill** is multiplied by the current **Multiplier**, and that total is added to Score;
- Bonus is therefore a level-end accumulator, not a value that should blindly leak into the next maze.

Recovered `Opening.cc` strings also describe the old auto-save behavior:

- a save made mid-level resumes from the **beginning of that level**;
- a save made after the level is finished resumes from the **beginning of the next level**;
- starting a new game erases the old auto-save.

Phase 3 implements those semantics without turning the save file into a modern save-state of every bug and dot.

## Campaign data flow

```text
New Game
   │
   ├─ clear old autosave
   ▼
begin level checkpoint
   │
   ▼
AquaDotGameSimulation
   │
   ├─ lives reach zero ───────────────► Game Over
   │                                     │
   │                                     ├─ record durable high score
   │                                     └─ erase autosave
   │
   └─ required dots cleared
          │
          ├─ calculate Skill
          ├─ (Bonus + Skill) × Multiplier
          ├─ add award to Score
          ├─ save NEXT-level checkpoint immediately
          ▼
     recovered tween-level presentation
          │
          ▼
       next maze
```

The immediate next-level checkpoint is important. If the process exits while the tween screen is visible, Resume should enter the next maze, not replay the maze that was already cleared.

## Skill scoring provenance

The strategy guide gives the **factors and their direction**, but not all of the original numeric weights. Phase 3 therefore introduces `AquaDotSkillScoring` as one deliberately isolated reconstruction point.

Evidence-backed factors currently represented include:

- uneaten Munch dots increase Skill;
- uneaten Yuk dots increase Skill;
- eating at least one bug per Munch increases Skill;
- leaving special power and not activating Yummy increase Skill;
- eating all goodies or none increases Skill, with none favored;
- damage and deaths reduce Skill.

The current relative numeric weights are **provisional reconstruction constants**. They are not presented as recovered original constants. As stronger binary evidence is decoded, one file can be corrected without rewriting gameplay.

The five recovered end-level quality families are represented directly:

```text
yuk
okay
good
very good
wow / best
```

These correspond to recovered `tween_yuk`, `tween_okay`, `tween_good`, `tween_veryGood`, and `tween_wowBest` audio/resource naming and the five visual bands in `End-Level-Exclaims`.

## Persistence boundary

`AquaDotCampaignStore` persists only:

- current/next level index;
- score at the beginning of that level;
- multiplier;
- lives;
- levels cleared.

It deliberately does **not** persist:

- remaining dots;
- player position;
- bug positions;
- active powers;
- energy;
- current level Bonus.

That is intentional fidelity to the recovered beginning-of-level resume behavior.

`AquaDotHighScoreStore` separately keeps a bounded durable score history and reconstructs the original **Today's Best** / **Best Scores Ever** split.

## Renderer authenticity work

The exact solid-wall renderer is still an active Phase 3 reverse-engineering target. The original `_drawMazePiece` path is now documented as a four-atlas system:

- `9w x 9h`
- `10w x 9h`
- `9w x 10h`
- `10w x 10h`

plus the already-mapped `(lines)` atlas.

`tools/aquadot_wall_piece_audit.py` inventories the recovered atlases directly from the preserved graphics archive. **This build does not falsely claim that the full `mazePieceIndex[4]` selection table has been solved.**

## Phase 3 regression boundary

`tools/aquadot_campaign_audit.py` validates the complete recovered standard corpus:

- 205 maze files;
- exact CRCs;
- dimensions;
- connected traversable graph;
- four bug starts per maze;
- wrap pairing and inward exits;
- recovered 41 groups × 5 variants structure;
- wall-token corpus totals.

The point is to make preservation invariants cheap to rerun every time campaign logic or rendering changes.
