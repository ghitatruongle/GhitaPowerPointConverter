
## Baseline T02.1 (Dart archive — trước ghita_zip, 2026-08-29) — 2026-08-30 21:39:06

| Kịch bản | Nén ZIP | Kích thước |
|---|---|---|
| Deck media: 62 entries, 10.1 MB input | 82.6 ms | 10.1 MB |
| Deck media — ghita_zip (Rust) | (bỏ qua — chưa bật GHITA_ZIP_RUST=1) | — |

## Baseline T02.1 (Dart archive — trước ghita_zip, 2026-08-29, deck 1600x900 q90) — 2026-08-30 21:39:49

| Kịch bản | Nén ZIP | Kích thước |
|---|---|---|
| Deck media: 62 entries, 21.1 MB input | 112 ms | 21.1 MB |
| Deck media — ghita_zip (Rust) | (bỏ qua — chưa bật GHITA_ZIP_RUST=1) | — |

## Sau T02 (ghita_zip Rust — 2026-08-29) — 2026-08-30 21:55:22

| Kịch bản | Nén ZIP | Kích thước |
|---|---|---|
| Deck media: 62 entries, 21.1 MB input | 104 ms | 21.1 MB |
| Deck media — **ghita_zip (Rust)** | ERROR: Bad state: Content hash on Dart side (1786734021) is different from Rust side (1462053951), indicating out-of-sync code. This may happen when, for example, the Dart code is hot-restarted/hot-reloaded without recompiling Rust code. (Note: This is just a sanity check. Even if content hash does not change, the code may still change and needs to be recompiled) | — |

## Sau T02 (ghita_zip Rust — 2026-08-29, DLL mới) — 2026-08-30 21:55:52

| Kịch bản | Nén ZIP | Kích thước |
|---|---|---|
| Deck media: 62 entries, 21.1 MB input | 119 ms | 21.1 MB |
| Deck media — **ghita_zip (Rust)** | 142 ms | 21.1 MB |

## Sau T02 (ghita_zip Rust — 2026-08-29, DLL mới + text-only) — 2026-08-30 21:56:33

| Kịch bản | Nén ZIP | Kích thước |
|---|---|---|
| Deck media: 62 entries, 21.1 MB input | 105 ms | 21.1 MB |
| Deck media — **ghita_zip (Rust)** | 132 ms | 21.1 MB |
| Text-only: 4.5 MB input | Dart 68.7 ms | Rust 19.1 ms |

## Sau T02 (ghita_zip final — 2026-08-29, level-fix) — 2026-08-30 22:08:52

| Kịch bản | Nén ZIP | Kích thước |
|---|---|---|
| Deck media: 62 entries, 21.1 MB input | 117 ms | 21.1 MB |
| Deck media — **ghita_zip (Rust)** | 138 ms | 21.1 MB |
| Text-only: 4.5 MB input | Dart 71.2 ms | Rust 29.6 ms |
