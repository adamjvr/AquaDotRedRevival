#!/usr/bin/env python3
"""Phase 4B audit for the recovered AquaDot!Red Skill calculation.

This tool intentionally has no third-party dependencies. It verifies the preserved
RE evidence signatures, independently evaluates known scoring vectors with 32-bit
float round-trips that mirror the original SSE path, and optionally checks an
installed AquaDotRedRevival checkout for the Phase 4B integration markers.
"""
from __future__ import annotations

import argparse
import json
import math
import struct
from pathlib import Path

HERE = Path(__file__).resolve().parent
PACKAGE = HERE.parent
EVIDENCE = (PACKAGE / "evidence") if (PACKAGE / "evidence").is_dir() else (PACKAGE / "docs/reverse-engineering/phase4b")


def f32(value: float) -> float:
    return struct.unpack("<f", struct.pack("<f", float(value)))[0]


def addf(a: float, b: float) -> float:
    return f32(f32(a) + f32(b))


def mulf(a: float, b: float) -> float:
    return f32(f32(a) * f32(b))


def munch_component(total: int, remaining: int) -> float:
    if total > 3:
        ratio = f32(4.0 / float(total))
        return {
            1: mulf(ratio, 5),
            2: mulf(ratio, 10),
            3: mulf(ratio, 20),
            4: mulf(ratio, 40),
        }.get(remaining, 0.0)
    if total == 3:
        return {1: 7.0, 2: 15.0, 3: 40.0}.get(remaining, 0.0)
    if total == 2:
        return {1: 10.0, 2: 40.0}.get(remaining, 0.0)
    if total == 1:
        return 40.0 if remaining == 1 else 0.0
    return 40.0 if total == 0 else 0.0


def quality(raw: float) -> str:
    if raw < 500:
        return "yuk"
    if raw < 1250:
        return "okay"
    if raw < 2500:
        return "good"
    if raw < 3500:
        return "veryGood"
    return "wowBest"


def calculate(x: dict) -> tuple[int, str, float]:
    d = f32(x.get("levelDifficulty", 0.30))
    D = float(d) + 1.0
    skill = f32(munch_component(x.get("totalMunchDots", 0), x.get("remainingMunchDots", 0)))

    count = int(x.get("timingSampleCount", 0))
    avg = f32(f32(x.get("timingSampleSum", 0.0)) / float(count)) if count > 0 else 0.0
    timing = mulf(mulf(avg, avg), avg)
    timing = mulf(timing, 100)
    skill = addf(skill, timing)

    full = int(x.get("fullBugClearsDuringMunch", 0))
    full_bonus = {1: 5.0, 2: 10.0, 3: 30.0, 4: 100.0}.get(full, 0.0)
    skill = addf(skill, full_bonus)
    if not x.get("ateAnyBugWithMunch", False):
        skill = addf(skill, 10)
    if x.get("everyConsumedMunchAteBug", True):
        skill = addf(skill, 20)

    if not x.get("damageContactOccurred", False):
        skill = f32(float(skill) + 100.0 * D)
    else:
        damage = f32(x.get("cumulativeDamage", 0.0))
        if damage < 1.0:
            preserved = 1.0 - float(damage)
            skill = f32(float(skill) + preserved * (preserved * 100.0) * D)

    minimum = f32(x.get("minimumEnergyAfterDamage", 1.0))
    minimum_term = mulf(mulf(minimum, minimum), 100)
    skill = f32(float(skill) + float(minimum_term) * D)

    if not x.get("activatedYummyPower", False):
        skill = addf(skill, 20)

    special = f32(x.get("specialPowerRemaining", 0.0))
    special_term = mulf(mulf(special, special), 50)
    skill = f32(float(skill) + float(special_term) * D)

    if not x.get("ateAnyYummyDot", False):
        skill = addf(skill, 50)
    if not x.get("missedAnyYummyDot", False):
        skill = addf(skill, 15)

    # Binary flag 0x1d9639: initialized true; no direct runtime write recovered.
    skill = addf(skill, 15)

    if not x.get("yukEverSpawned", False):
        skill = addf(skill, 5)
    else:
        remaining_yuk = int(x.get("yukRemainingAtEnd", 0))
        if remaining_yuk == 1:
            skill = addf(skill, 40)
        elif remaining_yuk > 1:
            skill = addf(skill, 100)

    if not x.get("ateAnyYukDot", False):
        skill = addf(skill, 10)
    if not x.get("expiredAnyYukDot", False):
        skill = addf(skill, 20)

    skill = mulf(skill, 10)
    deaths = int(x.get("deaths", 0))
    if deaths == 1:
        skill = f32(float(skill) * 0.8)
    elif deaths == 2:
        skill = mulf(skill, 0.5)
    elif deaths >= 3:
        skill = f32(float(skill) * 0.2)

    skill = f32(float(skill) * D)
    return math.floor(skill), quality(skill), skill


def baseline(**updates: object) -> dict:
    value = {
        "levelDifficulty": 0.30,
        "totalMunchDots": 0,
        "remainingMunchDots": 0,
        "timingSampleSum": 0.0,
        "timingSampleCount": 0,
        "fullBugClearsDuringMunch": 0,
        "ateAnyBugWithMunch": False,
        "everyConsumedMunchAteBug": True,
        "damageContactOccurred": False,
        "cumulativeDamage": 0.0,
        "minimumEnergyAfterDamage": 1.0,
        "activatedYummyPower": False,
        "specialPowerRemaining": 0.0,
        "ateAnyYummyDot": False,
        "missedAnyYummyDot": False,
        "yukEverSpawned": False,
        "yukRemainingAtEnd": 0,
        "ateAnyYukDot": False,
        "expiredAnyYukDot": False,
        "deaths": 0,
    }
    value.update(updates)
    return value


def assert_evidence() -> None:
    asm = (EVIDENCE / "original_skill_calculation_i386.asm").read_text()
    required = [
        "5f3c2:",
        "calll\t0x27568",
        "movl\t0x1d9620",
        "movl\t0x1d962c",
        "cmpb\t$0x0, 0x1d9630",
        "cmpb\t$0x0, 0x1d9631",
        "cmpb\t$0x0, 0x1d9639",
        "movl\t0x1d9624",
        "ucomiss\t0x772b8",
        "ucomiss\t0x774ac",
        "ucomiss\t0x774b0",
        "movss\t0x774b4",
        "calll\t0x1dcba4 ## symbol stub for: _floorf",
        "5f824:\tretl",
    ]
    missing = [needle for needle in required if needle not in asm]
    if missing:
        raise SystemExit(f"FAIL: preserved Skill disassembly missing signatures: {missing}")

    mutators = (EVIDENCE / "original_skill_state_mutators_i386.asm").read_text()
    for needle in ["5ca18:", "5ca48:", "5ca54:", "5ca60:", "5cac2:", "5cace:", "5cb24:"]:
        if needle not in mutators:
            raise SystemExit(f"FAIL: missing state-mutator evidence {needle}")

    constants = json.loads((EVIDENCE / "skill_constants.json").read_text())
    if constants["quality_thresholds"] != [500, 1250, 2500, 3500]:
        raise SystemExit("FAIL: threshold evidence metadata changed")


def assert_vectors() -> None:
    cases = [
        ("canonical default", baseline(), 6045, "wowBest"),
        ("one death", baseline(deaths=1), 4836, "wowBest"),
        ("two deaths", baseline(deaths=2), 3022, "veryGood"),
        ("three deaths", baseline(deaths=3), 1209, "okay"),
        (
            "nonlinear damage",
            baseline(damageContactOccurred=True, cumulativeDamage=0.25, minimumEnergyAfterDamage=0.75),
            4566,
            "wowBest",
        ),
        (
            "goodie timing + special",
            baseline(
                timingSampleSum=1.5,
                timingSampleCount=2,
                specialPowerRemaining=0.5,
                activatedYummyPower=True,
                ateAnyYummyDot=True,
                missedAnyYummyDot=True,
                yukEverSpawned=True,
                yukRemainingAtEnd=1,
                ateAnyYukDot=True,
                expiredAnyYukDot=True,
            ),
            5764,
            "wowBest",
        ),
    ]
    for name, input_state, expected_points, expected_quality in cases:
        points, band, raw = calculate(input_state)
        if points != expected_points or band != expected_quality:
            raise SystemExit(
                f"FAIL {name}: got points={points} band={band} raw={raw}; "
                f"expected {expected_points}/{expected_quality}"
            )
        print(f"PASS vector {name}: raw={raw:.6f} points={points} quality={band}")

    munch_expect = {
        (0, 0): 40,
        (1, 1): 40,
        (2, 1): 10,
        (2, 2): 40,
        (3, 1): 7,
        (3, 2): 15,
        (3, 3): 40,
        (4, 1): 5,
        (4, 2): 10,
        (4, 3): 20,
        (4, 4): 40,
        (5, 1): 4,
        (5, 2): 8,
        (5, 3): 16,
        (5, 4): 32,
        (5, 5): 0,
    }
    for key, expected in munch_expect.items():
        got = munch_component(*key)
        if got != expected:
            raise SystemExit(f"FAIL Munch table {key}: got {got}, expected {expected}")
    print(f"PASS recovered Munch table: {len(munch_expect)} assertions")

    boundaries = [
        (499.999, "yuk"), (500, "okay"),
        (1249.999, "okay"), (1250, "good"),
        (2499.999, "good"), (2500, "veryGood"),
        (3499.999, "veryGood"), (3500, "wowBest"),
    ]
    for raw, expected in boundaries:
        if quality(raw) != expected:
            raise SystemExit(f"FAIL quality threshold {raw}: {quality(raw)} != {expected}")
    print("PASS exact quality boundaries: 500 / 1250 / 2500 / 3500")


def assert_repo(repo: Path) -> None:
    root = repo.resolve()
    paths = {
        "scoring": root / "AquaDotRed!Revival/AquaDotRed!Revival/Phase3/AquaDotLevelScoring.swift",
        "recovered": root / "AquaDotRed!Revival/AquaDotRed!Revival/Phase4/AquaDotRecoveredSkillScoring.swift",
        "simulation": root / "AquaDotRed!Revival/AquaDotRed!Revival/Phase1/AquaDotGameSimulation.swift",
        "session": root / "AquaDotRed!Revival/AquaDotRed!Revival/Phase1/AquaDotGameSession.swift",
        "dots": root / "AquaDotRed!Revival/AquaDotRed!Revival/Phase2/AquaDotDotSystem.swift",
        "scene": root / "AquaDotRed!Revival/AquaDotRed!Revival/MazeGameScene.swift",
    }
    for name, path in paths.items():
        if not path.is_file():
            raise SystemExit(f"FAIL installed {name}: missing {path}")

    scoring = paths["scoring"].read_text()
    recovered = paths["recovered"].read_text()
    simulation = paths["simulation"].read_text()
    session = paths["session"].read_text()
    dots = paths["dots"].read_text()
    scene = paths["scene"].read_text()

    checks = [
        ("scoring delegation", "AquaDotRecoveredSkillScoring.calculate(snapshot)" in scoring),
        ("old 1800 damage penalty removed", "damageTaken * 1_800" not in scoring),
        ("old 1100 death penalty removed", "livesLost * 1_100" not in scoring),
        ("threshold 3500", "qualityWowBestThreshold: Float = 3_500" in recovered),
        ("damage measurement finalizer", "finalizeDamageSkillMeasurement" in simulation),
        ("selected level difficulty", "skillBaseDifficulty: skillBaseDifficulty" in session),
        ("goodie lifecycle sampling", "goodieTimingSkillSamples" in dots),
        ("scene difficulty bridge", "forSelectedLevelCount: max(0, selector.state.levelsSelected - 1)" in scene),
    ]
    failed = [name for name, ok in checks if not ok]
    if failed:
        raise SystemExit(f"FAIL installed integration markers: {failed}")
    print(f"PASS installed Phase 4B integration markers: {len(checks)} checks")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, help="optional AquaDotRedRevival checkout to verify")
    args = parser.parse_args()

    assert_evidence()
    print("PASS preserved i386 Skill evidence signatures")
    assert_vectors()
    if args.repo:
        assert_repo(args.repo)
    print("PHASE4B SKILL AUDIT PASS")


if __name__ == "__main__":
    main()
