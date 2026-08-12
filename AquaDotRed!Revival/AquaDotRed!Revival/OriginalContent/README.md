# Original content boundary

This directory documents original-content inputs used by the remaster.

`OriginalLevelsManifest.json` records the recovered names, checksums, dimensions, byte lengths, and SHA-256 hashes of all 205 standard mazes. The bytes actually shipped to the runtime are stored as data sets in `../OriginalLevelData.xcassets`, which lets native AppKit and UIKit builds retrieve the same unmodified maze payload through `NSDataAsset`.

Runtime-ready images in `../OriginalRuntimeAssets.xcassets` are crops/transparency preparations derived from recovered original graphics. The complete unmodified graphical recovery package and an exact-name archive of the standard mazes live at repository root under `preservation/`.
