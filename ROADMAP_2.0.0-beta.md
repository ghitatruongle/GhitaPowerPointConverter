# ROADMAP — GhitaPPT v2.0.0-beta

> Áp dụng **100 tính năng PPT còn thiếu + 50 điểm tối ưu** (tổng 150 điểm, đã phân tích từ dự án và Microsoft PowerPoint).
> Cấu trúc: **67 track** (tối thiểu 50) × **10 phase/track** (tối thiểu 10) = **670 phase**, gom vào **10 milestone**.
> Trạng thái: ⏳ CHỜ DUYỆT — chưa code, chưa commit, chưa push.

## 0. Quy ước chung (bắt buộc)

| Quy ước | Nội dung |
|---|---|
| V0.1 | Không commit/push bất kỳ thay đổi nào cho tới khi bạn duyệt **từng milestone** (M1→M10) |
| V0.2 | Trong khi dev: nhánh `feature/2.0.0-beta/Txxx`, giữ `version: 2.0.0-beta+1` trong pubspec.yaml |
| V0.3 | ✅ Đã bump `pubspec.yaml` lên **2.0.0-beta+1**; CHANGELOG mục `[2.0.0-beta]` và README đã cập nhật |
| V0.4 | Mỗi track hoàn thành = widget test + chạy `integration_test` + dò lỗi thủ công trên Windows + i18n EN/VI + 1 dòng CHANGELOG |
| V0.5 | Mọi chuỗi UI mới phải vào `lib/l10n/*.arb` (EN + VI) — không hardcode tiếng Việt |
| V0.6 | Mỗi phase kết thúc = báo cáo ngắn (1–3 dòng) cho bạn; track ≠ milestone thì chưa được commit |
| V0.7 | Ưu tiên thứ tự: M1 (nền tảng xuất) → M10 (chất lượng + release) — các milestone độc lập có thể song song nếu bạn muốn |

**Chú giải:** `FEAT n` = điểm tính năng #n trong danh sách 100 (thiếu); `OPT n` = điểm tối ưu #n trong danh sách 50. `🔗` = phụ thuộc track trước.

---

# MILESTONE 1 — Nền tảng tài liệu & Xuất (T01–T07)
> Mục tiêu: engine xuất PPTX/PDF/HTML chính xác, nhẹ, đúng chuẩn — nền cho mọi track sau.
> Cửa sổ duyệt: sau khi xong T07.

## Track 01 — Nền tảng Export Pipeline (OPT 1, 5, 8)
**File chính:** `lib/services/ppt_generator.dart`, `lib/services/export_isolate.dart`, `lib/services/html_export_service.dart`, `lib/services/pdf_export_service.dart`

1. Khảo sát luồng export hiện tại: đo thời gian parse HTML, build XML, nén ZIP cho deck 20–50 slide
2. Thiết kế `ExportJob` chuẩn hóa: input (slides, options) + progress callback + cancel token dùng chung 3 định dạng
3. Cache tokenizer/parser: parse HTML một lần → cây block dùng chung PPTX + PDF (bỏ parse 2 lần/slide)
4. Thêm progress báo % theo từng slide + slide đang xử lý vào `export_isolate.dart` (timeout 2 phút → theo dõi được, hủy được)
5. Tối ưu nén ZIP: chọn mức nén cho text XML (cao) vs media đã nén (stored), giữ fix UTF-8 byte-length đang có
6. Phát hiện & tái sử dụng: không rebuild lại HTML deck trùng nội dung (cache theo hash) trong cùng phiên
7. Đo lại benchmark (thời gian + dung lượng) deck chuẩn 20 slide trước/sau — ghi bảng kết quả
8. Widget test: mô phỏng `ExportJob` cancel giữa chừng, progress tăng đơn điệu
9. i18n: chuỗi "Đang xuất… x/y", "Hủy xuất" vào .arb EN/VI
10. Regression: xuất PPTX/PDF/HTML của deck cũ (v1.6.3) phải mở được, không lệch nội dung — update CHANGELOG

## Track 02 — Bố cục theo font metrics thật (OPT 2)
**File chính:** `lib/services/ppt_generator.dart` (hàm `estimatedHeight`), `lib/services/html_export_service.dart`

1. Liệt kê mọi chỗ ước lượng chiều cao hiện tại (360.000 EMU/dòng, 400.000/bảng…) trong PPTX + PDF
2. Benchmark: so khớp giữa WebView2 (font thật) và ước lượng — đo sai số %
3. Thiết kế `TextMetricsService`: đo text bằng font metrics (dùng `dart:ui`/canvas ngoài isolate hoặc bảng metrics Segoe UI/Calibri kèm sẵn)
4. Build bảng metrics tĩnh cho 3 font mặc định (Calibri, Segoe UI, Arial) + cơ chế fallback
5. Thay thế ước lượng dòng bằng metrics thật trong `estimatedHeight` (text + list)
6. Áp dụng cho bảng (giảm 400.000/dòng → theo cỡ chữ + padding thật)
7. Dò tràn cuối slide: nếu quá sức chứa → co chữ dần (đệ quy 90%/cỡ) như Autofit thu nhỏ
8. Thêm flag "vừa khít" trong hộp thoại export để tắt/tắt tính năng nếu cần
9. Test: 10 slide mẫu có chữ dài/chữ VN có dấu/đậm nghiêng — so ảnh WebView2 vs PPTX(PowerPoint render)
10. Regression + CHANGELOG: ghi rõ "layout chuẩn font metrics" kèm số liệu sai số sau khi sửa

## Track 03 — Ảnh pipeline: dedupe, nén lại, nhúng ảnh remote (OPT 3, 4)
**File chính:** `lib/services/html_image_loader.dart`, `lib/services/ppt_generator.dart`, `lib/models/export_options.dart`

1. Khảo sát `html_image_loader.dart`: điểm nhúng base64/local, chỗ chặn http/https
2. Sửa `HtmlImageLoader` cho phép tải http/https (với timeout 10s, giới hạn 10MB, chỉ image/*)
3. Thêm cache bộ nhớ + cache đĩa (thư mục app cache) cho ảnh remote
4. Dedupe ảnh theo SHA-256 nội dung: 1 ảnh dùng ở nhiều slide chỉ nhúng 1 lần trong media + rels
5. Re-encode: ảnh > ngưỡng chuyển PNG→JPEG (quality theo `ExportQuality` 150/300/600), giữ PNG khi cần trong suốt
6. Xoay EXIF (ảnh chụp điện thoại) trước khi nhúng
7. Giới hạn an toàn: bỏ ảnh lỗi/dirty + ghi lại cảnh báo vào log export
8. Kiểm tra: deck 10 ảnh trùng → dung lượng giảm ≥50% so với trước
9. Cập nhật UI: chuỗi "Đang tải ảnh từ web…" + lỗi "Không tải được ảnh X" vào .arb
10. Regression + CHANGELOG: ảnh remote giờ được nhúng; thống kê dung lượng file giảm

## Track 04 — Theme & Font của file PPTX theo người dùng (OPT 11)
**File chính:** `lib/services/ppt_generator.dart` (`_buildThemeXml`), `lib/theme/app_theme.dart`, `lib/screens/theme_settings_screen.dart`

1. Khảo sát `_buildThemeXml`: theme cứng Calibri/Office hiện tại
2. Thiết kế ánh xạ: ThemeSetting (primary/accent/font) → OOXML clrScheme + fontScheme
3. Sinh `clrScheme` động từ màu người dùng (accent1–6, hlink, folHlink)
4. Ghi font UI người dùng chọn vào majorFont/minorFont (thay vì Calibri cứng)
5. Đảm bảo fallback an toàn: font lạ → PowerPoint tự thay, không lỗi repair prompt
6. Áp dụng đồng bộ vào slideLayout placeholder cũng dùng theme
7. Test: tạo file với theme Custom, mở bằng PowerPoint thật → màu/font đúng, không "Sửa chữa file"
8. Settings: preview nhỏ "File xuất sẽ dùng theme này" ngay trong màn Theme
9. i18n cho chuỗi mới + update CHANGELOG
10. Regression: deck mặc định Office Blue vẫn xuất y hệt v1.6.3 (so ảnh)

## Track 05 — Master & SlideLayout đa dạng (OPT 12)
**File chính:** `lib/services/ppt_generator.dart`, `lib/models/slide_layout.dart` (9 layout)

1. Đối chiếu 9 `SlideLayoutType` (Blank, Title Slide, Title+Content, Section Header, Two Content, Comparison, Title Only, Content+Caption, Picture+Caption) với 9 layout chuẩn PPT
2. Thiết kế `layoutRegistry`: mỗi layout → placeholder map (title/body/caption/picture) + kích thước EMU
3. Sinh nhiều `<p:sldLayout>` trong `ppt/slideLayouts/` + rels đầy đủ (hiện chỉ 1 blank)
4. Sinh `<p:sldLayout>` đúng chuẩn OOXML (cSld, spTree, ph type/index, clrMapOvr)
5. Gán layout phù hợp cho từng slide khi xuất theo `layoutType` (fallback blank nếu lạ)
6. Giữ master dùng chung 1 `slideMaster1.xml` duy nhất (chuẩn PPT cho phép)
7. Test mở trong PowerPoint: chọn đúng layout trong gallery Slide Layout, placeholder hiển thị đúng
8. Sửa `Slide.layoutType` đặt lại khi người dùng đổi layout trong editor (đồng bộ 2 chiều)
9. i18n tên layout + CHANGELOG
10. Regression: xuất deck cũ không set layoutType → vẫn mở bình thường

## Track 06 — PDF export nâng cao (OPT 6, 7)
**File chính:** `lib/services/pdf_export_service.dart`, `lib/models/export_options.dart`

1. Khảo sát pdf_export_service: font fallback Segoe UI→Arial→Tahoma, 1 trang/slide cố định
2. Thêm tùy chọn khổ giấy: A4 / Letter / khớp slide (16:9, 4:3, 1:1, 9:16)
3. Thêm lề tùy chỉnh + Scale-to-Fit (vừa khít, tránh lề trắng 2 bên)
4. Nhúng font con (subset) cho font đang dùng để file giống hệt trên máy không có font đó
5. Giảm kích thước: nén PDF qua chế độ quality thấp cho ảnh trong PDF
6. Tùy chọn in slide ẩn + chọn phạm vi slide (kế thừa `allSlides`)
7. Thêm metadata tài liệu (title/author/created) vào PDF
8. Test: mở PDF trên máy khác không có Segoe UI → chữ VN không vỡ
9. i18n chuỗi option mới + CHANGELOG
10. Regression: xuất PDF mặc định giữ hành vi cũ khi không đổi option

## Track 07 — HTML deck tối ưu (OPT 9, 10)
**File chính:** `lib/services/html_export_service.dart`, `lib/services/effect_preview_service.dart`

1. Đo dung lượng HTML deck chuẩn (10 slide, 10 ảnh) — xác định phần nặng: CSS keyframes / ảnh base64
2. Tách CSS chung 1 lần, mỗi hiệu ứng chỉ 1 class ngắn (bỏ trùng keyframes)
3. Ảnh base64 → lazy load: chia mỗi slide 1 `<template>`/`data-src`, JS nạp khi tới slide
4. Defer toàn bộ JS player, thêm `loading="lazy"`/`decoding="async"` cho ảnh
5. Thêm cache bộ nhớ cho deck đã build (mở trình chiếu lần 2 không rebuild)
6. Giảm dung lượng bằng cách minify HTML/CSS/JS ngay tại export
7. Đo lại: dung lượng giảm %, thời gian tải slide đầu tiên
8. Test player: vẫn đủ phím mũi tên/Space/Home/End/F, auto-play, notes, progress bar
9. i18n chuỗi trong player (nếu có) + CHANGELOG
10. Regression: deck HTML export cũ vẫn chạy đủ 33 hiệu ứng

---

# MILESTONE 2 — Đối tượng nội dung (T08–T20)
> Mục tiêu: người dùng chèn được mọi loại nội dung như PowerPoint: biểu đồ, SmartArt, video, audio, 3D, icons…
> Cửa sổ duyệt: sau khi xong T20.

## Track 08 — Động cơ Biểu đồ thật (FEAT 1, 2)
**File chính:** mới `lib/services/chart_service.dart`, `lib/models/chart_data.dart`, `lib/services/ppt_generator.dart`, `lib/screens/editor/`

1. Thiết kế model `ChartData`: type, series, categories, styles (màu, label, legend)
2. Hỗ trợ nhóm biểu đồ cơ bản trước: Column / Bar / Line / Pie / Area (+ Donut option)
3. Nhóm nâng cao: Combo, Treemap, Sunburst, Histogram, Box & Whisker, Waterfall, Funnel, Map
4. Render PPTX: sinh `<c:chart>` XML package (chart1.xml + embedded xlsx + rels + content-types) đúng chuẩn DrawingML Charts
5. Render PDF: vẽ chart bằng thư viện pdf (custom painter) giữ màu đồng bộ
6. Render HTML preview/WebView2: dùng SVG/Canvas tự sinh (không phụ thuộc thư viện ngoài)
7. UI: dialog "Chèn biểu đồ" — chọn loại, nhập/ánh xạ dữ liệu, chỉnh màu, preview
8. Chỉnh sửa sau khi chèn: click chart → mở lại dialog, cập nhật cả 3 định dạng
9. i18n: tên các loại chart + CHANGELOG
10. Test: mở PPTX trong PowerPoint/LibreOffice — chart hiển thị & chỉnh được dữ liệu

## Track 09 — Khung dữ liệu kiểu Excel + workbook nhúng (FEAT 3)
**File chính:** mới `lib/services/embedded_workbook_service.dart`, `lib/screens/widgets/chart_data_grid.dart`

1. Thiết kế widget `ChartDataGrid`: lưới ô giống Excel thu gọn (A1…, nhập số/tên series)
2. Thao tác lưới: thêm/xóa dòng cột, chọn vùng, dán từ clipboard, auto-fill nhanh
3. Sinh workbook `.xlsx` thật (dùng `archive` tự build, tối thiểu: sheet1 + sharedStrings) nhúng vào chart package
4. Map vùng chọn lưới → `<c:numCache>/<c:strCache>` trong chart XML để PowerPoint hiển thị ngay cả khi chưa mở Excel
5. Đồng bộ 2 chiều: đổi dữ liệu trong lưới → cập nhật chart cả 3 định dạng
6. Nút "Nhập từ CSV/Excel" (file_picker + parse CSV cơ bản)
7. Mở khóa: khi bấm "Chỉnh dữ liệu trong Excel" trên PowerPoint → workbook thật mở ra được
8. Test: nhúng chart → mở PowerPoint → đổi số trong Excel embedded → chart cập nhật
9. i18n + CHANGELOG
10. Regression: chart không data (lỗi) hiển thị thông báo thân thiện, không crash

## Track 10 — SmartArt (FEAT 4)
**File chính:** mới `lib/services/smartart_service.dart`, `lib/models/smartart.dart`

1. Khảo sát 8 nhóm SmartArt PPT: List, Process, Cycle, Hierarchy, Relationship, Matrix, Pyramid, Picture
2. Thiết kế model: `SmartArtGraph` (layout id, nodes, text, colors) + 20–30 layout cơ bản đầu tiên
3. Sinh PPTX: `<dgm:>` Diagram XML (data + layout + rels) theo chuẩn DrawingML Diagrams
4. Sinh HTML/PDF: render thay thế bằng SVG/shape (đủ đẹp cho preview và PDF)
5. UI dialog "Chèn SmartArt": thumbnail layout, nhập text cho từng node (kiểu text pane)
6. Chỉnh màu (3 theme) + đổi layout giữ nguyên nội dung (relayout)
7. Đồng bộ: chỉnh text trong text pane → cập nhật cả 3 định dạng
8. Test: mở PPTX trong PowerPoint → SmartArt hiển thị, đổi layout được
9. i18n + CHANGELOG
10. Regression: deck không SmartArt vẫn xuất chuẩn như cũ

## Track 11 — Video nhúng & chỉnh (FEAT 5, 6, 76)
**File chính:** mới `lib/services/video_embed_service.dart`, `lib/models/media_item.dart`, `lib/services/ppt_generator.dart`

1. Mở rộng `media/` hiện có cho video: đóng gói video file vào `ppt/media/` (mp4)
2. Sinh `<p:video>` + videoFile rels + `<a:videoFile>` + poster ảnh tĩnh (lấy frame đầu)
3. Playback options: auto/on-click, loop, full-screen khi chiếu, ẩn khi không phát
4. Trim video: chọn start/end (không cần re-encode — dùng FFmpeg nếu có, nếu không chỉ ghi timestamps)
5. Poster frame tùy chọn (chọn ảnh khác làm cover)
6. Bookmark video (đánh dấu thời điểm, nhảy tới khi chiếu)
7. Video online: chèn link YouTube → lưu video id + thumbnail (chặn đúng iframe như hiện tại, chỉ hiển thị khi xuất PPTX dạng link)
8. Vì app trình chiếu bằng WebView2: phát video trong slideshow HTML bằng thẻ `<video>` kèm controls
9. i18n + CHANGELOG
10. Test: PPTX có video mở bằng PowerPoint phát được; HTML deck phát được trong WebView2

## Track 12 — Screen Recording (FEAT 7)
**File chính:** mới `lib/services/screen_recorder_service.dart`, `lib/screens/widgets/screen_capture_dialog.dart`

1. Khảo sát khả năng Windows: dùng `desktop_capture`/gói tương đương hoặc FFmpeg nền
2. UI chọn vùng quay: chọn toàn màn hình / cửa sổ / vùng kéo
3. Điều khiển thu: Start/Pause/Stop + đếm ngược 3s, hiển thị timer
4. Lưu MP4 tạm → nhúng vào slide ngay (tái dùng Track 11 pipeline)
5. Xem lại trước khi chèn (preview dialog)
6. Giới hạn: độ dài max, dung lượng max, cảnh báo khi hết đĩa
7. Xử lý lỗi: không có quyền quay màn hình → hướng dẫn bật
8. i18n + CHANGELOG
9. Doc ghi chú giới hạn (cần FFmpeg/plugin Windows tương thích)
10. Test: quay 10s, chèn vào slide, xuất PPTX + HTML, phát lại được

## Track 13 — Audio & Narration gắn slide (FEAT 8, 9 + OPT 31)
**File chính:** `lib/services/audio_recording_service.dart`, `lib/screens/widgets/audio_recorder_panel.dart` (đang chết), `lib/models/slide.dart`

1. Nối lại UI `AudioRecorderPanel` vào editor panel của từng slide (gắn cạnh ô Notes)
2. Ghi âm → m4a/ogg (nén, không WAV cồng kềnh) lưu trong project bundle `.ghita` (media/)
3. Model: `Slide.audioPath` + `Slide.audioEmbedded` — thêm vào toMap/fromMap (tương thích ngược)
4. Nhúng vào PPTX: `<p:audio>` + `a:audioFile` + options (auto/click, loop, ẩn icon)
5. Nhúng vào HTML deck: thẻ `<audio>` player nhỏ trên slide
6. Phát xuyên slide: tùy chọn "play across slides"/loop/hide icon
7. Chỉnh thời lượng & cắt audio nhỏ (start/end)
8. Di chuyển dự án: khi mở `.ghita` khác máy — audio theo bundle (không phụ thuộc Documents)
9. i18n + CHANGELOG
10. Test: ghi âm → xuất PPTX → PowerPoint phát narration đúng slide

## Track 14 — 3D Models (FEAT 10)
**File chính:** mới `lib/services/model3d_service.dart`

1. Khảo sát định dạng: PPT hỗ trợ .glb/.fbx/.obj/.3mf — chọn hỗ trợ GLB trước
2. UI chèn: file_picker bộ lọc 3D + preview thumbnail (render bằng thư viện trung gian hoặc ảnh tĩnh)
3. Đóng gói: nhúng model vào `ppt/media/` + rels kiểu `model3d`
4. Sinh XML `<p:model3d>` theo OOXML Model3D + `<a:model3DRaster>` poster
5. Gán animation tự xoay (rotateY) ở mức poster/trình chiếu
6. Preview trong app: render bằng `flutter_gl`/package tương thích Windows hoặc ảnh poster + badge "3D"
7. HTML export: không nhúng model thật — hiện ảnh poster + ghi chú "mở trong PowerPoint xem 3D"
8. Kiểm tra trong PowerPoint: model xoay được, không lỗi repair
9. i18n + CHANGELOG
10. Test: GLB mẫu 5MB mở được; file không hợp lệ → báo lỗi rõ ràng

## Track 15 — Thư viện Icons & Ảnh kho (FEAT 11, 12)
**File chính:** mới `lib/services/icon_library_service.dart`, `lib/services/stock_media_service.dart`

1. Đóng gói bộ icons: nhúng thư viện Fluent System Icons / Material Symbols dạng SVG (~1000 icon)
2. UI dialog "Chèn icon": search, category, chọn màu tự do, kích thước
3. Nhúng icon vào PPTX: vẽ dạng `<p:pic>` PNG (render SVG→PNG) hoặc giữ dạng shape
4. Nhúng vào HTML/PDF: thẻ inline SVG giữ đúng màu chọn
5. Thêm "Ảnh kho local": bộ ảnh minh họa bundled (~100 ảnh CC0) chọn theo category
6. (Tùy chọn + sau) Tìm ảnh Bing/Unsplash qua API khi có internet: dialog tìm kiếm + kết quả lưới
7. Lịch sử icon/ảnh đã dùng (gần đây) để chèn nhanh
8. Xử lý offline: ảnh kho luôn khả dụng; Bing chỉ khi online (có cache)
9. i18n + CHANGELOG
10. Test: chèn icon vào slide → xuất 3 định dạng → màu sắc đồng nhất

## Track 16 — Screenshot nhanh & Photo Album (FEAT 13, 14)
**File chính:** mới `lib/services/screenshot_service.dart`, `lib/screens/widgets/photo_album_dialog.dart`

1. Screenshot: chụp toàn màn hình / cửa sổ active / vùng chọn (Windows API hoặc plugin)
2. Chụp xong → mở `image_editor_dialog.dart` (đã có) để crop trước khi chèn
3. Photo Album: dialog chọn nhiều ảnh + layout (1 ảnh, 2 ảnh, 1 lớn + nhiều nhỏ, lưới 2×2…)
4. Sinh tự động N slide từ ảnh đã chọn theo layout + chèn vào cuối deck
5. Tùy chọn: thêm caption (tên file/tùy sửa), frame viền, chuyển tiếp mặc định giữa slide ảnh
6. Đồng bộ hóa với `SlideLayoutType.pictureCaption` có sẵn
7. Test với 20 ảnh → 20 slide sinh đúng, không tràn ảnh
8. i18n + CHANGELOG
9. Tối ưu: xử lý ảnh nén khi sinh slide (tái dùng Track 03 pipeline)
10. Regression: luồng chèn ảnh thủ công cũ không đổi

## Track 17 — WordArt & TextBox tự do (FEAT 15, 16)
**File chính:** mới `lib/models/free_shape.dart`, `lib/services/wordart_service.dart`, `lib/screens/editor/canvas_overlay.dart`

1. Thiết kế `FreeTextShape`: x/y/w/h (đơn vị % slide để scale), text, style, z-order
2. Canvas overlay (bổ sung cho `visualElements`/`DraggableElement` đang chết): kéo-thả TextBox trên preview WebView2
3. Tích hợp vào luồng slide: lưu vào `Slide.visualElements`, **engine export ĐỌC thật** (không bỏ qua như hiện tại)
4. WordArt: 12 style gradient/wave/thái độ — sinh shape XML `<a:prstGeom>` + fill gradient + txtEffect
5. TextBox tự do: xoay, trong suốt nền, viền, đổ bóng; giữ vị trí khi xuất PPTX (xfrm trực tiếp, không xếp dọc)
6. HTML/PDF render khớp tọa độ % (position absolute / pdf canvas)
7. Z-order & chọn đối tượng: click chọn, kéo di chuyển, resize 8 handle
8. Xóa/undo tích hợp time-machine (snapshot đã chứa visualElements)
9. i18n + CHANGELOG
10. Test: TextBox đặt 30%,40% → mở PPTX trong PowerPoint đúng vị trí

## Track 18 — Nút hành động, Equation, Symbol, OLE (FEAT 17, 18, 19, 20)
**File chính:** mới `lib/services/action_button_service.dart`, `lib/services/equation_service.dart`, `lib/services/symbol_service.dart`

1. Action buttons: 12 nút chuẩn (home, next, back, end, info, help…) + gán hành động (chuyển slide, mở URL/file, chạy chương trình, phát âm thanh)
2. Sinh XML `<p:sp>` + `a:hlinkClick`/`p:action` (slideJump) + `p:oleObj` cho OLE khi cần
3. Equation: dialog chèn công thức — dùng MathML → OOXML `<a:math>`/OMML (biên dịch mẫu phổ biến: phân số, căn, tổng, tích phân, ma trận)
4. Render HTML/PDF: equation dùng KaTeX/MathJax tự host (thư viện local, không gọi mạng) hoặc render SVG
5. Symbol: bảng ký tự nhóm (đồng tiền, mũi tên, toán, kỹ thuật, chữ cái Hy Lạp, emoji) + ô tìm mã Unicode
6. OLE: nhúng file (Excel/Word/PDF) dạng icon + mở khi double-click (chỉ hỗ trợ Windows hiện hữu)
7. Đồng bộ 3 định dạng cho cả 3 loại nội dung
8. Test: nút Next trên slide 1 → PowerPoint chuyển slide 2 khi chiếu
9. i18n + CHANGELOG
10. Regression: hyperlink text thường vẫn hoạt động như cũ

## Track 19 — Header/Footer & field động (FEAT 21, 24)
**File chính:** mới `lib/services/header_footer_service.dart`, `lib/services/ppt_generator.dart`

1. Thiết kế `DeckMeta`: header, footer, số slide (bật/tắt/định dạng), ngày giờ (tĩnh/động)
2. UI dialog "Chèn Header & Footer" (mở từ ribbon Chèn): áp toàn deck hoặc chỉ slide được chọn
3. Sinh PPTX: `<p:ph type="hdr|ftr|sldNum|dt">` + field `<a:fld>` (slidenum, datetime) trong shape footer
4. Cấu hình qua master để "bỏ qua master" tùy chọn
5. HTML/PDF export: vẽ header/footer ở cùng vị trí chuẩn (pt = EMU)
6. Ngày giờ động: dùng `<a:fld type="datetime1">` để PowerPoint tự cập nhật
7. Xử lý trang đầu (không hiện ở slide bìa) tùy chọn
8. i18n + CHANGELOG
9. Test: mở PPTX → slide 3 hiện "3" đúng vị trí chuẩn; ngày giờ tự đổi khi sửa trong PowerPoint
10. Regression: deck không cấu hình → không xuất hiện header/footer lạ

## Track 20 — Zoom trong slide & Cameo (FEAT 22, 23)
**File chính:** mới `lib/services/zoom_feature_service.dart`, `lib/services/cameo_service.dart`

1. Zoom: phân tích 3 loại (Summary/Section/Slide Zoom) — chọn làm **Slide Zoom** trước
2. Model `ZoomItem`: target slide, thumbnail, frame style
3. Sinh HTML: slide zoom = ảnh thu nhỏ + click → chuyển slide target (JS) — trình chiếu app hoạt động ngay
4. Sinh PPTX: dùng `<p:zoom>` nếu chuẩn OOXML hỗ trợ (kiểm tra), fallback là hyperlink có thumbnail
5. UI chèn: chọn slide đích + khung (tái dùng thumbnail thật từ Track 64 khi có)
6. Section Zoom: tạo Sections (bổ sung model Section) → cây điều hướng
7. Cameo: chèn khung camera trực tiếp (Windows: `MediaFoundationCamera`/webcam qua plugin) hiển thị khi chiếu HTML
8. PPTX Cameo: `<p:cameo>` theo chuẩn mới — nếu PowerPoint không hỗ trợ thì giữ placeholder
9. i18n + CHANGELOG
10. Test: deck có Slide Zoom chuyển đúng slide; Cameo mở được webcam trên máy test---

# MILESTONE 3 — Định dạng & Chỉnh sửa đối tượng (T21–T28)
> Mục tiêu: soạn thảo hình dạng/ảnh/text như PowerPoint: merge shape, crop, hiệu ứng, căn chỉnh chính xác.
> Cửa sổ duyệt: sau khi xong T28.

## Track 21 — Động cơ Shape: Merge, Freeform, Edit Points (FEAT 25, 26)
**File chính:** mới `lib/models/drawn_shape.dart`, `lib/services/shape_engine.dart`, `lib/screens/editor/shape_tools.dart`

1. Thiết kế `DrawnShape`: loại (rect/oval/arrow/freeform…), path, fill, stroke, x/y/w/h %, z-order
2. Renderer PPTX: sinh `<p:sp>` + `<a:prstGeom>`/`<a:custGeom>` cho freeform + `<a:custGeomLst>` khi merge
3. Merge Shapes: union/combine/intersect/subtract — tính toán boolean path (thư viện polygon boolean hoặc tự viết cho rect/circle trước)
4. UI vẽ: toolbar Draw (line, arrow, rect, oval, freeform scribble) + chọn nhiều shape → nút merge
5. Edit Points: hiển thị điểm neo, kéo sửa (đa giác + bézier), thêm/xóa điểm
6. Render HTML (SVG) & PDF (canvas path) khớp tọa độ %
7. Chỉnh fill/stroke qua Properties Panel (nối lại panel đang chết) — gradient + trong suốt
8. Undo/redo tích hợp time-machine cho thao tác shape
9. i18n + CHANGELOG
10. Test: 2 hình vuông merge union → mở PPTX trong PowerPoint đúng kết quả, chỉnh điểm được

## Track 22 — Crop ảnh & Xóa nền (FEAT 27, 28)
**File chính:** `lib/services/image_editor_service.dart`, `lib/screens/widgets/image_editor_dialog.dart`

1. Crop freeform: vẽ vùng crop (tỷ lệ khóa 1:1, 16:9, 3:2) + giữ chất lượng gốc
2. Crop to Shape: chọn hình dạng → áp mask (PPTX: `a:prstGeom` + fill ảnh; HTML: clip-path; PDF: canvas)
3. Xóa nền tự động: dùng thuật toán local (flood-fill theo điểm màu người dùng click) — không cần mạng
4. (Bản nâng cấp) Xóa nền AI: gọi API AI hiện có với prompt xóa nền nếu provider hỗ trợ; kết quả PNG alpha
5. Tinh chỉnh thủ công: brush xóa/khôi phục vùng (eraser/add), brush size
6. Lưu kết quả: thay ảnh trong slide (cả 3 định dạng), undo được
7. PowerPoint tương thích: xóa nền → PNG trong suốt nhúng chuẩn
8. i18n + CHANGELOG
9. Test: ảnh nền trắng → xóa sạch, viền tóc không bị cắt nhiều
10. Regression: image_editor cũ (resize/xoay/sáng tương phản) vẫn hoạt động

## Track 23 — Hiệu chỉnh & Hiệu ứng nghệ thuật ảnh (FEAT 29, 30, 31)
**File chính:** `lib/services/image_editor_service.dart`, `lib/services/ppt_generator.dart`

1. Mở rộng `picture corrections`: sharpness, saturation, tone (nhiệt độ), recolor (duotone theo màu theme)
2. Artistic Effects: mờ (blur), khảm (mosaic), bút chì, phấn, sơn dầu, phim cũ — dùng bộ lọc ảnh trong `image` package + kernel tự viết
3. Picture Transparency: alpha toàn ảnh (hiện có thể qua dải trượt) — đảm bảo giữ ở cả 3 định dạng
4. PPTX: corrections → `<a:duotone>/<a:alphaModFix>`; artistic → `<a:blip> <a:effectLst>` hợp lệ
5. HTML/PDF: SVG filter hoặc pre-render PNG kết quả rồi nhúng
6. Preview real-time trong dialog trước khi áp
7. Preset nhanh: 6 preset (B&W, Vintage, Cool, Warm, Soft, Vivid)
8. Cross-check: mở PPTX trong PowerPoint thấy đúng hiệu ứng (hoặc ít nhất ảnh đã apply sẵn — fallback an toàn)
9. i18n + CHANGELOG
10. Regression: ảnh thường và ảnh đã xóa nền không bị phá vỡ

## Track 24 — Eyedropper & Format Painter (FEAT 32, 33)
**File chính:** mới `lib/services/format_painter_service.dart`, `lib/services/eyedropper_service.dart`

1. Eyedropper: capture màu tại con trỏ (Windows API hoặc snapshot WebView2 pixel) khi mở picker
2. Lưu mẫu: cửa sổ nhỏ hiện current color + swatch gần đây; click để lấy hex
3. Format Painter: lưu style snapshot của text (font, size, màu, bold…) và shape (fill, stroke, shadow)
4. Chế độ 1 lần / liên tục (double-click giữ painter) cho cả text & shape
5. Dán format vào vùng chọn mới (text) hoặc shape đang chọn
6. Áp dụng cho cả 3 định dạng export (style lưu dạng dữ liệu, không chỉ UI)
7. Phím tắt: Ctrl+Shift+C / Ctrl+Shift+V (đồng bộ ShortcutsProvider — có conflict check từ Track 63)
8. Test: painter text → dán vào slide khác giữ đúng style
9. i18n + CHANGELOG
10. Regression: copy/paste text thường không bị đổi hành vi

## Track 25 — Hiệu ứng Text & Shape chuyên sâu (FEAT 34)
**File chính:** mới `lib/services/text_effects_service.dart`, `lib/services/ppt_generator.dart`

1. Mở rộng inline style: shadow (offset, blur, màu, alpha), reflection, glow, soft edge
2. Bevel & 3D rotation: preset 12 kiểu (xét ưu tiên cho shape)
3. Sinh OOXML: `<a:effectLst>` (outerShdw, glow, softEdge, reflection) + `<a:scene3d>/<a:sp3d>` hợp lệ
4. Render HTML: CSS box-shadow/text-shadow/filter — giữ đúng giá trị
5. Render PDF: dùng hiệu ứng tối giản (shadow phẳng) để tránh phình file
6. UI: Properties Panel — tab "Hiệu ứng" với slider từng thuộc tính + preset nhanh
7. Preset nhanh: No shadow / Soft / Hard / Glow / Neumorphism style
8. Test: text glow → mở PPTX trong PowerPoint đúng hiệu ứng, không repair
9. i18n + CHANGELOG
10. Regression: text không hiệu ứng xuất y hệt v1.6.3

## Track 26 — Selection Pane & Group (FEAT 35)
**File chính:** mới `lib/models/layer.dart`, `lib/screens/widgets/selection_pane.dart`

1. Model layer: danh sách đối tượng (textbox, shape, ảnh, chart…) theo z-order trên mỗi slide
2. Selection Pane (dock phải): liệt kê đối tượng, ẩn/hiện (eye), khóa (lock), đổi tên, kéo thay đổi thứ tự
3. Đồng bộ với canvas overlay (Track 17): chọn trong pane = chọn trên canvas và ngược lại
4. Group/Ungroup/Regroup: nhóm đối tượng giữ vị trí tương đối; move/scale nhóm như 1 đối tượng
5. Xuất PPTX: group → `<p:grpSp>` + `<a:xfrm>` group scale; HTML: `<g>` SVG / div bao
6. Đèn dấu: các đối tượng ẩn vẫn xuất như cũ (giữ nguyên hành vi PowerPoint: ẩn trong edit, không ẩn khi chiếu? — chọn: xuất như ẩn là không hiển thị trong HTML, PPTX giữ hidden)
7. Undo mọi thao tác pane
8. i18n + CHANGELOG
9. Test: group 3 shape → kéo di chuyển → PPTX giữ đúng vị trí nhóm
10. Regression: slide chỉ có nội dung HTML cũ không bị ảnh hưởng

## Track 27 — Align / Snap / Guides / Ruler (FEAT 36, 37)
**File chính:** mới `lib/services/alignment_service.dart`, `lib/screens/editor/guides_overlay.dart`

1. Align: left/center/right/top/middle/bottom theo slide & theo nhóm chọn; Distribute: ngang/dọc đều
2. Smart Guides: hiện đường chạm khi kéo đối tượng gần cạnh/trục đối tượng khác hoặc trung tâm slide
3. Snap to Grid + Snap to Shape (bật/tắt) + Gridlines hiển thị
4. Ruler: thước ngang/dọc quanh canvas + tab stops trên ruler
5. Guides: kéo tạo đường gióng tùy ý, khóa vị trí, xóa, hiện/ẩn
6. Lưu guides/grid settings vào project `.ghita` (deck meta)
7. Xuất không bị ảnh hưởng (đây là công cụ soạn thảo, không vào file)
8. i18n + CHANGELOG
9. Test: kéo 2 shape canh nhau → smart guide xuất hiện, thả ra đúng vị trí
10. Regression: kéo-thả sắp xếp slide cũ không đổi

## Track 28 — Text nâng cao (FEAT 38, 39, 40, 41, 42)
**File chính:** `lib/screens/editor/html_editor_panel.dart`, `lib/services/ppt_generator.dart`, mới `lib/services/text_layout_service.dart`

1. Replace Font toàn deck: dialog chọn font cũ → font mới, áp mọi slide (scan HTML + thay inline style)
2. Change Case: sentence/upper/lower/title/toggle case cho text được chọn
3. Character Spacing: giãn/thu hẹp ký tự (letter-spacing tương đương) cả 3 định dạng
4. Text Direction: ngang/dọc (90°/270°)/stacked — đánh dấu trong HTML (writing-mode) + OOXML `<a:bodyPr vert>`
5. Autofit: shrink text on overflow (tự thu cỡ chữ) / resize shape to fit text — plugin vào Track 02 metrics
6. Bullets nâng cao: chọn số bắt đầu, danh sách đa cấp (a:buAutoNum/indent), bullet bằng ảnh/icon
7. Tabs: tab stops với leader (dấu chấm/gạch) trên ruler (Track 27)
8. Test: replace font toàn deck 10 slide → mở PPTX font đã đổi hết
9. i18n + CHANGELOG
10. Regression: đoạn text không style vẫn xuất giữ nguyên

---

# MILESTONE 4 — Animation & Transition (T29–T34)
> Mục tiêu: animation cho TỪNG đối tượng trong cả file PPTX lẫn trình chiếu HTML — tiến gần PowerPoint.
> Cửa sổ duyệt: sau khi xong T34.

## Track 29 — Động cơ Animation đối tượng (FEAT 43, 46, 47, 48)
**File chính:** mới `lib/models/object_animation.dart`, `lib/services/animation_engine.dart`, `lib/services/html_export_service.dart`

1. Thiết kế model: `ObjectAnimation { shapeId, effect (entrance/emphasis/exit/motion), start, delay, duration, repeat, autoReverse }`
2. Gắn animation vào shape: mở rộng FreeTextShape/DrawnShape/visualElements metadata
3. Renderer HTML/WebView2: sinh CSS animation per shape với cùng timing model (đủ 4 nhóm effect + 33 hiệu ứng hiện có)
4. Multiple animations: xếp chồng nhiều effect trên 1 shape (queue theo thứ tự + start thời điểm)
5. By word/letter: text animation chia span theo từ (Entrance)
6. Repeat & AutoReverse + Rewind khi kết thúc
7. Đồng bộ trình chiếu: deck HTML player chạy đúng timeline khi Present (không phải vô hiệu như hiện tại)
8. Widget test: model serialize → render CSS khớp timing
9. i18n tên hiệu ứng + CHANGELOG
10. Regression: slide không animation (đa số deck cũ) chạy y như trước

## Track 30 — Animation Pane & Animation Painter (FEAT 44, 50)
**File chính:** mới `lib/screens/widgets/animation_pane.dart`

1. Animation Pane (dock phải): liệt kê mọi animation của slide theo thứ tự thời gian
2. Thao tác: thêm/xóa/sửa effect, kéo thả đổi thứ tự, đổi start (on click/with/after)
3. Timeline trực quan: dải thời gian kéo dài/ngắn (duration), kéo dịch (delay), đánh dấu trigger
4. Preview: nút Play phát thử animation trong WebView2 preview
5. Animation Painter: chọn shape có animation → click "Painter" → click shape khác → copy animation (giữ timing)
6. Đồng bộ 2 chiều với Selection Pane (chọn shape → thấy animation của nó)
7. Xóa hàng loạt: Clear all animations slide
8. i18n + CHANGELOG
9. Test: 5 animation, thay đổi thứ tự → chạy đúng thứ tự khi trình chiếu
10. Regression: pane đóng không ảnh hưởng deck

## Track 31 — Animation Trigger & Motion Path (FEAT 45, 49)
**File chính:** `lib/services/animation_engine.dart`, `lib/models/object_animation.dart`

1. Trigger: "Bắt đầu khi click vào shape X" — OOXML `<a:animEffect>`/trigger theo chuẩn (dùng `p:timing`)
2. Renderer HTML: JS gán click listener → khởi động animation tương ứng
3. Motion Path preset: 12 đường (line, arc, circle, zigzag, curve, heart, star…)
4. Custom Path: vẽ đường bất kỳ trên canvas (tái dùng Freeform từ Track 21) → lưu dạng điểm %
5. Xuất PPTX: motion path chuyển sang `<p:animMotion>` + `<p:path>` với điểm tọa độ EMU tương đối
6. Test trong PowerPoint: trigger click đúng shape, path chạy đúng quỹ đạo
7. Điều chỉnh điểm path sau khi vẽ (edit points)
8. i18n + CHANGELOG
9. Test: path + trigger kết hợp trên cùng shape
10. Regression: animation không trigger chạy đúng like cũ

## Track 32 — Xuất Animation chuẩn OOXML (FEAT 43-export)
**File chính:** `lib/services/ppt_generator.dart` (mới `_buildTimingXml`), `lib/services/animation_engine.dart`

1. Nghiên cứu chuẩn: `<p:timing>` + `<p:seq>` + `<p:anim>`/`<p:animEffect>`/`<p:animMotion>` + `p:set` visibility
2. Map 4 nhóm hiệu ứng → OOXML: entrance (animEffect appear/fade/fly), emphasis (animScale/animClr/animRot), exit (animEffect hide), motion (animMotion)
3. Sinh timing tree: tree node + behavior list + condition (onClick/afterEffect)
4. Map timing model (delay/duration/repeat) → OOXML điểm chính xác (stCond/tnLst)
5. Fallback an toàn: nếu effect không map được → bỏ qua + cảnh báo export (nối với OPT 50 — Track 33)
6. Test mở PowerPoint: animation chạy đúng thứ tự, delay, repeat — so sánh hình ảnh frame
7. Giữ tương thích Excel/LibreOffice mở không lỗi (kiểm tra bằng file validator)
8. i18n + CHANGELOG
9. Test: deck có 10 animation phức hợp xuất → PowerPoint không repair prompt
10. Regression: deck không animation xuất không kèm `<p:timing>` rác

## Track 33 — Transition toàn diện & Cảnh báo xuất (FEAT 52, 53 + OPT 50)
**File chính:** `lib/models/slide.dart` (SlideEffect), `lib/services/ppt_generator.dart` (_buildTransitionXml), `lib/screens/widgets/advanced_export_dialog.dart`

1. Bổ sung hiệu ứng transition mới vào `SlideEffect`: dissolve, cover (4 hướng), uncover, curtain, cedar, pageCurl, ripple, vortex, shred, diamond, wedge, newsflash, ferris, flip, gallery, honeycomb, invert, orbit, origami, reveal
2. Map OOXML chuẩn: tra bảng type/subtype hợp lệ cho từng hiệu ứng mới
3. Âm thanh transition: option chọn sound (chuông, click…) + dừng âm thanh trước đó — `<p:snd>` rId vào media
4. Thời lượng transition: slider 0.1–3s từng slide + áp toàn deck
5. Auto-advance sau N giây kết hợp âm thanh (kế thừa `autoAdvanceMs`)
6. OPT 50 — Cảnh báo khi xuất: dialog nêu rõ hiệu ứng nào "chỉ chạy đúng khi xem HTML", cho chọn giữ nguyên/chuyển về gần nhất
7. Preview thử transition ngay trong EffectsScreen (nối lại màn hình đang chết — hoặc gắn vào ribbon)
8. Test: 20 hiệu ứng mới xuất PPTX → PowerPoint chạy đúng từng cái
9. i18n: tên 20 hiệu ứng mới EN/VI + CHANGELOG
10. Regression: 13 hiệu ứng cũ giữ nguyên type/subtype (deck cũ không đổi)

## Track 34 — Morph (FEAT 51)
**File chính:** mới `lib/services/morph_service.dart`, `lib/models/object_animation.dart`

1. Phân tích Morph: so sánh 2 slide liên tiếp, tìm cặp shape khớp (tên/z-order/loại), sinh chuyển tiếp
2. Model: `Slide.morphPreviousSlide` (boolean/điều kiện) + metadata đối sánh
3. Renderer HTML: chạy FLIP animation (first/last/invert/play) giữa 2 slide khi chuyển trang
4. Renderer PPTX: ghi `<p:transition>` kiểu morph (p14:morph) — kiểm tra khả năng PowerPoint mở; fallback: không ghi
5. UI: ribbon Transition → nút "Morph" trên slide (bật = slide này morph từ slide trước)
6. Xử lý nội dung: cùng text/hình di chuyển mượt; thay đổi text → fade
7. Test: 2 slide box đổi vị trí → HTML deck morph mượt; PPTX mở PowerPoint chạy morph (nếu được hỗ trợ)
8. i18n + CHANGELOG
9. Performance: giới hạn số shape morph mỗi slide (≤20) để không giật
10. Regression: tắt morph → hành vi transition cũ

---

# MILESTONE 5 — Trình chiếu (T35–T40)
> Mục tiêu: trải nghiệm trình chiếu tương đương PowerPoint: công cụ bút, setup show, remote, coach, broadcast.
> Cửa sổ duyệt: sau khi xong T40.

## Track 35 — Trình chiếu Pro: công cụ & hiệu năng (FEAT 55, 56, 57 + OPT 21, 22, 23)
**File chính:** `lib/screens/present_screen.dart`, `lib/screens/presenter_view_screen.dart`

1. OPT 21 — Kiểm tra WebView2 runtime ngay khi khởi động app (hiện banner), tránh chờ timeout 30s khi Present
2. OPT 22 — Cache deck đã build trong bộ nhớ: Present lần 2 không rebuild HTML
3. OPT 23 — Gộp Presenter view còn 1 WebView2: JS điều khiển slide hiện tại + kế (giảm RAM, đồng bộ chính xác)
4. FEAT 55 — Present: phím G mở lưới slide (grid navigator), gõ số + Enter nhảy thẳng tới slide
5. FEAT 56 — Bút/bút dạ/laser: overlay vẽ trên WebView2 qua JS (pointer events) + chế độ laser (chỉ con trỏ, di chuột)
6. FEAT 56 — Kính lúp: bấm giữ Ctrl+cuộn → zoom vùng slide lên tới 3× (CSS transform)
7. FEAT 57 — Phím B/W: màn hình đen/trắng tạm dừng (lớp phủ + phím bấm lần nữa trở lại)
8. Lưu tùy chọn: nhớ lựa chọn công cụ mặc định (pen color, laser on/off) trong session
9. i18n (hướng dẫn phím trên màn hình) + CHANGELOG
10. Test: present 30 phút deck lớn — RAM ổn định, vẽ pen không lag; phím B/W/G hoạt động

## Track 36 — Setup Show & Custom Shows (FEAT 58, 59, 60)
**File chính:** mới `lib/models/custom_show.dart`, `lib/screens/widgets/setup_show_dialog.dart`

1. Model `CustomShow`: tên + danh sách slide (kế thừa số slide hiện có, chỉ index)
2. Dialog "Set Up Show": chọn chế độ — Presenter (có người điều khiển) / Browsed (cửa sổ) / Kiosk
3. Options: loop liên tục đến Esc, không narration, không animation, tiến slide bằng thời gian
4. Chọn màn hình hiển thị (đa monitor: dropdown monitor kèm tên) + độ phân giải trình chiếu
5. Màu pen/laser mặc định trong session trình chiếu
6. Custom Shows manager: tạo/sửa/xóa, chọn custom show khi Present
7. Present theo custom show (trình chiếu con theo thứ tự riêng) cả HTML lẫn PPTX (PPTX ghi `p:customShow`)
8. i18n + CHANGELOG
9. Test: custom show 5/20 slide trình chiếu đúng thứ tự đó; Kiosk tự lặp
10. Regression: Present mặc định toàn deck không đổi

## Track 37 — Điều khiển từ điện thoại & Phụ đề trực tiếp (FEAT 61, 62)
**File chính:** `lib/services/wifi_broadcaster_service.dart` (dùng lại), mới `lib/services/remote_control_service.dart`, `lib/services/subtitle_service.dart`

1. Remote: app phone mở URL LAN (tái dùng broadcaster) — giao diện điều khiển: next/prev, timer, ghi chú slide hiện tại
2. Giao thức: WS (WebSocket) thay cho poll — phản hồi tức thì (nền tảng: shelf_web_socket)
3. Hiển thị slide hiện tại trên điện thoại phụ (không đồng bộ chính) + nút phóng to font ghi chú
4. Bảo mật: token session 32-byte như hiện tại + chỉ accept điều khiển khi chủ bật
5. FEAT 62 — Phụ đề: dùng Windows speech recognition (hoặc API AI streaming) nhận diện giọng nói
6. Hiển thị phụ đề dưới slide với màu/độ lớn tùy chọn + bật/tắt giữa chừng
7. Xử lý lỗi: không có mic/quyền → cảnh báo, tắt subtitles mềm mại
8. i18n + CHANGELOG
9. Test: điện thoại cùng Wi-Fi bấm next — slide chuyển <300ms; phụ đề hiện đúng khi nói tiếng Anh/Việt (nếu model hỗ trợ)
10. Regression: chức năng xem LAN cũ (reload) vẫn dùng được khi không bật remote

## Track 38 — Rehearse Timings & Presenter Coach (FEAT 54, 63)
**File chính:** mới `lib/services/rehearse_service.dart`, `lib/services/coach_service.dart`

1. FEAT 54 — Rehearse mode: chạy trình chiếu + đồng hồ thật, bấm chuyển slide → ghi thời gian từng slide
2. Lưu timings vào slide (mở rộng `Slide.rehearseMs`) + xuất `<p:transition advTm>` dùng đúng timings
3. Tạo báo cáo: tổng thời gian, slide lâu nhất, slide cần rút gọn + xuất báo cáo text
4. FEAT 63 — Coach: thu âm giọng khi rehearse → phân tích cơ bản local (tốc độ, khoảng lặng)
5. Coach nâng cao: gọi AI provider (prompt phân tích transcript) — đếm từ đệm ("ừm/à"), từ nhạy cảm, tốc độ từ/phút
6. Hiển thị điểm (0–100) + góp ý từng slide (card feedback)
7. Lưu lịch sử tập luyện (session log) để so sánh cải thiện
8. i18n + CHANGELOG
9. Test: rehearse 5 slide → timings chuẩn; coach nhận diện "um" tiếng Anh (VL: tiếng Việt "ừm")
10. Regression: Present thường không bị ảnh hưởng

## Track 39 — Record trình bày (FEAT 65)
**File chính:** mới `lib/services/presentation_recorder_service.dart`

1. Ghi hình trong phiên trình chiếu: video màn hình + micro (tái dùng Track 12 recording engine)
2. Chế độ: ghi timings + narration (không cần video) / ghi cả video
3. Dừng/tạm dừng, hiển thị timer ghi, badge "REC"
4. Lưu MP4 hoàn chỉnh (slide + giọng) — nền tảng: FFmpeg hoặc plugin Windows
5. Xem lại/import lại narration từ bản ghi vào slide (gán audio từng slide)
6. Kết hợp xuất video chuẩn — nối với Track 41 (export MP4)
7. Giới hạn & cảnh báo dung lượng khi ghi dài
8. i18n + CHANGELOG
9. Test: ghi 3 slide với giọng → MP4 phát khớp slide chuyển
10. Regression: Present không bật ghi mặc định

## Track 40 — Broadcast thời gian thực (FEAT 64 + OPT 33)
**File chính:** `lib/services/wifi_broadcaster_service.dart`

1. OPT 33 — Thay poll reload bằng SSE (Server-Sent Events): server đẩy slide hiện tại, trang xem không nhấp nháy
2. URL broadcast: ngắn gọn + QR (qr_flutter) cho người xem quét mở nhanh
3. Điều khiển từ broadcast page: nút next/prev nếu chủ bật (tùy chọn)
4. Theo dõi người xem: đếm số client đang kết nối, hiện chip trên Presenter View
5. Chế độ "link riêng": tạo link dùng 1 lần/hết hạn
6. Hỗ trợ ghi chú: người xem thấy cả notes? (mặc định không — riêng link có notes nếu chủ bật)
7. Tối ưu băng thông: chỉ gửi slide index + ảnh đã cache client
8. i18n + CHANGELOG
9. Test: 10 client xem đồng thời, chuyển slide <500ms, không reload nhấp nháy
10. Regression: chế độ xem cũ vẫn hoạt động khi tắt broadcast

---

# MILESTONE 6 — Xuất, In & Đóng gói (T41–T45)
> Mục tiêu: phân phối deck mọi định dạng như PowerPoint: video, GIF, ảnh, in ấn, đóng gói, bảo mật.
> Cửa sổ duyệt: sau khi xong T45.

## Track 41 — Xuất video MP4 & GIF (FEAT 66, 67)
**File chính:** mới `lib/services/video_export_service.dart`, `lib/screens/widgets/export_video_dialog.dart`

1. Khảo sát cách render video trên Windows: WebView2 capture (bản mới hỗ trợ) hoặc FFmpeg pipe từ PNG frames
2. Pipeline: render từng slide (HTML deck) → frame PNG (kích thước theo quality) → encode
3. Gắn timings/narration: dùng rehearse timings + audio narration từng slide (Track 13) — khớp thời lượng
4. Độ phân giải: 720p/1080p/4K + fps 24/30/60 + hiệu ứng transition có trong frame
5. Progress UI + cancel + ước tính thời gian còn lại
6. Export GIF: loop vô hạn / số lần, fps thấp hơn (10–15), tối ưu palette 256 màu
7. Cảnh báo thời gian render dài (ước tính) trước khi chạy
8. i18n + CHANGELOG
9. Test: deck 10 slide có narration → MP4 1080p phát đúng, audio đúng slide
10. Regression: lệnh export cũ không đổi

## Track 42 — Xuất từng slide thành ảnh (FEAT 68)
**File chính:** mới `lib/services/slide_image_export_service.dart`

1. Render slide → PNG/JPEG chất lượng cao (WebView2 capture từng slide ở kích thước gấp 2×/3×)
2. Chọn định dạng: PNG (trong suốt nền tùy chọn), JPG (quality), WebP
3. Chọn phạm vi: tất cả / slide chọn / từ X đến Y + thư mục đích + tiền tố tên file
4. Tùy chọn xuất: giữ nguyên kích thước EMU slide (đúng tỷ lệ 16:9…) hoặc khổ tùy chỉnh px
5. Xuất nền trong suốt PNG: loại bỏ bg solid → alpha (hỗ trợ soạn ảnh)
6. Batch: chạy isolate (tái dùng Track 01 pipeline) + progress
7. Gộp thêm: tạo 1 sheet ảnh tất cả slide (contact sheet) tùy chọn
8. i18n + CHANGELOG
9. Test: 20 slide → 20 PNG đúng kích thước, không vỡ font VN
10. Regression: không ảnh hưởng luồng xuất khác

## Track 43 — In ấn, Handouts & Outline cho Word (FEAT 69, 70, 71)
**File chính:** mới `lib/services/print_service.dart`, `lib/services/outline_export_service.dart`

1. Kết nối in Windows: dùng `printing` package (đã có) — in trực tiếp máy in hệ thống
2. Layout in: Full page slide / Notes Pages (slide + ghi chú dưới) / Outline
3. Handouts: 2/3/4/6/9 slide mỗi trang + dòng ghi chú cho từng slide (mẫu chuẩn PPT)
4. Options in: khung viền slide, scale to fit, in slide ẩn, in màu/đen trắng, chọn phạm vi
5. Outline export: sinh RTF (.rtf) từ tiêu đề + body text mọi slide → mở bằng Word
6. Tùy chỉnh handout master: header/footer + logo (đơn giản hóa: in thêm dòng header)
7. Xem trước khi in (preview dialog với các layout)
8. i18n + CHANGELOG
9. Test: in 9-slide/trang handouts đúng bố cục trên PDF giả lập (in ra file)
10. Regression: xuất PDF hiện tại không đổi

## Track 44 — Định dạng lưu mở rộng: .potx / .ppsx / .ppt / .odp (FEAT 72, 73)
**File chính:** `lib/models/export_options.dart`, `lib/services/ppt_generator.dart`, mới `lib/services/odp_export_service.dart`

1. .potx (template): xuất đúng gói template — thay `p:presentation` bằng chuẩn template (tương thích mở như file thường + nhận diện template khi mở)
2. .ppsx (slideshow): cùng gói PPTX chỉ đổi content-type + đuôi (mở là chiếu luôn)
3. .pptm / .potm: bỏ qua macro (không có VBA); nếu người dùng chọn → xuất bản thường + cảnh báo "không chứa macro"
4. .ppt (97-2003): yêu cầu chuyển đổi — dùng LibreOffice headless nếu có trên máy (phát hiện), fallback cảnh báo yêu cầu tự dùng PowerPoint
5. .odp: sinh gói OpenDocument (thư viện tự build đơn giản hoặc `odt` package) — text/list/ảnh/table trước, chart/smartart sau
6. Save As dialog: danh sách định dạng + đuôi tự động + ghi đè xác nhận
7. Kiểm tra đúng chuẩn: mở .potx/.ppsx trong PowerPoint không repair
8. i18n + CHANGELOG
9. Test: lưu .ppsx → double-click mở chạy trình chiếu luôn
10. Regression: .pptx/.pdf/.html giữ nguyên

## Track 45 — Đóng gói CD & Bảo mật tài liệu (FEAT 74, 75, 77, 78, 79)
**File chính:** mới `lib/services/package_service.dart`, `lib/services/doc_security_service.dart`

1. FEAT 74 — Package: xuất thư mục gồm `.pptx` + `media/` + `README` (giải nén media để ngoài như PowerPoint "Link files") + tùy chọn nén ZIP tổng
2. FEAT 75 — Compress Media: quét toàn deck, nén ảnh/video theo mức (tái dùng Track 03) + báo dung lượng giảm
3. FEAT 77 — Document Inspector: quét metadata ẩn (tên tác giả, lịch sử, chuỗi "email/phone" regex), cho xóa
4. FEAT 78 — Mã hóa: mật khẩu mở file theo chuẩn OOXML (encryption `<p:encryption>`) — dùng `file_encryptor`/tự build; Mark as Final (`p:modifyVerifier`/property); chữ ký số (dùng cert hệ thống Windows — phạm vi hẹp)
5. FEAT 79 — Restrict Access: readonly + cảnh báo (client-side, không phải IRM thật nếu không có Azure) + ghi chú trong file properties
6. UI: dialog "Bảo vệ bài thuyết trình" tập trung 4 công cụ
7. Kiểm tra: file mã hóa mở bằng PowerPoint phải hỏi mật khẩu
8. i18n + CHANGELOG
9. Test: package deck 50MB → nén media còn <20MB; inspector tìm thấy tên tác giả và xóa được
10. Regression: xuất thường không bị chặn bởi bảo mật khi không cấu hình---

# MILESTONE 7 — Cộng tác & Cloud (T46–T51)
> Mục tiêu: hạ tầng cộng tác nhanh, bình luận, tài khoản, đồng bộ cloud, so sánh hợp nhất.
> Cửa sổ duyệt: sau khi xong T51.

## Track 46 — Hạ tầng cộng tác LAN nâng cấp (OPT 32, 34, 35, 36)
**File chính:** `lib/services/collaboration_service.dart`, `lib/providers/presentation_state.dart`

1. OPT 32 — Delta sync: giữ revision, chỉ gửi diff (thay đổi slide index + nội dung mới) thay vì cả deck
2. Nén payload gzip (deck 2MB → ~300KB); bỏ giới hạn cứng 2MB, thay bằng giới hạn theo trạng thái
3. OPT 34 — QR join: hiện QR code (qr_flutter đã khai báo) chứa URL session + access token ngắn
4. OPT 35 — Auto re-connect: backoff 1s→2s→4s→8s, resume đồng bộ từ revision cuối, hiển thị trạng thái "đã ngắt/đang nối"
5. OPT 36 — Cấu hình động: giới hạn collaborator (mặc định 20) & slide (200) chỉnh trong session settings
6. Chuyển poll 900ms → cơ chế nhanh hơn cho sự kiện ưu tiên (sửa nội dung) + poll chậm cho heartbeat
7. Conflict UI: hiển thị xung đột ai đổi gì (tên + thời gian) thay vì 409 trần
8. i18n + CHANGELOG
9. Test: 2 máy cùng sửa — đồng bộ <1s, mất mạng 10s tự nối lại không mất dữ liệu
10. Regression: join session cũ (định dạng URL cũ) vẫn chấp nhận 1 phiên bản

## Track 47 — Co-authoring thời gian thực (FEAT 80)
**File chính:** `lib/services/collaboration_service.dart`, `lib/screens/home_screen.dart`

1. Presence: mỗi collaborator có màu + tên; hiển thị avatar trên thanh trạng thái
2. Con trỏ người khác: gửi tọa độ con trỏ (throttle 100ms) → hiển thị trên preview/canvas
3. Chỉ báo "đang sửa slide X" — badge trên thumbnail slide trong SlideListPanel
4. Block mềm: 2 người cùng sửa 1 slide → lock tạm bàn phím ở người sau (như PowerPoint hiện "đang được người khác mở")
5. Merge nội dung: ánh xạ revision + merge theo slide (last-writer trên khác slide là OK)
6. Lịch sử đồng bộ: log "ai sửa gì lúc nào" (hiển thị trong panel cộng tác)
7. Cam kết session: chủ có thể khóa session (join mới bị từ chối), đuổi người dùng
8. i18n + CHANGELOG
9. Test: 3 máy — sửa 3 slide khác nhau cùng lúc, không mất ai; sửa cùng slide → lock đúng
10. Regression: chế độ single-player không liên quan, không bị chậm

## Track 48 — Comments & Mentions (FEAT 81)
**File chính:** mới `lib/models/comment.dart`, `lib/services/comment_service.dart`, UI trong editor panel trái

1. Model `Comment`: id, slideId, text, tác giả, createdAt, resolved, replyTo, anchor (tọa độ/dòng HTML nếu có)
2. UI: ngăn comments bên phải editor — thêm/sửa/xóa, trả lời (thread), resolve/unsolve
3. Mention: gõ @ → danh sách collaborator (LAN) → tô màu + thông báo trong session
4. Persist: comments lưu trong `.ghita` (bundle) + đồng bộ qua collaboration sync (delta)
5. Xuất PPTX: comments → `<p:cm>` + `<p:cMediaNodeLst>` (chuẩn OOXML comments) — nếu phức tạp quá: xuất 1 trang phụ "Ghi chú thảo luận"
6. Badge: icon bong bóng trên thumbnail slide có comment + đếm
7. Thông báo: chip "có comment mới" khi session mở
8. i18n + CHANGELOG
9. Test: 2 máy comment chéo → resolve đúng; mở lại .ghita còn comments
10. Regression: xuất deck bình thường không kèm comment lạ

## Track 49 — Tài khoản người dùng & Phân quyền (FEAT 84)
**File chính:** mới `lib/services/auth_service.dart`, `lib/models/user_profile.dart`, `lib/screens/settings_screen.dart`

1. Hồ sơ cục bộ: tên + avatar (chọn màu/emoji) — không cần đăng nhập mạng cho LAN (mặc định)
2. (Option) Đăng nhập cloud: Google/email bằng OAuth (gói `google_sign_in`/`sign_in_with_apple` — Windows hỗ trợ hạn chế, đánh giá trước)
3. Vai trò trong session: host (toàn quyền) / editor / viewer — gán khi tạo/join session
4. Chặn viewer sửa: phía server session từ chối payload sửa từ viewer
5. Quyền cho link xem broadcast: link view-only mặc định, link edit có token riêng
6. Lưu profile → SharedPreferences + dùng làm tác giả comments/xuất metadata (PresentationAuthor)
7. i18n + CHANGELOG
8. Test: viewer bấm sửa → nhận thông báo "chế độ xem", không ghi được
9. Regression: offline không yêu cầu tài khoản (ưu tiên trải nghiệm ngoại tuyến)
10. CHANGELOG + hướng dẫn README về mô hình quyền

## Track 50 — Cloud sync & Version history (FEAT 82, 83)
**File chính:** mới `lib/services/cloud_sync_service.dart`, mới `lib/services/version_history_service.dart`

1. Đánh giá bộ nhớ cloud: WebDAV (Nextcloud) trước — dùng `dav` package; OneDrive Graph cần app đăng ký (chỉ khi bạn cấp client id)
2. Cấu hình tài khoản cloud: URL + user + pass (flutter_secure_storage)
3. Upload/download dự án `.ghita` tự động (autosave cloud sau N phút) + chỉ báo đồng bộ
4. Merge khi 2 máy lưu: theo timestamp + revision; xung đột → giữ bản mới + lưu bản cũ thành `.conflict`
5. Version history: giữ tối đa 20 bản tự động khi upload (ghi vào thư mục cloud) + danh sách khôi phục
6. UI: panel "Phiên bản" — xem ngày/giờ/kích thước, khôi phục (tải về làm hiện tại), xóa
7. Mở deck từ cloud (recent projects mở rộng: nhóm Cloud)
8. i18n + CHANGELOG
9. Test: 2 máy cùng mở cloud deck, sửa, autosave — không mất dữ liệu, conflict đúng
10. Regression: hoạt động offline hoàn toàn không đổi

## Track 51 — Reuse Slides & Compare/Merge (FEAT 85, 86)
**File chính:** mới `lib/services/reuse_slide_service.dart`, mới `lib/services/compare_merge_service.dart`

1. Reuse Slides: dialog "Chèn slide từ thuyết trình khác" — mở `.ghita` hoặc `.pptx` (khi Track đã có parser PPTX import — lưu ý phụ thuộc) để lấy slide
2. Chọn nhiều slide + "Giữ định dạng gốc" (mang theo style HTML) / "Dùng theme hiện tại"
3. Nhập slide từ PPTX: tạm thời chuyển thành HTML thô từ text (đọc dòng text + hình) — đầy đủ hơn khi có parser PPTX hoàn chỉnh (ghi chú phụ thuộc Track import PPTX ở Milestone 9/10)
4. Compare: mở 2 phiên bản `.ghita` → so sánh từng slide (diff text/HTML, badge khác biệt)
5. Merge: chọn slide lấy từ bản A hay B (hoặc cả hai - thêm), áp vào hiện tại
6. Báo cáo so sánh: danh sách "thêm/xóa/sửa" theo slide
7. i18n + CHANGELOG
8. Test: so sánh 2 bản → merge đúng 12/20 slide theo lựa chọn
9. Regression: Recent Projects không đổi
10. Cập nhật README hướng dẫn luồng reuse/compare

---

# MILESTONE 8 — AI (T52–T56)
> Mục tiêu: AI hiểu ngữ cảnh deck, sinh nội dung đúng theme bố cục, designer, copilot — vượt mặt đối thủ.
> Cửa sổ duyệt: sau khi xong T56.

## Track 52 — AI hiểu ngữ cảnh & validate đầu ra (OPT 37, 38)
**File chính:** `lib/providers/ai_provider_manager.dart`, `lib/screens/ai_chat_screen.dart`, `lib/providers/presentation_state.dart`

1. OPT 37 — Build context vào system prompt: layout hiện tại (layoutType), theme (màu primary/accent/font), ngôn ngữ UI, tóm tắt slide đang chọn
2. Context tùy chọn: người dùng bật "AI dùng ngữ cảnh deck" (riêng tư theo lựa chọn)
3. Yêu cầu AI trả HTML theo đúng class/style của theme (mẫu trong prompt)
4. OPT 38 — Validate sau khi sinh: strip tag nguy hiểm (vẫn giữ chip script/iframe), giới hạn 100KB
5. Rút gọn tự động: nếu vượt giới hạn → cắt class trùng, gợi ý "chạy nén HTML" 1 chạm
6. Giữ lời hứa: kiểm tra HTML parse được (mở preview lỗi → tự động thử sửa)
7. i18n + CHANGELOG
8. Test: AI sinh slide — màu font khớp theme đang chọn; HTML dính script → bị lọc
9. Regression: chat không bật context vẫn hoạt động như cũ
10. Đo chất lượng: 20 lần sinh, đếm % slide dùng đúng sau khi bật context

## Track 53 — AI pipeline bền vững & tiết kiệm (OPT 39, 40, 41, 42, 43)
**File chính:** `lib/providers/ai_provider_manager.dart`, `lib/services/api_fallback_cascade_service.dart`, `lib/services/api_key_rotation_service.dart`

1. OPT 39 — Generate multi-slide: parse stream dần, phát hiện JSON lỗi giữa chừng → repair (cân bằng ngoặc) + checkpoint: giữ slide đã sinh
2. OPT 40 — Streaming: render slide 1 ngay khi token đủ JSON cục bộ, không chờ toàn bộ
3. OPT 41 — Chat history: giới hạn theo token (cấu hình), tự quên hội thoại cũ nhất, hiển thị "đã cắt lịch sử"
4. OPT 42 — Fallback: ping provider song song (không tuần tự), nhớ provider khỏe nhất gần đây, timeout theo nhóm (150ms local, 8s remote mặc định)
5. OPT 43 — Model list & healthcheck: cache 10 phút, nút "Refresh" thủ công; healthcheck nền không chặn AI chat
6. Thống kê chi phí: đếm token ước tính mỗi phiên, hiển thị tối giản trong chat
7. Xử lý API key hết hạn: phát hiện 401 → tự thử key dự phòng, báo "key X hết hạn"
8. i18n + CHANGELOG
9. Test: sinh 10 slide, cắt mạng giữa chừng → giữ 5 slide đã xong, thử lại từ 6
10. Regression: streaming UI hiện tại không đổi trải nghiệm

## Track 54 — Designer (Design Ideas) (FEAT 87)
**File chính:** mới `lib/services/designer_service.dart`, `lib/screens/widgets/designer_panel.dart`

1. Quy tắc thiết kế local (không cần mạng): 12 bố cục chuyển đổi từ nội dung (title+list → 2 cột, KPI cards, hero ảnh, quote styling…)
2. Phát hiện nội dung: parse HTML hiện tại (title, list dài, bảng, nhiều ảnh) → đề xuất layout phù hợp
3. Designer Panel (dock phải): 3–5 thumbnail gợi ý + "Ảnh minh họa" (ảnh kho Track 15) + "Biểu tượng" (icons Track 15)
4. Áp 1 chạm: chuyển đổi HTML slide sang layout gợi ý (giữ nội dung, đổi cấu trúc/class)
5. Variant nhanh: đổi màu accent/dark variant trong panel
6. Designer AI (khi có key): gửi nội dung + yêu cầu "đề xuất 3 bố cục HTML" — kết quả dán vào panel
7. Lịch sử gợi ý: undo bằng tay (bản gốc giữ lại, nút "Hoàn tác thiết kế")
8. i18n + CHANGELOG
9. Test: slide list 8 mục → đề xuất 2-cột đúng; áp xong xuất PPTX không vỡ
10. Regression: không mở panel → deck không đổi

## Track 55 — Copilot Creator: tạo deck từ lệnh/Word/PDF (FEAT 88, 89)
**File chính:** `lib/screens/ai_chat_screen.dart`, mới `lib/services/copilot_service.dart`, `lib/services/document_importer_service.dart`

1. Lệnh "Tạo bài thuyết trình" nâng cấp: hỏi chủ đề + số slide + giọng điệu (trình bày/bán hàng/giáo dục) + tỷ lệ slide
2. Tạo từ tài liệu: mở Word (.docx parse text) / PDF (trích văn bản) / Markdown → tự chia slide theo dàn ý
3. Tạo từ URL: lấy nội dung trang (nâng cấp Track 66 import web) → tóm tắt → slide
4. Copilot tóm tắt deck hiện tại: gửi outline/text slide → trả 5 dòng tóm tắt + slide "Tóm tắt" chèn cuối
5. Hỏi đáp với deck (Q&A): người dùng hỏi "slide nào nói về X" — gửi index + tiêu đề + text → trả lời kèm link slide
6. "Soạn thảo tiếp": chọn slide → AI đề xuất 3 hướng mở rộng (1 chạm áp)
7. Giao diện: chat có chip nhanh (Tạo deck / Tóm tắt / Hỏi về deck) + progress khi tạo nhiều slide
8. i18n + CHANGELOG
9. Test: đưa PDF 20 trang → deck 10 slide đúng dàn ý, giữ được ý chính
10. Regression: chat bình thường không đổi

## Track 56 — Dictation & Dịch toàn deck (FEAT 90, 91)
**File chính:** mới `lib/services/dictation_service.dart`, `lib/screens/ai_chat_screen.dart` (dịch)

1. Dictation: nhận giọng nói Windows (speech recognition) → chèn text vào slide đang chọn tại con trỏ
2. Nút mic trong editor toolbar + trạng thái nghe (pulse) + dừng tự động sau 2s im lặng
3. Hỗ trợ ngôn ngữ theo locale UI (EN/VI — nếu model Windows có sẵn tiếng Việt; nếu không: cảnh báo dùng EN)
4. Dịch toàn deck: lần lượt từng slide dùng AI (giữ cấu trúc HTML, chỉ dịch text node) + progress
5. Chọn ngôn ngữ đích (8 ngôn ngữ như slide-tool hiện tại) + bản xem trước diff
6. Áp/Hủy hàng loạt hoặc từng slide sau khi xem trước
7. i18n + CHANGELOG
8. Test: đọc 1 câu → text vào đúng slide; dịch deck EN→VI giữ bold/list/table
9. Regression: dịch 1 slide (có sẵn) không đổi
10. Ghi chú giới hạn speech (phụ thuộc Windows) vào README

---

# MILESTONE 9 — Năng suất & Trợ năng (T57–T62)
> Mục tiêu: chính tả, tìm kiếm, trợ năng, template online, ribbon tùy biến — trải nghiệm "đúng trình".
> Cửa sổ duyệt: sau khi xong T62.

## Track 57 — Chính tả, Thesaurus, Tìm/Thay thế (FEAT 92, 93, 94)
**File chính:** mới `lib/services/spellcheck_service.dart`, `lib/services/search_service.dart`, `lib/screens/editor/`

1. Từ điển: gói danh sách từ EN + VI (hunspell dictionaries, tĩnh trong assets)
2. Dò chính tả trên text: highlight từ sai trong editor + preview (dùng `TextSpan` gạch đỏ)
3. Sửa nhanh: click từ sai → gợi ý 3–5 từ (Levenshtein) + bỏ qua
4. Grammar cơ bản: quy tắc cục bộ (viết hoa đầu câu, khoảng trắng kép) — không gọi mạng
5. Thesaurus local: bộ từ đồng nghĩa EN (gói nhỏ) + mở rộng qua AI nếu có key
6. Tìm trong deck: search box (Ctrl+F) — duyệt title + text mọi slide, highlight + nhảy tới slide chứa kết quả
7. Replace: thay chuỗi khắp deck (tùy chọn toàn từ/chữ hoa thường), báo "đã thay N chỗ"
8. i18n + CHANGELOG
9. Test: gõ sai "recieve" → gạch đỏ + gợi ý "receive"; Ctrl+F tìm đúng slide
10. Regression: editor gõ nhanh không bị giật (check hiệu năng)

## Track 58 — Accessibility Checker (FEAT 95)
**File chính:** mới `lib/services/accessibility_service.dart`, `lib/screens/widgets/accessibility_panel.dart`

1. Bộ kiểm tra tự động: thiếu alt text cho ảnh, tương phản màu (WCAG AA: kiểm tra cặp màu nền/chữ), thứ tự đọc
2. Thứ tự đọc: xác định từ HTML (title → content thô) + canvas overlay (Track 17) — hiển thị số thứ tự để chỉnh
3. Alt text: dialog nhập cho từng ảnh (lưu vào visualElements) + sinh alt tự động từ title slide
4. Tương phản: tự phát hiện cặp chữ/nền kém → gợi ý màu đạt chuẩn + 1 chạm áp
5. Bảng kết quả: danh sách lỗi/cảnh báo theo slide + số lỗi; bấm vào → nhảy tới chỗ đó
6. Xuất báo cáo trợ năng (text) khi cần nộp
7. i18n + CHANGELOG
8. Test: deck có ảnh không alt + chữ vàng nền trắng → phát hiện đủ 2 lỗi, sửa 1 chạm
9. Regression: export hoàn toàn không bị ảnh hưởng
10. Cập nhật README mục trợ năng

## Track 59 — Template online & Studio hoàn thiện (FEAT 96 + OPT 46, 47)
**File chính:** `lib/screens/template_studio_screen.dart`, `lib/services/template_service.dart`

1. OPT 46 — Nối luồng "Sử dụng": callback applyTemplate truyền từ Home/Editor — áp thật, kèm undo
2. Preview lớn: dialog xem template full kích thước slide trước khi chọn
3. OPT 47 — Template tham số hóa: template JSON có `{primary}`, `{accent}`, `{font}` — đổi theme → template tự biến đổi
4. "Tạo template từ deck hiện tại": lưu slide đầu tiên + theme thành template mới (Assets/người dùng)
5. Thư viện local: 20 mẫu cải tiến (đủ 9 layout thay vì 1 HTML) + đánh dấu yêu thích
6. FEAT 96 — Kho template online (self-host): tải danh sách từ URL cấu hình (JSON) + tải về → dùng; mặc định tắt (offline)
7. (Khi có server của bạn) đăng tải template do mình tạo
8. i18n + CHANGELOG
9. Test: đổi theme màu → mọi template xem trước đổi theo; áp template đúng layout
10. Regression: deck đang soạn không bị ghi đè ngoài ý muốn (luôn tạo bản mới + undo)

## Track 60 — Ribbon/QAT tùy biến & Chế độ xem (FEAT 97, 99)
**File chính:** `lib/screens/widgets/ribbon_toolbar.dart`, `lib/screens/widgets/quick_access_toolbar.dart`

1. Model cấu hình: danh sách tab → group → lệnh (id chuẩn hóa từ `ShortcutAction`)
2. UI tùy biến: dialog "Tùy chỉnh Ribbon/QAT" — kéo thả lệnh giữa 2 cột (như PowerPoint)
3. Tạo tab/group riêng với tên + icon; reset về mặc định
4. Lưu cấu hình vào SharedPreferences + export/import JSON cấu hình
5. FEAT 99 — Views: button chuyển nhanh 4 chế độ (Normal / Slide Sorter / Notes / Reading) + trạng thái status bar
6. Reading View: trình chiếu trong cửa sổ app (không fullscreen) với navigation thanh dưới (đã có nền từ PresentScreen)
7. Outline View: danh sách text các slide dạng cây, sửa tiêu đề/dòng trực tiếp (sync 2 chiều HTML)
8. i18n + CHANGELOG
9. Test: thêm lệnh "Export PDF" lên QAT → bấm chạy đúng; tạo tab riêng → xóa được
10. Regression: ribbon mặc định vẫn đủ 6 tab như cũ khi chưa tùy biến

## Track 61 — Add-ins & VBA (FEAT 98)
**File chính:** mới `lib/services/addin_service.dart`, `lib/services/vba_service.dart`

1. Cổng Add-in (đơn giản hóa): thư mục `addins/` bên cạnh app — 1 file Dart/JSON đăng ký lệnh + handler
2. SDK tối thiểu: add-in nhận deck (slides), trả về thay đổi (thêm slide, sửa text) — kèm mẫu 2 ví dụ
3. Trình quản lý: danh sách add-in bật/tắt + log lỗi chạy
4. VBA trong PPTX: không chạy VBA; chỉ HỖ TRỢ giữ/lưu file có macro (đánh dấu .pptm như Track 44) + cảnh báo macro khi mở từ import (Tương lai)
5. Ghi macro tương đương: người dùng thao tác → tự sinh JSON script (record/playback các lệnh cốt lõi: thêm slide, format, xuất)
6. Playback script: chạy lại + chỉnh sửa trong trình soạn script đơn giản
7. Bảo mật: add-in tự tải từ remote → chặn (chỉ local) + cảnh báo khi bật add-in lạ
8. i18n + CHANGELOG
9. Test: add-in mẫu "thêm slide KPI từ số liệu" chạy đúng; tắt add-in lỗi không crash app
10. Viết README: hướng dẫn phát triển add-in + giới hạn VBA

## Track 62 — Đọc to & Điều hướng bàn phím (FEAT 100)
**File chính:** mới `lib/services/read_aloud_service.dart`, `lib/utils/keyboard_shortcuts.dart`

1. Read Aloud: Windows TTS (System.Speech) đọc title + text slide (ngôn ngữ theo locale)
2. Điều khiển: đọc từ slide hiện tại / toàn deck, pause/resume/stop, tốc độ đọc (chậm/vừa/nhanh)
3. Highlight khi đọc: tô text đang đọc trong editor (tương tác pointer)
4. Rà soát phím tắt: hoàn thành bảng phím tắt mọi lệnh (bao gồm các chức năng mới từ các Track)
5. Điều hướng bàn phím 100%: focus ring rõ, Tab qua mọi control, phím mũi tên di chuyển đối tượng (nudge 1px/10px)
6. Trợ giúp phím tắt theo ngữ cảnh: F1/Ctrl+/ mở đúng phần liên quan
7. i18n + CHANGELOG
8. Test: đọc deck 5 slide tiếng Việt phát đúng giọng (nếu Windows có tiếng Việt, fallback EN); Tab đi hết mọi nút
9. Regression: phím tắt cũ không đổi hành vi
10. Cập nhật README trợ năng

---

# MILESTONE 10 — Chất lượng phần mềm & Release 2.0.0-beta (T63–T67 + Integration)
> Mục tiêu: editor UX, hiệu năng, import, dọn dẹp, QA tổng — chốt phiên bản 2.0.0-beta.
> Cửa sổ duyệt (cuối cùng): sau T67 + Integration; sau đó mới được commit/tag.

## Track 63 — Editor UX nâng cấp (OPT 13, 14, 15, 16, 17, 18, 19, 24)
**File chính:** `lib/screens/editor/html_editor_panel.dart`, `lib/screens/widgets/*`, `lib/providers/shortcuts_provider.dart`

1. OPT 13 — Syntax highlight cho HTML editor (dùng `flutter_highlight` — dep đã khai báo) + tự đóng thẻ, số dòng
2. OPT 14 — Live preview: debounce 500ms tự cập nhật preview khi gõ (giữ nút Update cho trường hợp tắt)
3. OPT 15 — WYSIWYG toolbar thao tác trên lựa chọn: wrap `<b>/<i>/<u>/<span style>` quanh text đang chọn (selection range), nút color picker chèn span
4. OPT 16 — Ribbon: trạng thái enabled/disabled theo ngữ cảnh (vd: không chọn slide → vô hiệu hóa xóa/export)
5. OPT 17 — QAT tùy biến nhanh: click chuột phải lệnh → "Thêm vào QAT" (tiền đề Track 60)
6. OPT 18 — Command palette: fuzzy search (gõ "expo" ra Export), danh sách gần đây, phím tắt hiển thị cạnh lệnh
7. OPT 19 — Conflict check phím tắt: khi customize trùng → cảnh báo + gợi ý phím trống
8. OPT 24 — Status bar mở rộng: số từ, dung lượng deck, trạng thái lưu (đã lưu/đang lưu), slide x/y, zoom %
9. i18n + CHANGELOG
10. Test: gõ HTML sai thẻ nhanh → editor không giật, preview cập nhật 500ms; QAT thêm lệnh chạy được

## Track 64 — Preview & Thumbnail thật (OPT 20 + FEAT hỗ trợ)
**File chính:** `lib/screens/editor/slide_list_panel.dart`, `lib/services/project_bundle_service.dart`

1. Render thumbnail thật qua WebView2: capture từng slide (deck tạm) → PNG nhỏ (88×50) 
2. Cập nhật thumbnail nền: tự làm mới slide bị sửa (debounce), không chặn UI
3. Cache thumbnail trong `.ghita` (media/thumbs/) — mở lại deck nhanh không phải render lại
4. Thumbnail lớn cho preview dialog (double-click slide) + sorter (SlideSorter dùng luôn)
5. Placeholder: WebView2 unavailable → ảnh nền có layoutType (không treo)
6. Giảm RAM: giới hạn hàng đợi render (render 4 slide/lần), tái dùng WebView2 capture (Track 35)
7. i18n + CHANGELOG
8. Test: deck 50 slide — mở lại <1s hiện thumbnail, cuộn mượt
9. Regression: khi không có WebView2 vẫn dùng thumbnail cũ/cached
10. Tối ưu: dung lượng thumbnail trong bundle ≤10% tổng file

## Track 65 — Lưu trữ & Khởi động (OPT 25, 26, 27, 28, 29, 30)
**File chính:** `lib/providers/presentation_state.dart`, `lib/services/time_machine_history_service.dart`, `lib/services/smart_draft_manager.dart`, `lib/services/local_ai_detector_service.dart`

1. OPT 25 — Time machine: snapshot lưu dạng nén (gzip) hoặc diff (chỉ slide thay đổi); coalesce gõ liên tục (gộp 5s thành 1 snapshot)
2. OPT 26 — Autosave draft: debounce + chỉ ghi khi dirty; chia file theo phiên
3. OPT 27 — Deck lớn: slides JSON > ngưỡng (1MB) chuyển lưu file riêng (bundle), SharedPreferences chỉ giữ con trỏ; backward compatible
4. OPT 28 — Lazy scan AI local: quét sau khi UI render (post-frame), cache 5 phút, không bao giờ chặn màn hình đầu
5. OPT 29 — Healthcheck song song + khoảng thời gian thích ứng (nhiều provider → 10 phút)
6. OPT 30 — Lazy provider: chỉ khởi tạo provider khi mở màn hình cần; template cache sau lần nạp đầu
7. Đo thời gian khởi động trước/sau (mục tiêu <1.5s tới Home)
8. i18n + CHANGELOG
9. Test: khởi động nguội 10 lần — trung bình giảm 30%; undo với 30 snapshot nén không rớt RAM
10. Regression: mọi luồng lưu/mở cũ vẫn đúng (kiểm tra auto-save sau crash)

## Track 66 — Import nâng cao (OPT 44, 45)
**File chính:** `lib/services/document_importer_service.dart`, `lib/screens/widgets/import_dialog.dart`

1. OPT 44 — Markdown đầy đủ: bảng (| cột |), danh sách lồng, ảnh (đường dẫn/base64), khối code → giữ dạng, phân slide bằng `---`
2. Import Word .docx: trích text (package docx đọc) → heading thành slide (title + body)
3. OPT 45 — Import web giàu hơn: lấy title + H1–H3 + đoạn văn + danh sách + ảnh chính (tối đa 5), giữ thứ tự
4. Import PPTX (nền tảng cho Track 51/91): parser đọc text+hình đủ cho nhu cầu — đọc slide → HTML (chuyển đổi shape text, bullet, ảnh); chart/smartart → giữ placeholder "không nhập được"
5. Import PDF: trích văn bản theo trang → slide (trang = slide, tối đa 30 trang)
6. Tóm tắt AI "nhập gọn": sau import → AI gợi ý rút còn N slide (khi có key)
7. UI import: một dialog chọn nguồn (file/markdown/url/pptx/pdf) + preview trước khi áp
8. i18n + CHANGELOG
9. Test: markdown có bảng → slide có bảng đúng; PPTX 5 slide → 5 slide HTML giữ text/ảnh
10. Regression: import web cũ vẫn chạy chế độ đơn giản khi đặt "không lấy ảnh"

## Track 67 — Dọn code chết & l10n hoàn chỉnh (OPT 48, 49)
**File chính:** toàn dự án, `lib/l10n/*.arb`

1. Rà toàn bộ `lib/`: tìm màn hình/widgets không tham chiếu (EffectsScreen, AudioRecorderPanel trước khi nối, PropertiesPanel, DraggableElement cũ…)
2. Quyết định từng cái: nối vào luồng (nếu Track trước đã cần) hoặc xóa + xóa import rác
3. Dọn dependency chết: `audioplayers`, `url_launcher`, `highlight`… — dùng thật hoặc gỡ khỏi pubspec (kiểm tra không ai import)
4. OPT 49 — l10n: quét chuỗi hardcode tiếng Việt trong code (dialog/snackbar/ribbon…) → chuyển hết vào .arb EN/VI
5. Đảm bảo .arb không thiếu key: script kiểm tra 2 file đồng bộ
6. Chạy `flutter analyze` 0 lỗi + `flutter test` xanh
7. rà README: cập nhật danh sách tính năng 2.0.0-beta + hướng dẫn
8. i18n + CHANGELOG
9. Test: khởi động app EN/VI — không còn chuỗi Việt "lẫn" trong giao diện EN
10. DoD Milestone 10 (xem mục Integration dưới đây)

---

# INTEGRATION & RELEASE 2.0.0-beta

1. Chạy full QA: `flutter analyze`, `flutter test`, `integration_test` trên Windows (máy có WebView2)
2. Smoke test 15 luồng chính: tạo → chỉnh → xuất 3 định dạng → present → cộng tác → AI → mở lại
3. Mở file kiểm thử bằng PowerPoint thật (nếu có) cho mọi định dạng mới (charts, smartart, video, timings, encrypt)
4. Bump `pubspec.yaml` → `version: 2.0.0-beta+1`; cập nhật `CHANGELOG.md` mục `[2.0.0-beta]` tổng hợp; README
5. Tạo tag `v2.0.0-beta` (chỉ sau khi bạn duyệt file này)
6. Tổng kết báo cáo: số track hoàn thành (67/67), số phase (670), điểm đạt (150/150), phần còn lại mở (ghi chú roadmap 2.1)
7. Cập nhật tài liệu này: đánh dấu các track đã xong với ghi chú thực tế (độ lệch nếu có)
8. Lưu lại số liệu benchmark (dung lượng file, thời gian xuất, RAM, khởi động) trước/sau
9. Backup hiện trạng trước khi bump (đảm bảo có thể quay lại v1.6.3 bằng git)
10. Bàn giao: danh sách tính năng mới + hạn chế còn lại cho người dùng thử beta

---

## Phụ lục — Ma trận 150 điểm → 67 track

- FEAT 1,2→T08 · FEAT 3→T09 · FEAT 4→T10 · FEAT 5,6,76→T11 · FEAT 7→T12 · FEAT 8,9→T13 · FEAT 10→T14 · FEAT 11,12→T15 · FEAT 13,14→T16 · FEAT 15,16→T17 · FEAT 17–20→T18 · FEAT 21,24→T19 · FEAT 22,23→T20
- FEAT 25,26→T21 · FEAT 27,28→T22 · FEAT 29–31→T23 · FEAT 32,33→T24 · FEAT 34→T25 · FEAT 35→T26 · FEAT 36,37→T27 · FEAT 38–42→T28
- FEAT 43,46,47,48→T29 · FEAT 44,50→T30 · FEAT 45,49→T31 · FEAT 43-export→T32 · FEAT 52,53→T33 · FEAT 51→T34
- FEAT 55,56,57→T35 · FEAT 58,59,60→T36 · FEAT 61,62→T37 · FEAT 54,63→T38 · FEAT 65→T39 · FEAT 64→T40
- FEAT 66,67→T41 · FEAT 68→T42 · FEAT 69–71→T43 · FEAT 72,73→T44 · FEAT 74,75,77,78,79→T45
- FEAT 80→T47 · FEAT 81→T48 · FEAT 84→T49 · FEAT 82,83→T50 · FEAT 85,86→T51
- FEAT 87→T54 · FEAT 88,89→T55 · FEAT 90,91→T56 · FEAT 92,93,94→T57 · FEAT 95→T58 · FEAT 96→T59 · FEAT 97,99→T60 · FEAT 98→T61 · FEAT 100→T62
- OPT 1,5,8→T01 · OPT 2→T02 · OPT 3,4→T03 · OPT 11→T04 · OPT 12→T05 · OPT 6,7→T06 · OPT 9,10→T07
- OPT 13–19,24→T63 · OPT 20→T64 · OPT 25–30→T65 · OPT 44,45→T66 · OPT 48,49→T67
- OPT 21,22,23→T35 · OPT 32,34,35,36→T46 · OPT 33→T40 · OPT 37,38→T52 · OPT 39–43→T53 · OPT 31→T13 · OPT 46,47→T59 · OPT 50→T33

*(T46 cũng phủ FEAT 81 sub-item đồng bộ comment; T35 phủ OPT cho Presenter)*