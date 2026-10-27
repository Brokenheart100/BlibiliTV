# MambaTV local compatibility patch

Based on the complete `lib/` sources of canvas_danmaku 0.3.3, MIT, by Predidit.
The original LICENSE is retained verbatim. `UPSTREAM.json` records the official
pub.dev archive SHA256 and normalized per-file upstream/current hashes.
`MAMBA.patch` is the reviewable diff against that archive.

Local version: **0.3.3+mamba.1**, a direct path dependency committed with this
repository; no global Pub cache edits, dependency overrides, or moving Git refs.

The patch adds `DanmakuOption.framesPerSecond` (60 by default, 30/15 for low load).
The original ticker remains the default. At 30/15, a monotonic stopwatch and a
cancelable timer at the selected cadence sample the library animation clock and request only
the required frames; pause/resume/empty/dispose stop the selected scheduler.
Changing cadence preserves the last animation tick and starts a new relative
clock. MambaTV controls admission using the native media timeline separately.

Layout, collision handling, text-image cache, painters, filtering modes and the
controller interface are upstream implementations. The earlier experimental
picture-cache patch was rejected and is **not** included.

Reproduction: download and verify the archive in UPSTREAM.json, unpack its lib,
pubspec and license/documentation files, then apply MAMBA.patch at that root.
Run `python tool/ci/check_vendor.py` from MambaTV before analysis/tests. A future
upstream change requires a new provenance record, reviewed patch and the same
native performance/lifecycle checks; don't silently rebase this fork.
