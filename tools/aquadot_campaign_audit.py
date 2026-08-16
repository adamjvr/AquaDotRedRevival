#!/usr/bin/env python3
"""Phase 3 campaign-wide audit for the recovered AquaDot maze corpus.

Standard-library only; works on macOS and Linux. It validates the preservation
properties that should remain true while gameplay/presentation work evolves:
CRC, dimensions, starts, connected traversable graph, wrap pairing/inward exits,
and the 41 x 5 recovered standard-level grouping.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict, deque
from pathlib import Path
import re
import sys


def checksum(payload: bytes) -> int:
    crc = 0xFFFF
    for byte in payload:
        crc ^= byte
        for _ in range(8):
            crc = (crc >> 1) ^ 0x8408 if (crc & 1) else (crc >> 1)
    crc = (~crc) & 0xFFFF
    return ((crc << 8) & 0xFF00) | (crc >> 8)


def read_maze(path: Path):
    text = path.read_bytes().decode("mac_roman")
    normalized = text.replace("\r\n", "\n").replace("\r", "\n")
    lines = normalized.split("\n")
    if not lines or lines[0] != "aquadot!red":
        raise ValueError("missing aquadot!red signature")
    stored = int(next(line for line in lines if line.startswith("Checksum:")).split(":", 1)[1])
    width = int(next(line for line in lines if line.startswith("Width:")).split(":", 1)[1])
    height = int(next(line for line in lines if line.startswith("Height:")).split(":", 1)[1])
    width_offset = normalized.index("Width:")
    calculated = checksum(normalized[width_offset:].encode("mac_roman"))

    grid_start = next(i for i, line in enumerate(lines) if line.startswith("Height:")) + 2
    grid = lines[grid_start : grid_start + 2 * height + 1]
    if len(grid) != 2 * height + 1:
        raise ValueError("truncated grid")
    vertices = [row.split() for row in grid[0::2]]
    edges = [row.split() for row in grid[1::2]]
    return stored, calculated, width, height, vertices, edges


def boundary_inward(x, y, width, height):
    if x == 0: return (x + 1, y)
    if x == width: return (x - 1, y)
    if y == 0: return (x, y + 1)
    if y == height: return (x, y - 1)
    return None


def audit(root: Path) -> int:
    mazes = sorted(root.glob("ADL_*.dataset/*.aquadotmaze"))
    if not mazes:
        print(f"ERROR: no recovered ADL datasets under {root}", file=sys.stderr)
        return 2

    problems = []
    totals = Counter()
    groups = defaultdict(list)
    wrap_pairs = 0
    wall_tokens = Counter()

    for path in mazes:
        try:
            stored, calculated, width, height, vertices, edges = read_maze(path)
        except Exception as exc:
            problems.append(f"{path.name}: parse error: {exc}")
            continue

        if stored != calculated:
            problems.append(f"{path.name}: CRC {stored} != calculated {calculated}")

        if len(vertices) != height + 1 or any(len(row) != width + 1 for row in vertices):
            problems.append(f"{path.name}: vertex dimensions do not match {width}x{height}")
        if len(edges) != height or any(len(row) != width for row in edges):
            problems.append(f"{path.name}: edge dimensions do not match {width}x{height}")

        traversable = {
            (x, y) for y, row in enumerate(vertices) for x, token in enumerate(row)
            if token != ":"
        }
        starts = [(x, y) for y,row in enumerate(vertices) for x,t in enumerate(row) if t == "S"]
        enemies = [(t, x, y) for y,row in enumerate(vertices) for x,t in enumerate(row) if t in "EFGH"]
        wraps = defaultdict(list)
        for y,row in enumerate(vertices):
            for x,t in enumerate(row):
                if t in "ABCD": wraps[t].append((x,y))

        if len(starts) < 1:
            problems.append(f"{path.name}: no player start")
        if len(enemies) != 4:
            problems.append(f"{path.name}: expected 4 bug starts, found {len(enemies)}")

        graph = {p: [] for p in traversable}
        for x,y in traversable:
            for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                q=(x+dx,y+dy)
                if q in traversable: graph[(x,y)].append(q)
        for ident, endpoints in wraps.items():
            if len(endpoints) != 2:
                problems.append(f"{path.name}: wrap {ident} has {len(endpoints)} endpoints")
                continue
            wrap_pairs += 1
            a,b=endpoints
            graph[a].append(b); graph[b].append(a)
            for endpoint in endpoints:
                inward=boundary_inward(*endpoint,width,height)
                if inward is None:
                    problems.append(f"{path.name}: wrap {ident} endpoint {endpoint} is not on boundary")
                elif inward not in traversable:
                    problems.append(f"{path.name}: wrap {ident} endpoint {endpoint} has no inward corridor")

        if traversable:
            start=next(iter(traversable)); seen={start}; queue=deque([start])
            while queue:
                p=queue.popleft()
                for q in graph[p]:
                    if q not in seen: seen.add(q); queue.append(q)
            if seen != traversable:
                problems.append(f"{path.name}: traversable graph disconnected ({len(seen)}/{len(traversable)})")

        for row in edges:
            wall_tokens.update(row)
        totals["traversable"] += len(traversable)
        totals["starts"] += len(starts)
        totals["bugs"] += len(enemies)

        match=re.match(r"ADL_\d+_(.+)_([1-5])\.aquadotmaze$", path.name)
        if match: groups[match.group(1)].append(int(match.group(2)))
        else: problems.append(f"{path.name}: does not match recovered group/variant naming")

    if len(mazes) != 205:
        problems.append(f"expected 205 standard mazes, found {len(mazes)}")
    if len(groups) != 41:
        problems.append(f"expected 41 named groups, found {len(groups)}")
    for group, variants in groups.items():
        if sorted(variants) != [1,2,3,4,5]:
            problems.append(f"group {group}: variants {sorted(variants)}")

    print(f"standard mazes:      {len(mazes)}")
    print(f"named groups:        {len(groups)}")
    print(f"wrap pairs:          {wrap_pairs}")
    print(f"traversable vertices:{totals['traversable']:>8}")
    print(f"player starts:       {totals['starts']:>8}")
    print(f"bug starts:          {totals['bugs']:>8}")
    print("wall token totals:")
    for token,count in sorted(wall_tokens.items(), key=lambda p: (p[0] != 'X', p[0])):
        print(f"  {token:>2}: {count}")

    if problems:
        print("\nFAIL:")
        for problem in problems:
            print(" -", problem)
        return 1
    print("\nPASS: 205/205 recovered standard mazes satisfy Phase 3 campaign invariants.")
    return 0


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", type=Path,
        default=Path("AquaDotRed!Revival/AquaDotRed!Revival/OriginalLevelData.xcassets"))
    return audit(parser.parse_args().root)

if __name__ == "__main__":
    raise SystemExit(main())
