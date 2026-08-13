#!/usr/bin/env python3
"""Audit wrap geometry across AquaDot original level datasets.

Phase 2.1.2 regression helper.  Standard-library only; works on macOS and Linux.
It does not modify data.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from pathlib import Path
import sys


def read_maze(path: Path):
    text = path.read_bytes().decode("mac_roman")
    lines = text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    if len(lines) < 9 or lines[0] != "aquadot!red":
        raise ValueError(f"not an aquadot!red maze: {path}")
    width = int(lines[5].split(":", 1)[1].strip())
    height = int(lines[6].split(":", 1)[1].strip())
    grid = lines[8 : 8 + (2 * height + 1)]
    if len(grid) != 2 * height + 1:
        raise ValueError(f"truncated grid: {path}")
    vertices = [row.split() for row in grid[0::2]]
    return width, height, vertices


def boundary_side(x: int, y: int, width: int, height: int):
    if x == 0:
        return "L", (1, 0)
    if x == width:
        return "R", (-1, 0)
    if y == 0:
        return "T", (0, 1)
    if y == height:
        return "B", (0, -1)
    return "?", (0, 0)


def audit(root: Path) -> int:
    mazes = sorted(root.glob("ADL_*.dataset/*.aquadotmaze"))
    if not mazes:
        print(f"ERROR: no ADL_*.aquadotmaze datasets under {root}", file=sys.stderr)
        return 2

    pair_count = 0
    endpoint_count = 0
    same_side = 0
    orientations = Counter()
    problems = []
    ewe4 = None

    for path in mazes:
        width, height, rows = read_maze(path)
        traversable = {
            (x, y)
            for y, row in enumerate(rows)
            for x, token in enumerate(row)
            if token != ":"
        }
        wraps = defaultdict(list)
        for y, row in enumerate(rows):
            for x, token in enumerate(row):
                if token in {"A", "B", "C", "D"}:
                    wraps[token].append((x, y))

        for wrap_id, endpoints in sorted(wraps.items()):
            if len(endpoints) != 2:
                problems.append(f"{path.name}: wrap {wrap_id} has {len(endpoints)} endpoints")
                continue

            pair_count += 1
            sides = []
            for endpoint in endpoints:
                endpoint_count += 1
                side, (dx, dy) = boundary_side(*endpoint, width, height)
                sides.append(side)
                inward = (endpoint[0] + dx, endpoint[1] + dy)
                if side == "?":
                    problems.append(f"{path.name}: wrap {wrap_id} endpoint {endpoint} is not on boundary")
                elif inward not in traversable:
                    problems.append(
                        f"{path.name}: wrap {wrap_id} endpoint {endpoint} has no inward traversable neighbor {inward}"
                    )

            orientation = tuple(sorted(sides))
            orientations[orientation] += 1
            if sides[0] == sides[1]:
                same_side += 1

            if path.name == "ADL_049_Ewe_4.aquadotmaze" and wrap_id == "A":
                ewe4 = tuple(endpoints)

    adjacent = sum(
        count
        for orientation, count in orientations.items()
        if orientation not in {("L", "R"), ("B", "T"), ("L", "L"), ("R", "R"), ("T", "T"), ("B", "B")}
    )

    print(f"standard mazes:       {len(mazes)}")
    print(f"wrap pairs:           {pair_count}")
    print(f"wrap endpoints:       {endpoint_count}")
    print(f"same-boundary pairs:  {same_side}")
    print(f"adjacent-side pairs:  {adjacent}")
    print(f"Ewe (4) A endpoints:  {ewe4}")
    print("orientations:")
    for orientation, count in sorted(orientations.items()):
        print(f"  {orientation[0]}-{orientation[1]}: {count}")

    if ewe4 != ((12, 30), (27, 30)):
        problems.append(f"unexpected Ewe (4) A geometry: {ewe4}")

    if problems:
        print("\nFAIL:")
        for problem in problems:
            print(f"  - {problem}")
        return 1

    print("\nPASS: every recovered wrap endpoint has a deterministic inward exit.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "root",
        nargs="?",
        type=Path,
        default=Path("AquaDotRed!Revival/AquaDotRed!Revival/OriginalLevelData.xcassets"),
        help="OriginalLevelData.xcassets directory (defaults to repo-relative path)",
    )
    args = parser.parse_args()
    return audit(args.root)


if __name__ == "__main__":
    raise SystemExit(main())
