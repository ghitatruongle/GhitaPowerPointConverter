# KẾ HOẠCH PHÁT HÀNH v2.0.5 (DEMO → BETA1 → BETA2 → BETA3 → STABLE)

> Ngày lập: 2026-08-28 · Điểm xuất phát: commit `1b7b19d` (v2.0.1 stable), local = GitHub 100%, working tree sạch
> Chủ đề v2.0.5: **"Rust Core + Trải nghiệm mượt"** — rust hóa có chọn lọc các đường nóng + lớp tính năng beta mới
> Nguyên tắc xuyên suốt: **đo rồi mới sửa** · mọi module Rust có **Dart fallback** · zero-telemetry giữ nguyên
> Cấu trúc: **mỗi phiên bản = n track, mỗi track = 10 phase đánh số** (chuẩn ROADMAP v2.0.0) — tổng **25 track × 10 phase = 250 phase**
> Đánh số track liên tục T01→T25; phase của một track được trích là `Txx.p` (vd `T03.7`)

### ✅ KẾT QUẢ T01 (2026-08-29) — Track 1 hoàn thành, chưa commit (chờ duyệt)

**Quyết định cấu trúc T01.1** (ghi nhận từ khảo sát FRB 2.13.0): dùng layout chuẩn FRB —
crate Rust tại **`rust/ghita_core`** (workspace `rust/Cargo.toml`, cdylib tên `ghita_core`), glue plugin build tại **`rust_builder/`** (FRB `integrate` chỉ tạo glue + deps, KHÔNG tạo crate → crate dựng tay đúng template); `flutter_rust_bridge.yaml` ở root (`rust_input: crate::api` / `rust_root: rust/` / `dart_output: lib/src/rust`). **Version pin: flutter_rust_bridge 2.13.0 (dart + codegen), Rust stable 1.98.0, Flutter 3.44.9.**

**Bằng chứng hoàn thành:** `flutter analyze` 0 issues · suite **1017/1017 xanh** (1010 cũ + 7 test mới trong `test/rust_engine_test.dart`: 6 unit fallback/retry/prefs + 1 widget test Engine card) · crate `cargo build --release` exit 0 · **build Debug + Release đều pass** (Debug: `ghita_core.dll` 881 KB cạnh exe; Release: DLL 357 KB, PE32+ x86-64) · **cuộc gọi Dart→Rust THẬT đã E2E** — `flutter test integration_test/rust_engine_probe_test.dart -d windows`: nạp `ghita_core.dll` thật trong tiến trình app, `hello_zip()` trả `ghita_core 0.1.0`, dòng trạng thái Settings hiện "Running on the Rust engine (ghita_core 0.1.0)" · smoke launch exe Release sống >6 s · l10n audit CLEAN · CI cài Rust toolchain (dtolnay/rust-toolchain@stable) · `verify_release.ps1` smoke install kiểm luôn `ghita_core.dll`.

**Api hiện tại:** `hello_zip()` (Rust `api::engine`) trả về `ghita_core <version>` — mốc nền để T02 đặt `ghita_zip` lên đó. Lưu ý loader: non-packaged (`flutter run`/integration test) nạp từ `rust/target/release/` theo CWD; app đóng gói nạp `ghita_core.dll` cạnh exe.

---

## PHẦN A — PHÂN TÍCH DỰ ÁN THAM KHẢO

### A.1 Cầu nối Dart ↔ Rust

| Tham khảo | Trạng thái (2026-08) | Kết luận |
|---|---|---|
| **flutter_rust_bridge (FRB) v2.13.0** | Chuẩn thực tế: codegen type-safe, async worker pool, zero-copy, cargokit tự build trong `flutter build windows` | **CHỌN** cho toàn bộ module `ghita_*` |
| **rinf** | Message-passing sidecar — phù hợp IPC hơn compute granular | Chỉ tham khảo mô hình lazy-load |
| **Tauri v2** | Đóng gói desktop Rust, DLL nhỏ | Tham khảo kinh nghiệm DLL + antivirus, giữ shell Flutter |

### A.2 Crate Rust ứng viên (map vào code hiện tại)

| Crate | Thay cho | Số đo v2.0.1 | Ưu tiên |
|---|---|---|---|
| `zip` + `deflate` | Dart `archive` (PPTX/.ghita) | ZIP 13–17 ms deck text; **chưa đo deck media lớn** | **P0 (demo)** |
| `image` + `rayon` + `sha2` | Dart `image` (decode/encode/EXIF/dedupe) | Chưa có benchmark | **P0 (beta1)** |
| `lol_html`/`html5ever` | Dart `html` parse | 23–37 ms/slide — chỉ làm nếu profile ≥15% thời gian export | P2 (beta2, có điều kiện) |
| `quick-xml` | Build XML | Ấm 4,5 ms — đã khỏe | ❌ Loại |
| `pdf-writer` | Dart `pdf` | 269 ms — khỏe, đụng = viết lại 1900 dòng | ❌ Loại |
| `fontdb`+`swash` | `text_metrics_service` | Sai số layout 10,3% | P2 option (beta2) |

Tham khảo OOXML: ECMA-376 + `python-pptx` (hành vi); `docx-rs` chỉ xem cấu trúc — writer DOCX tự viết Dart bằng `xml` đã có.

### ✅ KẾT QUẢ T05 (2026-08-31) — Track 5 hoàn thành — MỐC DEMO ĐỦ 100%, chưa commit (chờ duyệt)

| Phase | Kết quả |
|---|---|
| T05.1 Coverage | **51,9%** ex-l10n (từ 51,0% v2.0.1) — **ĐẠT ratchet ≥51,5%** (bổ sung 3 widget-test `test/layout_picker_test.dart` phủ ~160 dòng dialog 0%); tool floor 47% đạt; 1041 tests |
| T05.2 Suite ×2 | **1038/1038 xanh ×2** liên tiếp (một lần flake ngẫu nhiên khi chạy coverage, chạy lại sạch — ghi nhận) |
| T05.3 Privacy | **0 kết nối TCP outbound trong 7s** đầu trên exe Release (Get-NetTCPConnection theo giây), app sống — Rust thêm 0 call startup |
| T05.4 Analyze + l10n | `flutter analyze` 0 issues · l10n audit CLEAN |
| T05.5 CI local sim | Release build pass (114,4s) + Debug pass (31,0s) với Rust toolchain stable-msvc local |
| T05.6 Installer | `GhitaPPT-Setup-2.0.5-demo.exe` (15,17 MB) · **verify_release.ps1 -SmokeInstall -SmokeLaunch → SmokeInstall Passed · SmokeLaunch Passed · Validation Passed** (kiểm cả ghita_core.dll trong cài đặt) |
| T05.7 Cài thử + checklist | File [installer/demo_manual_checklist.md](D:\GhitaPPT\installer\demo_manual_checklist.md) — phần tự động đã liệt kê + mục thủ công chờ bạn bấm qua |
| T05.8 Version | Đồng bộ `2.0.5-demo+4` ở 3 chỗ (pubspec / README / .iss `MyAppVersion 2.0.5.4` + DisplayVersion `2.0.5-demo+4`) + `build_info.dart` + **grep ALL**: update 3 test pin (release_2_0_0_official, v2_0_1_beta_contract, ui_layout_audit); chỉ còn refs lịch sử (docs benchmark/comment "v2.0.1 P3b") |
| T05.9 Changelog + commit | CHANGELOG đủ [2.0.5-demo] T01–T04; **commit `v2.0.5-demo` CHƯA chạy — đúng quy tắc chờ bạn duyệt commit (bài học revocation)** |
| T05.10 Desktop + memory | Installer + `GhitaPPT-Setup-2.0.5-demo.exe.sha256.txt` (SHA 973e4bb9…) đã ra Desktop · memory cập nhật status demo |

> Manifest installer: version 2.0.5-demo+4 · SHA256 973e4bb986ec58c811467897474ba287497ea81bc00bb6aab1801888c404fec9 · sourceRevision 1b7b19d (local, dirty) · NotSigned (bản demo, không sign như stable).

### ✅ KẾT QUẢ T04 (2026-08-29) — Track 4 hoàn thành, chưa commit (chờ duyệt)

**N2 Image Optimizer v2 (beta flag):** `image_optimizer_service.dart` (ImageOptimizerConfig + ImageOptimizationStats); hook vào `HtmlImageLoader` (chất lượng hiệu dụng theo config, tally savings); Settings → Engine có toggle "Tối ưu ảnh (beta)" + persist prefs; worker nhận flag qua job message (ppt/pdf/html), savings trả về host qua reply; export dialog snackbar "Tiết kiệm: X KB (Y%) (N ảnh)"; i18n 3 key mới EN=VI.

**Bằng chứng:** `test/image_optimizer_optimization_test.dart` **5/5** — **deck 10 ảnh: tiết kiệm 54,0% (4.462 KB → 2.053 KB) đạt gate ≥40%** · flag OFF bit-perfect (2 lần xuất cùng byte, không tally) · alpha + ảnh <512px giữ PNG · EXIF vẫn bake khi bật flag · ảnh hỏng không crash (warning) · `flutter analyze` 0 · suite **1034/1034 xanh** · l10n audit CLEAN · CHANGELOG [2.0.5-demo] T04. Lưu ý: pipeline convert PNG→JPEG đã có từ Track 03 (allowJpeg=true ở đường xuất thật) — N2 thêm lớp điều khiển chất lượng + thống kê + UI, không đổi ngữ nghĩa cơ bản.

### ✅ KẾT QUẢ T03 (2026-08-29) — Track 3 hoàn thành, chưa commit (chờ duyệt)

**N1 DOCX Report Export:** `docx_report_service.dart` (WordprocessingML tối giản ECMA-376: Content_Types + rels + document.xml + core.xml; format trực tiếp bold/size, không tham chiếu styles; XmlBuilder cho escape tiếng Việt + `_cleanText` cắt control char). Export dialog: chip "Word report (.docx)", tùy chọn "Kèm danh sách slide" (i18n EN=VI), `ExportOptions.docxIncludeSlideList`, routing trong `exportWithOptions`.

**Bằng chứng:** test `docx_report_service_test.dart` **6/6** (cấu trúc package + content-types/rels, escape `& < "` + tiếng Việt nguyên vẹn, notes dài × deck 100 slide, tắt từng tùy chọn, deck rỗng bị từ chối) · **mở bằng Microsoft Word 16.0 thật (COM): OPEN_OK — 15 paragraph, chữ đầu "Báo cáo demo", KHÔNG repair prompt** (build/t03_docx_probe.docx) · `flutter analyze` 0 · suite **1029/1029 xanh** (regression PPTX/PDF/HTML không đổi) · CHANGELOG [2.0.5-demo] T03 + README Export Formats. Lưu ý: máy không có LibreOffice — mốc mở thật dựa trên Word; thêm LibreOffice nếu cho phép ở checklist thủ công.

### ✅ KẾT QUẢ T02 (2026-08-29) — Track 2 hoàn thành theo kết quả đo, chưa commit (chờ duyệt)

**Đã làm:** module `ghita_zip` — crate `zip` 8.6.0 (zlib-rs) + `zip_archive()` qua FRB; `ZipCodec` facade (routing + auto-fallback); wire vào PPTX (`generatePPT`/export isolate/dialog xuất) + `.ghita` (`saveProjectBundle`); engine pref truyền qua job message cho worker; Settings Engine điều khiển backend; unit test deterministic (`useEngineZip=false` mặc định, caller thật bật `true`).

**Kết quả đo** (`tool/benchmark_results_media.md` — deck 20 slide, 21,1 MB, chạy 3 lần):

| Kịch bản | Dart (đường hiện tại) | ghita_zip (Rust) |
|---|---|---|
| Deck media 21,1 MB (text deflate + media stored) | **105–119 ms** | 132–142 ms |
| Text-only 4,5 MB (42 XML × 70 KB) | 68,7–71,2 ms | **19,1–29,6 ms** |

**Gate T02.7 — KHÔNG ĐẠT media ≥30% nhanh hơn** (Rust chậm 15–20%: FRB copy 21 MB media nuốt lợi thế; media stored nên Rust không nén thêm gì). Theo stop rule "đo rồi mới sửa": **giữ Dart làm mặc định** — Rust chỉ dùng khi user bật ở Settings (nơi nó thắng 2,4–3,6× trên deck nặng text). Đề xuất cho beta2 (T13.6): API streaming file→file bỏ copy — chỉ làm nếu profile chứng minh.

**Bằng chứng:** crate Rust test 2/2 · `test/zip_codec_test.dart` 6 test (routing/fallback/round-trip bit-perfect/corrupt) · integration probe **4/4** E2E trong app Windows thật — (1) DLL nạp thật + version trong Settings; (2) PPTX encode đầy đủ qua ghita_zip (`lastBackend=='rust'`) + **strict OOXML validation toàn gói** (mọi XML part parse được, Content_Types phủ đủ mọi part, mọi rels target resolve — gate tự động "không repair prompt"); (3) codec round-trip từng byte; (4) **`.ghita` bundle round-trip qua DLL thật**: saveProjectBundle(useEngineZip:true) → loadProjectBundle, manifest/slides/media bytes khớp + media extract đúng · **PPTX engine mở bằng PowerPoint 16.0 thật (COM): `OPEN_OK slides=1` — không repair prompt** (file tại build/t02_engine_probe.pptx) · `flutter analyze` 0 · suite **1023/1023 xanh** · benchmark tool khóa sàn chạy trong mỗi suite.

**Bài học:** (1) `FRB integrate` không tạo crate — dựng tay; (2) zip 8.6 từ chối compression_level trên entry Stored — chỉ gán level cho deflated; (3) lỗi "initialize twice" = đã init — phải coi là ready, không fallback; (4) CWD `flutter test` = project root là đường load DLL non-packaged chuẩn.

## PHẦN B — PHÂN TÍCH CODE HIỆN TẠI

- 309 file Dart (~81k dòng), 90+ service đều code thật, không stub; 1010 test xanh; coverage 51,0%.
- Baseline v2.0.1 (`tool/benchmark_results_t01/t02/t07.md`): PPTX 35,2 ms / PDF 269 ms / HTML ~98 ms (20 slide); startup 430 ms median; deck HTML 10 slide/10 ảnh = 20,4 KB.
- FFI hiện chỉ có Win32 eyedropper; **chưa có Rust nào**; CI chưa cài Rust toolchain.
- **3 tính năng beta chọn cho v2.0.5**: **N1** DOCX Report Export · **N2** Image Optimizer v2 · **N3** Instant Export (progress + cancel, 100+ slide không khóa UI).

## PHẢN HỒI THỬ NGƯỜI DÙNG (2026-08-31) — ưu tiên chuẩn hóa

| # | Phản hồi | Hướng xử lý | Ưu tiên |
|---|---|---|---|
| F1 | "Ảnh cũng thông báo hiện render, mãi không tự tắt" — sau khi thao tác thêm ảnh/xoá slide, một thông báo hiện không tự biến mất | **ĐÃ SỬA 2026-09-01**: gốc rễ THẬT = Flutter 3.44 mặc định `SnackBar.persist = (action != null)` — snackbar **có action → không bao giờ tự tắt** (chỉ tắt khi bấm action/close). Fix: `showAppSnackBar` ép `persist: false` + `clearSnackBars` (replace thật) → tự tắt đúng 3s, Undo vẫn bấm được; áp toàn bộ editor (delete/undo, delete-all, ~30 insert) + Ctrl+Delete (home) + Recent "Dự án mới"; 5 test helper + 1 regression xoá thật qua EditorShell; suite 1047/1047 | Cao ✅ |
| F2 | Animation hạn chế | **v2.0.5-alpha — track T23** (giữa beta3 và stable) — animation per-element: entrance/emphasis/exit + trigger/delay/duration, Present preview + PPTX/HTML export chuẩn | Trung |
| F3 | Mẫu PPT quá đơn giản (5 template hiện tại) | **v2.0.5-beta2, track T17** (xem mốc 3 bên dưới) — thiết kế lại 5 bộ template hiện đại + preview + i18n + test + ma trận, để vào stable v2.0.5 | Trung |

## PHẦN C — KIẾN TRÚC CHUNG (cả 6 mốc)

1. **Fallback-first**: module `ghita_*` kèm đường Dart cũ; Settings chọn Engine Rust/Dart; DLL nạp lỗi → tự rơi Dart.
2. **Privacy**: crate thuần local; mỗi mốc chạy lại bài 0-TCP 7 giây lúc startup.
3. **CI/Installer**: `ci-windows.yml` thêm Rust toolchain; Inno kèm DLL; `verify_release.ps1` kiểm DLL + smoke.
4. **Version**: `2.0.5-demo+4` → `2.0.5-beta.1+5` → `2.0.5-beta.2+6` → `2.0.5-beta.3+7` → `2.0.5+8`; commit verbatim; **chỉ stable có tag + GitHub Release**; installer mỗi mốc ra Desktop + SHA256.

---

# MỐC 1 — v2.0.5-DEMO: "Tính năng beta đầu tiên + rust hóa nhẹ" (~4–5 ngày) — 5 TRACKS

> Cổng ra mốc beta1: N1 dùng được · ghita_zip đạt mốc benchmark · suite xanh ×2 · installer + DLL smoke OK · CI GitHub xanh trước commit `v2.0.5-demo`

## Track T01 — Rust Foundation (RF)

1. Khảo sát FRB v2.13 + cargokit trên Flutter Windows; chốt cấu trúc `native/ghita_core` (workspace crate cdylib)
2. Thiết kế API Dart↔Rust tổng thể: facade RustEngine + auto-fallback Dart khi nạp DLL lỗi
3. Tạo crate + codegen "hello zip" qua FRB; Dart gọi được hàm Rust thật
4. Tích hợp build Windows: cargokit chạy trong `flutter build windows`; debug + Release đều pass
5. Settings mới: chọn Engine Rust/Dart (mặc định Rust khi qua gate) + hiển thị trạng thái engine
6. Auto-fallback: bắt lỗi nạp DLL → rơi Dart + thông báo; không crash
7. CI `ci-windows.yml`: bước cài Rust toolchain (stable-msvc) trước `flutter build`
8. Mô phỏng đủ matrix CI local (drift MSVC windows-latest) trước khi push
9. Installer Inno kèm DLL; `verify_release.ps1` kiểm DLL tồn tại + smoke launch
10. Widget test fallback + i18n chuỗi Settings/thông báo EN/VI + CHANGELOG dòng đầu

## Track T02 — Rust Module ghita_zip (RM)

1. **Benchmark mới: deck media lớn** (20 slide × ảnh 2–5 MB, ~100 MB) đo đường Dart `archive` → `tool/benchmark_results_media.md`
2. Thiết kế API ghita_zip: nén text mức cao, media stored, chunk streaming, không block UI
3. Viết module Rust (`zip` + `deflate`), test đơn vị Rust trong crate
4. Codegen FRB + Dart facade có fallback (khớp kiến trúc T01.2)
5. Wire vào đường PPTX của `ppt_generator` (engine config quyết định Rust/Dart)
6. Wire vào `project_bundle_service` (.ghita)
7. Đối chiếu benchmark T02.1: media lớn **≥30% nhanh hơn**; deck text không chậm hơn 10%
8. Test tính đúng: PPTX mở bằng PowerPoint, .ghita round-trip, file corrupt không crash
9. Benchmark khóa sàn trong `test/` (mốc sàn mới cho các mốc sau)
10. i18n + CHANGELOG kèm số đo trước/sau

## Track T03 — N1: DOCX Report Export (N)

1. Khảo sát `outline_export_service` + pattern `pdf_export_service` (lấy nội dung deck → tài liệu)
2. Thiết kế schema DOCX báo cáo: outline + speaker notes + danh sách slide (tham chiếu ECMA-376)
3. Viết `docx_report_service.dart` bằng package `xml` (đã có sẵn)
4. UI: export dialog thêm định dạng "Báo cáo Word (.docx)" + tùy chọn nội dung (outline/notes/slide list)
5. i18n EN/VI toàn bộ chuỗi mới
6. Test round-trip: mở lại file bằng parser, kiểm cấu trúc package DOCX
7. Test nội dung: tiếng Việt unicode, notes dài, deck 100 slide
8. Regression: PPTX/PDF/HTML không đổi bit nào
9. Manual checklist Windows + mở thật bằng Word/LibreOffice
10. CHANGELOG + README mục Export Formats

## Track T04 — N2: Image Optimizer v2 dạng flag beta (N)

1. Khảo sát `html_image_loader` + đặc điểm ảnh trong deck thực tế (định dạng/kích thước)
2. Thiết kế ngưỡng nén: PNG→WebP/JPEG theo ngưỡng, giữ PNG khi cần trong suốt
3. Viết optimizer Dart (package `image`) + module thống kê tiết kiệm
4. Settings: toggle beta flag + mô tả rõ "thử nghiệm"
5. Wire vào export pipeline khi flag bật (tắt flag = hành vi cũ bit-perfect)
6. UI kết quả: "Tiết kiệm X KB (Y%)" sau export
7. Test: deck 10 ảnh giảm **≥40%** dung lượng khi bật
8. Test ảnh biên: PNG trong suốt, ảnh nhỏ, EXIF xoay, ảnh hỏng
9. i18n + l10n audit
10. CHANGELOG

## Track T05 — Quality & Ship bản demo (Q+S)

1. Coverage ratchet ≥51,5% + gap list cho mốc sau
2. Full suite (≥1010 test) xanh ×2 liên tục
3. Kiểm chứng privacy: 0 kết nối TCP 7 giây đầu sau khi thêm Rust/DLL
4. `flutter analyze` 0 issues + l10n audit CLEAN
5. Mô phỏng đủ matrix CI local (Rust + Flutter + drift MSVC)
6. Build installer + `verify_release.ps1 -SmokeInstall -SmokeLaunch`
7. Cài thử + checklist thủ công tính năng chính (N1/N2/export)
8. Version 3 chỗ = `2.0.5-demo+4` (pubspec / `.iss` / README) + grep ALL version pin
9. CHANGELOG `[2.0.5-demo]` + commit verbatim `v2.0.5-demo` chỉ sau khi CI GitHub xanh 100%
10. Installer + SHA256 ra Desktop + cập nhật memory

---

# MỐC 2 — v2.0.5-BETA1: "Nâng cấp beta features + tối ưu + tăng tốc" — **✅ HOÀN THÀNH 2026-09-01** (6 TRACKS T06–T11)

> Cổng vào: re-run benchmark đối chiếu demo. Cổng ra beta2: ghita_image ≥3× · N2 gỡ flag · N3 dùng được · mọi tối ưu có số.

## Track T06 — Rust Module ghita_image (RM)

1. Baseline benchmark decode/encode 20 ảnh đường Dart `image`
2. Thiết kế API: decode / resize / re-encode / EXIF xoay / dedupe-hash
3. Viết module Rust (`image` + `rayon` + `sha2`), đa luồng, test trong crate
4. Codegen FRB + Dart facade fallback (kiến trúc T01)
5. Wire vào pipeline export + `html_image_loader`
6. Đối chiếu: **≥3× nhanh hơn** đường Dart trên cùng máy
7. Test biên: ảnh hỏng, PNG trong suốt, EXIF, ảnh lớn (50 MP)
8. Benchmark khóa sàn trong `test/`
9. Dedupe hash dùng chung cho media rels PPTX (1 ảnh nhiều slide = 1 lần nhúng)
10. i18n + CHANGELOG số đo

## Track T07 — N2 Image Optimizer hoàn chỉnh (N)

1. Chuyển backend N2 sang ghita_image (Dart giữ làm fallback chọn được)
2. Mở rộng chất lượng theo `ExportQuality` (150/300/600) như Track 03 ROADMAP
3. UI thống kê + preview trước/sau dung lượng
4. Gỡ chế độ "beta flag" thành tùy chọn thường trong Settings
5. Cache đĩa ảnh đã tối ưu (không encode lại mỗi lần export)
6. Test regression: chọn Dart → **bit-perfect** giữ nguyên như demo; so sánh Rust vs Dart bằng **pixel-diff/PSNR + báo độ lệch byte** (không ép bit-perfect — encoder Rust `image` và Dart lệch vài bit do quantization JPEG)
7. Test giữ mốc: deck 10 ảnh giảm ≥40%
8. Manual checklist scaling 100/125/150%
9. i18n + audit
10. CHANGELOG + số đo

## Track T08 — N3 Instant Export (N)

1. Khảo sát `export_job`/`export_isolate` hiện tại: progress + cancel đã tới đâu
2. Thiết kế chuẩn `ExportJob` v2: progress % theo slide + cancel token dùng chung 3 định dạng
3. PPTX: wire progress/cancel qua isolate
4. PDF: wire progress/cancel (kể cả notes pages/bookmarks)
5. HTML: wire progress/cancel
6. UI export dialog: progress bar + nút Hủy + trạng thái slide đang xử lý
7. Test: UI phản hồi <100 ms trong lúc export deck 100 slide
8. Test cancel giữa chừng: sạch file tạm, không file corrupt
9. i18n ("Đang xuất… x/y", "Hủy xuất") EN/VI
10. CHANGELOG

## Track T09 — Tối ưu thuật toán & tăng tốc (O)

1. Re-run toàn bộ benchmark (t01/t02/t07/media) — bảng đối chiếu demo vs v2.0.1
2. Chốt hotspot bằng số (bảng mới, có bằng chứng)
3. Cache parse HTML theo hash nội dung — parse 1 lượt dùng chung PPTX/PDF/HTML
4. Tối ưu player HTML deck nếu số chỉ ra (dedupe keyframes/media)
5. Tối ưu đường build XML **chỉ nếu** hotspot (không refactor cấu trúc lớn)
6. Mỗi tối ưu = 1 commit riêng + số đo trước/sau
7. Đo lại ngay sau từng tối ưu (không gộp đo)
8. Loại bỏ tối ưu không chứng minh được bằng số
9. Cập nhật `tool/benchmark_results_*.md` nhãn beta1
10. CHANGELOG tổng hợp số tăng tốc

## Track T10 — Quality & Ship beta1 (Q+S)

1. Coverage ratchet ≥52%
2. Full suite xanh ×2
3. 0-TCP startup sau các thay đổi
4. `flutter analyze` 0 + l10n audit CLEAN
5. Mô phỏng matrix CI local
6. Build installer + verify smoke
7. **Cài đè demo → beta1** (deck demo/project cũ mở được, prefs + API keys giữ nguyên) + cài thử + checklist beta (N1/N2/N3)
8. Version 3 chỗ = `2.0.5-beta.1+5` + grep ALL
9. CHANGELOG `[2.0.5-beta.1]` + commit `v2.0.5-beta1` sau CI GitHub xanh
10. Desktop + SHA256 + memory

## Track T11 — Sweep thông báo toàn app (Q; phản hồi người dùng 2026-09-01)

> Gốc rễ phát hiện khi fix F1: Flutter 3.44 đổi mặc định `SnackBar.persist = (action != null)` — mọi snackbar **có action không tự tắt**; đồng thời còn ~100 chỗ `showSnackBar` thô ở các màn ngoài editor vẫn queue. Phải hoàn tất sweep để lỗi không tái sinh ở màn khác.

1. Inventory: liệt kê toàn bộ `showSnackBar` thô còn lại ngoài helper (AI Chat, Home, Settings, Theme, Provider, Shortcuts, Export dialogs, sorter…) + đánh dấu chỗ có action/hardcode
2. Chuyển toàn bộ sang `showAppSnackBar` (replace + `persist: false`), giữ duration hợp lý (1s notify, 3s undo, 4s error)
3. Chuỗi hardcode EN/VI trong snackbar → l10n key (EN + VI .arb), viết lại mô tả nhất quán
4. Thống nhất thói quen hiển thị: chỉ một snackbar mỗi lần, không xếp hàng toàn app
5. Test widget cho từng nhóm ở lại: replace, auto-dismiss có/không action, action bấm được
6. Regression EditorShell xóa slide + Delete All (giữ test sẵn từ F1)
7. Grep gate: 0 `showSnackBar` thô + 0 chuỗi thông báo hardcode trong `lib/`
8. i18n audit CLEAN + `flutter analyze` 0
9. Check 0-TCP + smoke nhanh (thông báo không phát sinh netcode)
10. CHANGELOG + đánh dấu F1 "đủ 100% toàn app"

---

# MỐC 3 — v2.0.5-BETA2: "Sửa lỗi + hoàn thiện + rust hóa hoàn chỉnh" (~3–4 ngày) — 5 TRACKS

> Cổng vào: không bug P1/P2 mở từ beta1. Cổng ra beta3: bảng bug trống P1/P2 · quyết định go/no-go htmlparse có số · fallback bền.
> **Bổ sung phản hồi người dùng:** track **T17 — F3: Template refresh** (thiết kế lại 5 mẫu PPT) chạy song song trong mốc này; F2 (animation per-element) là mốc **v2.0.5-alpha (T23)** chạy sau beta3.

## Track T17 — F3: Template refresh (phản hồi người dùng 2026-08-31)

1. Audit 5 template hiện tại (`assets/templates/`): layout, màu, font, độ dùng được thực tế
2. Chốt bản thiết kế mới cho 5 bộ (Business/Creative/Academic/Marketing/Minimal) — 2–3 layout mỗi bộ
3. Viết HTML template mới (tái dùng cấu trúc `.ghita`/HTML hiện có, giữ data-bg-color + notes)
4. Preview từng template mới trong Template Studio (không vỡ layout scaling 100/125/150%)
5. i18n: tên/mô tả template (EN=VI) vào .arb
6. Test: chọn template → slide tạo ra đúng cấu trúc; xuất PPTX/PDF/HTML không lỗi
7. Không regression: template cũ còn dùng được (fallback) + l10n audit CLEAN
8. Ảnh minh hoạ/tài nguyên nhẹ (nén như bộ logo) — installer không phình
9. Ứng dụng giữ đúng tính năng "recommended transitions + accent colors" theo bộ
10. CHANGELOG + ma trận template mới (trước khi T21 chốt "ĐỦ 100%")

## Track T12 — Bug sweep tính năng beta (B)

1. Manual checklist N1 DOCX trên scaling 100/125/150%
2. Manual checklist N2 với deck ảnh thực tế (nhiều định dạng)
3. Manual checklist N3: hủy giữa chừng, deck 100+ slide, máy yếu
4. Checklist module Rust: fallback, DLL hỏng, đổi engine lúc chạy
5. Tổng hợp bug vào bảng P1/P2/P3 (file kế hoạch, phần kết quả track)
6. Fix P1 — mỗi bug viết test hồi quy **trước** khi fix
7. Fix P2 — cùng quy tắc
8. Fix P3 + polish nhỏ phát sinh
9. Suite xanh ×2 sau mỗi fix
10. Đóng bảng bug + CHANGELOG

## Track T13 — Rust hóa hoàn chỉnh: go/no-go + ghita_zip chốt (RM)

1. Profile parse HTML trên deck 100 slide: % tổng thời gian export
2. Quyết định go/no-go `ghita_htmlparse` theo ngưỡng **≥15%** — ghi số vào kế hoạch
3. Nếu GO: thiết kế tokenizer một-lượt dùng chung PPTX/PDF/HTML
4. Nếu GO: viết module + facade fallback
5. Nếu GO: wire 3 đường export + benchmark đối chiếu
6. Hoàn thiện ghita_zip: tinh chỉnh mức nén text vs stored theo số đo
7. Chunk lớn → async, không block UI thread
8. Benchmark cuối toàn bộ module Rust (bảng tổng)
9. Test hồi quy toàn bộ engine sau thay đổi
10. CHANGELOG (kèm lý do có số nếu NO-GO — không rust hóa cho có)

## Track T14 — Fallback & độ bền engine (RF)

1. Test giả lập DLL hỏng / sai phiên bản → rơi Dart sạch sẽ
2. Thông báo người dùng khi fallback + hướng dẫn xử lý
3. Audit log: không PII, không network
4. Settings hiển thị trạng thái engine hiện tại (Rust/Dart/fallback)
5. Test nạp lỗi lúc khởi động + giữa phiên
6. Nâng cấp cài đè: mismatch DLL cũ/mới giữa các mốc beta
7. i18n toàn bộ thông báo
8. Chạy lại 0-TCP sau mọi thay đổi track này
9. Tài liệu kiến trúc fallback cho dev (README/mục dev)
10. CHANGELOG

## Track T15 — Hoàn thiện trải nghiệm N1/N2/N3 (B)

1. Audit UI N1: tùy chọn rõ ràng, lỗi thân thiện, trạng thái export
2. Audit UI N2: thống kê + preview nhất quán
3. Audit UI N3: progress/cancel mượt, không nhảy số
4. Gọn chuỗi i18n EN=VI, audit CLEAN
5. Nhất quán tooltip/shortcut với command palette
6. Dark mode: check mọi dialog mới
7. Accessibility: label nút, focus order
8. README/docs cập nhật 3 tính năng beta
9. Widget test bổ sung phần polish
10. CHANGELOG

## Track T16 — Quality & Ship beta2 (Q+S)

1. Coverage ratchet ≥52,5%
2. Full suite xanh ×3
3. 0-TCP + privacy re-check
4. `flutter analyze` 0 + l10n audit CLEAN
5. Mô phỏng matrix CI local
6. Build installer + verify smoke
7. Cài thử + checklist bug đã fix
8. Version 3 chỗ = `2.0.5-beta.2+6` + grep ALL
9. CHANGELOG `[2.0.5-beta.2]` + commit `v2.0.5-beta2` sau CI GitHub xanh
10. Desktop + SHA256 + memory

---

# MỐC 4 — v2.0.5-BETA3: "Tối ưu hiệu năng + tài nguyên, sạch bug, mượt mà" (~3–4 ngày) — 5 TRACKS

> Cổng vào: beta2 đã chắc. Cổng ra stable: 0 bug mở · RAM/binary có số · ma trận tính năng "ĐỦ 100%".

## Track T18 — Profiling RAM & tài nguyên (O)

1. Chọn công cụ đo khả chuyển: benchmark tất định + script đo RSS (không dựa DevTools tương tác)
2. Đo RAM export deck 100 slide: engine Rust vs Dart
3. Đo phiên dài (mở deck + edit mô phỏng 30 phút)
4. Đo startup + RSS idle (giữ mốc < 150 MB)
5. Bảng số trước/sau làm bằng chứng
6. Chốt top hotspot RAM
7. Giải phóng buffer ảnh sau export (không giữ cache ẩn)
8. Cache đĩa ảnh remote giới hạn LRU
9. Đo lại ngay sau từng sửa
10. Docs số liệu vào `tool/`

## Track T19 — Binary & installer gọn (O/R)

1. Đo kích thước DLL + thành phần đóng góp
2. Profile release Rust: `opt-level`, LTO, `strip`
3. Lazy-load DLL: chỉ nạp khi người dùng chọn engine Rust
4. Audit dependency crate chưa dùng (thủ công qua `cargo tree`)
5. Đo installer tổng — mục tiêu **≤ +5 MB** so với v2.0.1
6. Đo lại thời gian nạp engine sau lazy-load
7. Test API Rust vẫn chạy sau strip/LTO
8. Đối chiếu RAM sau thay đổi track này
9. Docs cấu hình build Rust
10. CHANGELOG

## Track T20 — Sweep nâng cấp cài đè & tương thích (B)

1. Cài đè v2.0.1 → beta3: project cũ mở được
2. Cài đè demo → beta3
3. Cài đè beta1 → beta3
4. Cài đè beta2 → beta3
5. Gỡ + cài lại sạch: project/settings giữ nguyên (cam kết installer)
6. Draft auto-save tương thích schema giữa các version
7. .ghita cũ mở bằng beta3 (round-trip version cũ)
8. Wi-Fi deck cũ vẫn chạy với client mới
9. Sửa mọi lỗi lộ ra — test hồi quy riêng từng lỗi
10. CHANGELOG

## Track T21 — Ma trận tính năng "đủ và dùng được" (N/B)

1. Ma trận tính năng v2.0.5: N1/N2/N3 + engine Rust — trạng thái từng mục
2. Rà mỗi tính năng đủ 4 lớp: UI + i18n + test + manual checklist
3. Chạy thủ công toàn bộ ma trận trên Windows thật
4. Sửa gap phát hiện (mỗi gap 1 task nhỏ có test)
5. Không còn tính năng nào treo flag "beta" trừ khi cố ý giữ
6. Cập nhật toàn bộ benchmark khóa sàn (export/deck/image)
7. Full suite xanh ×3
8. Coverage ratchet ≥53%
9. 0-TCP lần cuối
10. Báo cáo ma trận "ĐỦ 100%" (như Phụ lục A của v2.0.1)

## Track T22 — Quality & Ship beta3 (Q+S)

1. `flutter analyze` 0 + l10n audit CLEAN
2. Full suite xanh ×3
3. Coverage giữ ≥53%
4. 0-TCP
5. Mô phỏng matrix CI local (Rust + Flutter + drift MSVC)
6. Build installer + verify smoke
7. Cài thử + nâng cấp cài đè checklist (kết quả T19)
8. Version 3 chỗ = `2.0.5-beta.3+7` + grep ALL
9. CHANGELOG `[2.0.5-beta.3]` + commit `v2.0.5-beta3` sau CI GitHub xanh
10. Desktop + SHA256 + memory

---

# MỐC 5 — v2.0.5-ALPHA: "F2 — Animation per-element" (phản hồi người dùng, ~5–6 ngày) — 1 TRACK

> Chạy SAU beta3, TRƯỚC stable (theo yêu cầu: alpha nằm giữa beta3 và stable; phiên bản cuối trước hardening cuối).
> Cổng vào: beta3 xong (ma trận đủ). Cổng ra stable: animation preview chạy trong Present mode, PPTX/HTML export đúng, PowerPoint mở không repair; mọi hồi quy từ animation được fix xong trong mốc này.
> **Chạy riêng track T23 — đánh số mốc: 1 demo · 2 beta1 · 3 beta2 · 4 beta3 · 5 alpha · 6 stable.**

## Track T23 — F2: Animation theo phần tử (object-level animation)

1. Khảo sát `animation_engine.dart` + `animation_ooxml.dart` hiện tại (transition deck/slide + preview) và mô hình PowerPoint (ECMA-376 p:anim: entrance/emphasis/exit, trigger, delay, duration)
2. Thiết kế model mới: `SlideAnimation` (type: entrance/emphasis/exit, trigger: on-click/timing, delayMs, durationMs, selector phần tử HTML)
3. Mở rộng `Slide` model + JSON serialization — **backward-compat**: deck cũ không có field → rỗng; .ghita cũ mở ok
4. UI Animation pane trong editor: chọn phần tử (h1/p/li…) → thêm hiệu ứng, đặt thời lượng/độ trễ/trigger
5. Pass preview trong Present mode (WebView2): class CSS animation theo từng phần tử + cue timing
6. PPTX export: timing XML (p:tl/p:par/p:anim + seq) cho animation từng phần tử — PowerPoint mở không repair (COM check như T03)
7. HTML deck export: CSS keyframes + class hook từng phần tử (giữ mốc kích thước deck — tối ưu khóa sàn)
8. PDF: render tĩnh (ghi rõ trong docs "animation không áp dụng trong PDF" + test)
9. Test: unit model + OOXML chuẩn + E2E preview + regression deck cũ; i18n EN=VI toàn bộ chuỗi mới
10. CHANGELOG + README mục "Animation theo phần tử" + ma trận (cập nhật map ở beta3 T21)

---

# MỐC 6 — v2.0.5 STABLE: "Hoàn thiện sạch sẽ, bản chính thức" (~2 ngày) — 2 TRACKS

> Cổng vào: ma trận T21 "ĐỦ 100%". Cổng ra: tag `v2.0.5` + GitHub Release sau CI xanh 100%. **Freeze tính năng tuyệt đối.**

## Track T24 — Freeze & Hardening (Q)

1. Ma trận tính năng chốt vs hiện trạng (kết luận ĐỦ/THIẾU từng mục — như F1 v2.0.1)
2. Scope freeze: không nhận feature/fix mới ngoài bug chặn phát hành
3. Full suite (≥1010 test) xanh ×3
4. `flutter analyze` 0 + l10n audit CLEAN
5. Coverage giữ ≥53% (không tụt dưới ratchet beta3)
6. 0-TCP + re-check privacy toàn đường startup
7. Mô phỏng đủ matrix CI (Rust + Flutter + drift MSVC) build Release local
8. Build installer + `verify_release.ps1` + nâng cấp cài đè từ v2.0.1
9. Manual checklist toàn bộ tính năng chính trên Windows thật
10. Báo cáo sẵn sàng phát hành (go/no-go có bằng chứng)

## Track T25 — Ship v2.0.5 (S)

1. Version 3 chỗ = `2.0.5+8` / `MyAppVersion "2.0.5.8"` + `DisplayVersion "2.0.5+8"` / README `v2.0.5`
2. Grep ALL `test/` + `tool/` cho version pin (bài học v2.0.1)
3. CHANGELOG `[2.0.5] - <ngày>` góc nhìn người dùng + mục "Tăng tốc bằng Rust" kèm số trước/sau
4. README: features mới (N1/N2/N3) + kiến trúc Rust + phần Engine settings
5. Commit verbatim `v2.0.5` — chỉ sau khi CI GitHub xanh 100%
6. Tag `v2.0.5`
7. GitHub Release đính installer + checksums
8. Copy installer ra Desktop + lưu SHA256
9. Cập nhật memory: released, tag cuối = v2.0.5
10. Tổng kết bài học Rust/FRB cho vòng sau

---

## SƠ ĐỒ TỔNG & RỦI RO

```
Mốc 1   demo  (~4-5 ngày) : T01-T05      → RF + ghita_zip + N1 + N2(flag)
Mốc 2   beta1 (~5-6 ngày) : T06-T11      → ghita_image + N2 đủ + N3 + tối ưu + sweep thông báo toàn app
Mốc 3   beta2 (~3-4 ngày) : T12-T16 + T17 → bugfix + rust hoàn chỉnh + F3 template refresh
Mốc 4   beta3 (~3-4 ngày) : T18-T22      → RAM/binary + cài đè + ma trận đủ
Mốc 5   alpha (~5-6 ngày): T23           → F2 animation per-element (phản hồi người dùng)
Mốc 6   stable(~2 ngày)  : T24-T25       → freeze/hardening + ship
TỔNG: 25 track × 10 phase = 250 phase · ~25-28 ngày làm việc hiệu quả
```

### Quy tắc dừng (áp cho mọi mốc)

- Profiling/benchmark không chứng minh → **không làm** (không rust hóa cho có, không tối ưu theo cảm tính).
- Bất kỳ test nào đỏ ở track Quality → không sang mốc sau, quay lại track liên quan sửa.
- Bug cấu trúc quá lớn → ghi hạn chế rõ, dời mốc sau; không kéo lịch phát hành.
- Không commit/push nếu CI GitHub chưa xanh 100%; chỉ stable được tag + Release.

### Rủi ro chính

| Rủi ro | Khả năng | Đối phó |
|---|---|---|
| FRB/cargokit xung đột MSVC runner mới | Trung bình | Dart fallback mọi module; track T01 dừng 1,5 ngày → hoãn module Rust sang mốc sau |
| Rust DLL → antivirus false positive | Thấp–TB | Kinh nghiệm Tauri: strip, nén; cân nhắc signing theo quy trình cũ |
| Benchmark media lớn cho thấy Dart đủ nhanh | Trung bình | Bỏ T02 mục 5-6, giữ fallback; ghi lý do có số |
| Scope creep tính năng beta | Cao | Freeze Phase 1 mỗi mốc; tính năng mới → backlog vòng sau |
| Version pin Inno/pubspec/test drift | Đã từng gặp | T05/T10/T16/T21/T25 đều có bước grep ALL |
