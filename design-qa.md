# Lumen visual QA — 2026-10-23

- Evidence paths below are relative to the host checkout; local verification artifacts are not distributed with the theme.
- Source visual truth: `build/lumen-evidence/source-reference.png` (preserved user attachment), 1296×734.
- Implementation full view: `build/lumen-evidence/lumen-reference.png`, 1296×734.
- Additional views: `lumen-desktop.png` (1920×1080), `lumen-portrait.png` (720×1280), `lumen-small.png` (800×600) in that directory.
- Native GPU/Wayland view: `build/lumen-native-evidence/lumen-reference.png`, 1920×1080.
- Qt logical pixels, DPR 1; no CSS viewport. Reference and primary implementation compared at the same 1296×734 dimensions.
- State: playing, three Japanese LRC lines, 0:45 / 2:43, cover and deterministic **test-event** spectrum. This is visual fixture data, not a claim of live audio in the screenshot.
- The mountains/moon are a test-only image rendered behind the transparent scene. The theme package contains no desktop background and does not change the user's wallpaper. Separate `lumen-alpha-*.png` captures verify alpha=0 outside content.

## Findings and comparison history

1. Initial render: lyric line spacing exceeded the reference rhythm; reduced optional line height and next-line gap without changing default host rendering.
2. Initial plain-alpha viewing made low-opacity artwork halos appear too strong. Verified the rendered composition over a test-only background; alpha values remain intact. No opaque cyan patch appears in the actual composition.
3. P1: real QVariantList IPC payloads were rejected by JS Array.isArray, leaving no bars although pure JS tests passed. Replaced with length and finite-element validation; actual host IPC test now asserts reception before screenshot capture.
4. P2: 720×1280 used a horizontal card. Added portrait aspect-ratio detection; final portrait screenshot has artwork/information above the frequency plot, within screen bounds.
5. Final full-view and focused visual review: compared lyric hierarchy and spacing, cover/card geometry, title/progress alignment and cyan spectrum. No actionable P0/P1/P2 findings remain.

## Five fidelity surfaces

- **Typography:** system CJK sans-serif, prominent white current line, smaller translucent surrounding lines; plain-text titles and elision. Slight dark outlines intentionally preserve readability over arbitrary desktop backgrounds.
- **Spacing/layout:** reference lyric center and 64%-width card placement retained; control icon region intentionally removed as requested. Portrait stacks the frequency plot; all tested regions fit the viewport.
- **Colors/tokens:** translucent dark card, fine border, cyan progress and spectrum, low-opacity cover halo. No fullscreen tint. Different background colors are expected because the user owns the background.
- **Images:** real host cover URL and standard host fallback, decoded to display size/DPR. Reference character scene and album artwork are intentionally not copied or generated; production uses the user's desktop and current song.
- **Copy/content:** song metadata and synchronized lyrics are data; no fake labels or controls in production. Missing-extension and unsupported-backend messages tested separately.

## Interaction and runtime checks

No playback controls are present. The native window is input-transparent; Wayland protocol confirms an empty input region, Bottom layer and no keyboard interaction. Native surface destruction is recorded on exit. Lease acquisition, invalid frames, stale frames, missing extension, reconnect and late responses pass QML tests. Song identity and timing use host components. Real audio-to-FFT is validated separately by the native PCM test; no screenshot is used as its evidence.

## Follow-up polish / external acceptance

Windows 10/11 rendering, mixed DPI and Explorer recovery require a Windows machine; this report passes the inspected QML visual implementation and Linux native render only. It does not assert Windows acceptance. Optional future polish: compositor-specific blur behind the card, outside v1 scope.

final result: passed
