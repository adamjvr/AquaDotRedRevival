# AquaDotRedRevival Phase 3.1 Patch Notes

This pass is a targeted polish patch on top of Phase 3.

## Added
- Restored the recovered AquaDot! Red application icon as a modern Xcode `AppIcon.appiconset`.
- Added a standard `Assets.xcassets` catalog so native Mac and iPad builds have a real icon again.

## Changed
- AquaDot now keeps spinning while moving even when it changes gameplay color state.
- Spin speed/direction now varies by state:
  - normal: classic forward spin
  - munch: faster forward spin
  - yummy: quicker forward spin
  - yuk: slower reverse spin
  - damaged: fast reverse spin

## Notes
- This patch assumes the project is using Xcode's default `AppIcon` name for the primary app icon. If Xcode still shows a generic icon, open the target settings and verify the App Icon field is `AppIcon`.
