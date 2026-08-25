# KẾ HOẠCH PHÁT HÀNH v2.0.1 CHÍNH THỨC (STABLE)

> Ngày lập: 2026-08-24 · Điểm xuất phát: commit `c1379b1` (v2.0.1-beta2), local = GitHub 100%
> Nguyên tắc xuyên suốt: **đo rồi mới sửa** · mọi tối ưu phải có số trước/sau · không refactor cấu trúc lớn trước stable

---

## 5 TRACKS (luồng công việc song song)

| Track | Tên | Phạm vi |
|---|---|---|
| **F** | Feature Complete | Đủ 100% tính năng đã chốt, không mục nào "đang phát triển" |
| **P** | Performance | Tối ưu thuật toán + code, có benchmark chứng minh |
| **R** | Resources | Tối ưu tài nguyên, dependencies, cam kết privacy |
| **Q** | Quality | Test suite, coverage, mô phỏng CI, installer smoke test |
| **S** | Ship | Đồng bộ version, CHANGELOG, tag, GitHub Release |

## 4 PHASES (giai đoạn tuần tự, có cổng chốt)

| Phase | Tên | Thời lượng | Cổng qua phase sau |
|---|---|---|---|
| **1** | Baseline & Chốt phạm vi | ~nửa buổi | Có baseline benchmark + ma trận tính năng chốt |
| **2** | Thực thi (F/P/R chạy song song) | ~2–2,5 ngày | Mọi thay đổi có test riêng + số đo trước/sau |
| **3** | Gia cố (Hardening Gate) | ~1 ngày | Analyze 0 · suite xanh ×2 · CI mô phỏng xanh · installer OK |
| **4** | Phát hành | ~2 giờ | CI GitHub xanh 100% mới được tag/release |

---

## MA TRẬN TASK (Track × Phase)

| Task | Track | Phase | Nội dung | Tiêu chí xong |
|---|---|---|---|---|
| **F1** ✅ | F | 1 | Quét `ROADMAP_2.0.0-beta.md` + CHANGELOG beta1/beta2 → ma trận tính năng đã chốt vs hiện trạng | Xong 2026-08-24 — 114/114 file ROADMAP tồn tại (5 case gộp/đổi tên có nguồn CHANGELOG); kết luận ở Phụ lục A |
| **F2** ✅ | F | 2 | T08: Wi-Fi token chuyển từ query param URL sang HTTP header (link one-time đầu cấp cookie phiên, request sau đọc header); sửa JS client nhúng trong deck | Xong 2026-08-25, commit `b45977c`: token chỉ bootstrap trên trang entry; data endpoint nhận cookie HttpOnly hoặc `X-Ghita-Token`; 13 test pass gồm sai token/hết hạn/replay/thiếu cookie |
| **F3** ✅ | F | 2 | Chốt tài liệu benchmark T07 (`tool/benchmark_results_t07.md`) đưa vào CHANGELOG | Xong 2026-08-25, commit `6be48d3` |
| **P1** ✅ | P | 1 | Chạy baseline toàn bộ benchmark sẵn có (`tool/benchmark_*`, export/metrics/html-deck) | Xong 2026-08-24 — đã ghi vào `tool/benchmark_results_t01/t02/t07.md` nhãn "Baseline v2.0.1-stable Phase1", tóm tắt ở Phụ lục B |
| **P2** ✅ | P | 1→2 | Profiling cho 3 kịch bản: khởi động → dựng deck nhiều ảnh → xuất PPTX/PDF | Xong 2026-08-24 — đo bằng benchmark tất định + exe Release thật (thay vì DevTools tương tác), hotspot ở Phụ lục C |
| **P3** ✅ | P | 2 | Tối ưu theo hotspot: build slide `ppt_generator.dart`, PDF ảnh lớn, rebuild thừa `ribbon_toolbar`/`editor_shell`. Mỗi tối ưu = 1 commit có số đo | Điều chỉnh theo bằng chứng Phase 1+2: hotspot thật = media player của HTML deck, không phải các file lớn. Commit `51c8171`: media gating → deck chuẩn −19,7%, parse −37%; PPTX/PDF khỏe không đụng; export ×4 lần chốt ~90–100 ms là chi phí thật nhỏ |
| **P4** ✅ | P | 2–3 | Đẩy coverage từ ~42,5% lên ≥50%, ưu tiên `wifi_broadcaster_service.dart` + service export | Xong 2026-08-25: ex-l10n 49,8% → **51,0% ≥50%**; suite 1010/1010 xanh kèm coverage run |
| **R1** ✅ | R | 2 | Nén `assets/images/app_logo.png`: 468KB → <100KB (oxipng/pngquant/WebP) | Xong 2026-08-25, commit `39219fc`: file cũ là JPEG 1024px mang đuôi .png, hiển thị 20px → PNG 128px **30 KB (−93,5%)** |
| **R2** ✅ | R | 2 | Rà `pubspec.yaml` loại package không dùng | Xong 2026-08-25, commit `077ff37`: loại 7 package (uuid, cupertino_icons, file, audioplayers, highlight, flutter_highlight, url_launcher); analyze 0 issues |
| **R3** ✅ | R | 2→3 | Kiểm chứng lại privacy: zero call mạng lúc startup sau thay đổi T08 | Xong 2026-08-25: exe Release chạy thử — 0 kết nối TCP trong 7 s đầu; T08 không đụng đường startup |
| **Q1** | Q | 3 | `flutter analyze` | 0 issues |
| **Q2** | Q | 3 | Full suite (94 file / 1005+ test) | Xanh ×2 lần liên tục |
| **Q3** | Q | 3 | Mô phỏng đủ matrix CI như GH runner (chú ý drift MSVC local vs windows-latest) | Build Windows mô phỏng thành công trước khi push |
| **Q4** | Q | 3 | Build release + installer (`build_installer.ps1`) → `verify_release.ps1` → cài thử + smoke test theo checklist F1 | Installer cài được, toàn bộ tính năng chính chạy đúng |
| **S1** | S | 4 | Đồng bộ version: `pubspec.yaml` → `2.0.1+3`; `.iss` → `MyAppVersion "2.0.1.3"` + `DisplayVersion "2.0.1+3"`; README → `v2.0.1` | Cả 3 chỗ cùng một version, grep không sót |
| **S2** | S | 4 | Gộp CHANGELOG thành `[2.0.1] - <ngày>`, viết theo góc nhìn người dùng, có mục "Tối ưu hiệu năng" kèm số đo trước/sau | CHANGELOG hoàn chỉnh, không còn chữ "đang phát triển" |
| **S3** | S | 4 | Commit verbatim `v2.0.1` → push → chờ CI GitHub xanh 100% → tag `v2.0.1` → GitHub Release đính installer → copy ra Desktop + lưu SHA256 | Tag + Release hiển thị đúng trên GitHub |
| **S4** | S | 4 | Cập nhật memory (v2.0.1 released, tag cuối = v2.0.1) + tổng kết bài học | Memory khớp thực tế repo |

## SƠ ĐỒ THỜI GIAN

```
Phase 1 (0,5 ngày)   : F1 · P1 · P2
Phase 2 (2–2,5 ngày) : F2 F3 ─┐
                       P3 P4 ─┼─ chạy song song
                       R1 R2 ─┘
                       R3 (cuối phase)
Phase 3 (1 ngày)     : Q1 Q2 Q3 Q4 (+P4 chốt coverage)
Phase 4 (2 giờ)      : S1 S2 S3 S4
TỔNG                 : ~3–4 ngày làm việc
```

## QUY TẮC DỪNG

- Profiling lộ vấn đề đòi sửa quá lớn → ghi rõ hạn chế vào CHANGELOG, phát hành đúng kế hoạch; sửa lớn để dành v2.0.2.
- Bất kỳ test nào đỏ ở Phase 3 → không qua Phase 4, quay lại Phase 2 sửa.
- Không nhận tính năng mới sau khi F1 chốt phạm vi.

---

# KẾT QUẢ PHASE 1 — 2026-08-24 ✅

## Phụ lục A — Ma trận tính năng chốt vs hiện trạng (F1)

| Nhóm | Phạm vi chốt | Hiện trạng | Bằng chứng |
|---|---|---|---|
| v2.0.0 | 67 Track / 670 Phase (10 Milestone) theo `ROADMAP_2.0.0-beta.md` | **ĐỦ 100%** | Kiểm chứng lại độc lập 2026-08-24: quét toàn bộ 114 đường dẫn Dart trong ROADMAP — **114/114 tồn tại** (109 khớp chính xác; 5 case gộp/đổi tên đều có nguồn CHANGELOG: `accessibility_panel`→`m9_productivity_dialogs.dart`, `text_effects_service`→`image_editor_service.dart`, `shape_tools`→`shape_tools_dialog.dart`, `guides_overlay`→nội dung `editor_shell.dart`, `export_video_dialog`→`m6_export_dialog.dart`) |
| beta1 (2026-08-19) | Stability & hardening: metadata/schema version, presentation lifecycle readiness, history mutation nhất quán, HTML safety policy, LAN session expiry, Windows CI mở rộng | **ĐỦ** | CHANGELOG `[2.0.1-beta.1]` + suite xanh |
| beta2 — kế hoạch cải tiến | T01–T06 (test phủ state/engine/AI/PDF + Mermaid E2E + coverage gate ratchet) · P1/P1b/P2/P3 (Present UI, poll thích ứng, boot nhẹ) | **ĐỦ** | CHANGELOG beta.2, commit `c1379b1`; suite 1005/1005 ×2 |
| beta2 — T07 HTML deck tối ưu | Code tối ưu đã chạy (deck 25.394→20.114 B ngày 11-08) | **Còn thiếu: chốt tài liệu** → task F3 | Số liệu có sẵn `tool/benchmark_results_t07.md`, chưa vào CHANGELOG |
| beta2 — T08 Wi-Fi token → header | Token broadcast vẫn đọc từ query param URL (`wifi_broadcaster_service.dart`:223,244,302,391) — dễ rơi vào log/history trình duyệt người xem | **THIẾU — tính năng chốt duy nhất chưa làm** → task F2 (Phase 2) | Grep trực tiếp code ngày 2026-08-24 |

> Kết luận phạm vi: chỉ còn **F2 (T08)** và **F3 (tài liệu T07)** là việc tính năng; ngoài ra không nhận thêm gì (scope freeze).

## Phụ lục B — Baseline hiệu năng (P1), ghi chính thức trong `tool/benchmark_results_*.md`

Nhãn mốc: **"Baseline v2.0.1-stable Phase1 (2026-08-24)"** — mọi tối ưu Phase 2 đối chiếu về đây.

**Export PPTX/PDF/HTML — deck chuẩn 20 slide (`benchmark_results_t01.md`):**

| Kịch bản | Parse | Build XML | Nén ZIP | Tổng | Dung lượng |
|---|---|---|---|---|---|
| PPTX lần đầu (cache lạnh) | 1,2 ms | 15,3 ms | 17,0 ms | **35,2 ms** | 45.278 B |
| PPTX lần 2 (cache ấm) | 0,0 ms | 4,5 ms | 13,3 ms | **20,1 ms** | 45.278 B |
| PDF tổng | — | — | — | **269 ms** | 165.314 B |
| HTML tổng | — | — | — | **97,7 ms** | 22.037 B |

**Layout metrics — sai số ước lượng vs font thật (`benchmark_results_t02.md`):** trung bình 47,5% → **10,3%** (đã tối ưu T02); tệ nhất 99,5% (block nghiêng).

**HTML deck 10 slide / 10 ảnh (`benchmark_results_t07.md`):**

| Chỉ số | Baseline hôm nay | Lần đo trước (11-08) |
|---|---|---|
| Tổng dung lượng | **25.418 B** | 20.114 B ⚠️ +26% |
| CSS keyframes | **6.186 B** | 4.304 B ⚠️ +44% |
| Build + ghi file | 226,7 ms | 207,6 ms |
| Parse HTML (proxy slide đầu) | 37,4 ms | 30,6 ms |

**Khởi động app Release (exe thật, đo đến khi cửa sổ hiện):** run1 567 ms (lạnh), run2 430 ms, run3 429 ms → **median ~430 ms**.

## Phụ lục C — Danh sách hotspot ưu tiên cho Phase 2 (P2)

Phương pháp: benchmark tất định trong repo + đo exe Release thật (thay vì phiên DevTools tương tác — không tái được trong môi trường tự động); mỗi hotspot đều kèm số liệu gốc ở Phụ lục B.

1. **HTML player phình to (cao nhất)** — deck +26%, CSS keyframes +44% chỉ sau ~2 tuần thêm tính năng (diagram accent, fullscreen…). Hành động P3/R: audit CSS/JS player, dedupe keyframes, minify whitespace; mục tiêu đưa tổng về ≤ 21 KB mà không mất tính năng; kèm test khóa sàn đã có (`test/p3_performance_test.dart`).
2. **Đường xuất HTML bất ổn** — cùng bài đo T01: 30,7 ms (đợt cũ) vs 97,7 ms baseline hôm nay. Chưa kết luận regression hay nhiễu máy; Phase 2 chạy lại ≥3 lần trước khi quyết định có tối ưu hay không.
3. **Ảnh logo 468 KB decode lúc khởi động** — startup 430 ms đang tốt nhưng asset chiếm 86% tổng tài nguyên; R1 nén <100KB vừa giảm RAM/đĩa vừa gọn installer.
4. **PDF export ~269 ms / 20 slide — khỏe**, chỉ cần giữ mốc khi làm F2/bookmarks; không tối ưu trừ khi profile nói ngược lại.
5. **Sai số layout block nghiêng 99,5%** — không phải hiệu năng nhưng là điểm yếu chất lượng xuất PPTX; ghi nhận để cân nhắc trong P3 nếu rẻ, không bắt buộc.

### CỔNG PHASE 1: PASS
Có baseline đầy đủ (P1) + ma trận tính năng chốt với đúng 1 thiếu sót đã lộ (F1). Điều kiện sang Phase 2 đạt.

---

# KẾT QUẢ PHASE 2 — 2026-08-25 ✅

6 commit local (chưa push — push thuộc Phase 3 sau khi mô phỏng CI): `b45977c` F2 · `6be48d3` F3 · `51c8171` P3 · `39219fc` R1 · `077ff37` R2 · `10c28cf` housekeeping.

## Bảng thành tích

| Hạng mục | Trước | Sau | Bằng chứng |
|---|---|---|---|
| Tính năng chốt còn thiếu | 1 (T08) | **0** | F2: token broadcast chỉ bootstrap → cookie phiên HttpOnly + header; 13 test |
| HTML deck chuẩn (10 slide/10 ảnh) | 25.418 B · parse 37,4 ms | **20.413 B (−19,7%) · 23,4 ms (−37%)** | `tool/benchmark_results_t07.md` nhãn "P3b" |
| Logo app | 468 KB (JPEG trá hình .png, hiển thị 20px) | **30 KB PNG 128px** | commit `39219fc` |
| Dependencies | 32 package | **25 package** (−7 không dùng) | grep toàn repo + analyze 0 issues |
| Coverage ex-l10n | 49,8% | **51,0% ≥ 50%** | `flutter test --coverage` + coverage_summary |
| Suite | 1005 test | **1010/1010 xanh ×1** (Phase 3 sẽ chạy ×2) | full run 2026-08-25 |
| Privacy startup-network | zero | **zero** (đo thực nghiệm: 0 TCP/7s) | R3 probe trên exe Release |

## Bài học ghi nhận

- Hotspot thật của deck HTML là **code player media gắn kèm vô điều kiện**, không phải formatting/CSS keyframes như nghi ban đầu — gating theo nội dung giải quyết gốc mà không mất tính năng.
- Test sàn kích thước (`p3_performance_test`) phải tái chuẩn theo tối ưu: đây là test khẳng định deck đủ nội dung, không phải benchmark hiệu năng (giới hạn <15 s vẫn nguyên).
- Số đo cũ (30,7 ms HTML export) thuộc mã nguồn giai đoạn trước — mọi so sánh trước/sau phải cùng commit.

### CỔNG PHASE 2: PASS
Mọi thay đổi đều có test riêng + số đo trước/sau; suite 1010/1010 xanh; analyze 0 issues. Điều kiện sang Phase 3 (Hardening Gate) đạt: Q1–Q4 sẽ chạy lại toàn bộ kiểm định trên nền đã ổn.

---

# KẾT QUẢ PHASE 3 — 2026-08-25 ✅

| Task | Kết quả | Bằng chứng |
|---|---|---|
| **Q1** analyze | ✅ PASS | `flutter analyze --no-fatal-infos`: No issues; `tool/l10n_audit.dart`: CLEAN |
| **Q2** suite ×2 | ✅ PASS | `flutter test --coverage` chạy 2 lần liên tục, cả hai **1010/1010 All tests passed** (~1:19/lần) |
| **Q3** mô phỏng CI | ✅ PASS | Đủ 6 bước của `ci-windows.yml` tại local: pub get · analyze · l10n audit · test+coverage ×2 · coverage summary (ratchet giữ vững) · `flutter build windows --release` thành công 66,3 s. Lưu ý drift MSVC: build GH runner dùng MSVC mới hơn — CI GitHub thật vẫn phải xanh sau push (theo dõi ở dưới) |
| **Q4** installer | ✅ PASS | `GhitaPPT-Setup-2.0.1-beta2.exe` 14,93 MB, SHA-256 `4bdbcd33…333a5cc`; `verify_release.ps1 -SmokeLaunch`: Validation/SmokeInstall/SmokeLaunch **Passed** |

**Bug thật sửa trong Phase 3**: `verify_release.ps1` đòi tên artifact kèm `+build` (`GhitaPPT-Setup-2.0.1-beta2+2.exe`) trong khi `build_installer.ps1` chủ động đặt tên không kèm (`GhitaPPT-Setup-2.0.1-beta2.exe`, comment trong code ghi rõ quy ước) → verify luôn fail với version có build number. Đã thống nhất verify theo FileBase của builder.

**Smoke test thủ công**: app cài và mở được qua installer (SmokeInstall + SmokeLaunch); khởi động ~430 ms; zero network lúc boot (R3). Checklist tính năng đầy đủ nằm trong 1010 test tự động + ma trận F1.

### CỔNG PHASE 3: PASS
Analyze 0 · suite xanh ×2 · mô phỏng CI đủ 6 bước xanh · installer verify + smoke OK. **CI GitHub run `32815256867` trên windows-latest: completed / success ✅** (8 commit `c1379b1..7dcef44` — drift MSVC không gây vấn đề). Phase 4 sẵn sàng.

---

# KẾT QUẢ PHASE 4 — 2026-08-25 ✅ PHÁT HÀNH THÀNH CÔNG

| Task | Kết quả | Bằng chứng |
|---|---|---|
| **S1** version sync | ✅ | `pubspec.yaml` `2.0.1+3` · `build_info.dart` appVersion `2.0.1`/channel stable/numeric `2.0.1.3` · `.iss` `"2.0.1.3"`+`"2.0.1+3"` · README `v2.0.1` · test build-info cập nhật. Bài học: lượt soát đầu bỏ sót **2 file contract-test ghim chuỗi beta2** (`release_2_0_0_official_test`, `v2_0_1_beta_contract_test`) → CI run `32816715534` đỏ đúng 3 assertion đó; đã chuyển sang contract stable |
| **S2** CHANGELOG | ✅ | Gộp thành một mục `[2.0.1] - 2026-08-25` theo góc nhìn người dùng: Bảo mật / Tối ưu (có số đo) / Chất lượng; không còn "đang phát triển" |
| **S3a** CI xanh bắt buộc | ✅ | Commit verbatim `v2.0.1` (`e8acde6`) push → CI đỏ (contract test) → fix `5526b41` → **CI run `32817486505`: success** |
| **S3b** tag + release | ✅ | Tag `v2.0.1` tại `5526b41`; GitHub Release [v2.0.1](https://github.com/ghitatruongle/GhitaPowerPointConverter/releases/tag/v2.0.1) đính `GhitaPPT-Setup-2.0.1.exe` (14,93 MB) + `.sha256`; Desktop có bản copy + checksum |
| **S4** memory | ✅ | Memory cập nhật: v2.0.1 released, last tag = v2.0.1 |

Installer chính thức: SHA-256 `9eea021a8c7241aae170556faddb0fb4dab513828c1284a3ae326dd3dda5fd9b` — verify_release.ps1 Validation/SmokeInstall/SmokeLaunch Passed trên artifact này.

### CỔNG PHASE 4 / RELEASE: DONE
Kế hoạch 4 phase × 5 track hoàn thành trọn vẹn trong ~1,5 ngày làm việc (dự kiến ban đầu 3–4 ngày).

---

# PHỤ LỤC — KIỂM CHỨNG SAU PHÁT HÀNH ("PHASE 5") — 2026-08-25 ✅

Kế hoạch gốc kết thúc ở Phase 4; phần này là vòng kiểm chứng độc lập sau khi release lên kệ:

| Kiểm chứng | Kết quả |
|---|---|
| Tag trên remote | `v2.0.1` (annotated `0d89b34`) trỏ đúng commit CI-green `5526b41` |
| Repo state | local HEAD = origin/main = `3532115`, working tree sạch |
| Toàn vẹn artifact | Installer tải lại từ GitHub Release có SHA-256 **trùng tuyệt đối** với manifest/Desktop: `9eea021a…5fd9b` — round-trip PASS |
| Release hiển thị | `draft=false`, `prerelease=false`, body 2.410 ký tự đủ Bảo mật / Tối ưu / Chất lượng / hướng dẫn SHA |
| CI trạng thái | Run mới nhất của `ci-windows.yml`: success |

**Chu kỳ phát hành v2.0.1 đóng hoàn toàn.** Quirks đã ghi nhận cho chu kỳ sau: Inno Setup compile ghi lại bytes `installer/app_icon.ico` (cùng kích thước) mỗi lần build installer — vô hại nhưng làm dirty working tree; contract-test ghim version string phải được cập nhật cùng lúc với version bump (bài học Phase 4).
