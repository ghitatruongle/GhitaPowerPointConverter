# T17 — Mockup Template (GATE duyệt trước khi viết HTML template chính thức)

> **State:** CHỜ USER DUYỆT — 2026-09-01
> Mỗi bộ: 3 layout (A: Title · B: Nội dung · C: Chi tiết/Table). Render PNG 1280×720 bằng Edge headless từ HTML trong thư mục này.

## Ràng buộc kỹ thuật đã xác nhận (audit T17)

1. **1 template = 1 slide** — `applyTemplate` (editor_state.dart:400) gán toàn bộ `htmlContent` cho slide hiện tại; `slide_layout.dart:257` viết đúng 1 `data-bg-color` div. Không có cơ chế split. → Mockup là layout 1 slide.
2. **Parser contract** (`_mergeElementStyle`, ppt_generator.dart:2847): style sống sót vào PPTX = `color`, `background-color`, `font-size`, `font-family`, `font-weight/bold`, `font-style:italic`, `text-decoration`, `text-align`. Các thuộc tính về màu/viền/border-radius/padding chỉ có hiệu lực khi xem trong Preview (WebView), vẫn giữ được khi blend qua `background-color` nếu cần.
3. **Preview CSS cứng** (slide_preview.dart): rule `h1{color:#fff} h2{…cbd5e1} h3{…} p/li{#e2e8f0} th{white}` → **mọi text element PHẢI có inline `color`** để cover. Với nền sáng (minimal) cực kỳ quan trọng, đã đặt inline color tối cho toàn bộ.
4. **Tag/attribute hỗ trợ**: p/div/h1–h6, ul/ol/li, table/tr/td/th, strong/b, em/i, u/ins, s/del, a[href], br, span, + icon/video/chart… chỉ dùng bộ an toàn.
5. **Nhẹ tài nguyên**: không dùng ảnh, font-family hệ thống (`'Segoe UI', Arial, sans-serif`), không external CSS/font.

## Bảng cấu hình (đồng bộ templates.json)

| Set | Accent (hex) | Recommended effect | Nền mockup |
|---|---|---|---|
| business | #4248BB | fade | #0F1F33 |
| creative | #6A16D3 | zoom | #170A26 |
| academic | #55F6FF | fade | #0E2A2E |
| marketing | #D45A73 | pushLeft | #26121A |
| minimal | #90A54F | fade | #FFFFFF / #F7F9F4 |

## 5 bộ × 3 layout

### 1. BUSINESS — Corporate (accent #4248BB, effect fade)
- **A — Title**: accent line gradient (80×6px) + H1 trắng 44px + subtitle xám sáng (`#A8B3CC`). Tạo cảm giác tài liệu báo cáo trang trọng.
- **B — Content**: 3 ô KPI (nền `rgba(66,72,187,.14)`, viền accent 40%, số lớn accent sáng) — dùng `table` 3 cột với `vertical-align:top`.
- **C — Detail**: timeline dọc 2 mốc (border-left 3px accent, label QUÝ 1/Q2 accent, nội dung `#D7DEEF`).

### 2. CREATIVE — Sáng tạo (accent #6A16D3, effect zoom)
- **A — Title**: gradient line #6A16D3→#C084FC + H1 trắng + subtitle tím nhạt, căn giữa.
- **B — Content**: 3 số 01/02/03 kiểu "trụ cột concept", nền card `rgba(168,85,247,.12)`, viền tím 35%.
- **C — Detail**: big number 64px (#C084FC) + 3 bullet note.

### 3. ACADEMIC — Giáo dục (accent #55F6FF, effect fade)
- **A — Title**: line #55F6FF, H1 trắng + subtitle xanh ngọc nhạt, căn giữa.
- **B — Content**: heading + câu dẫn + 3 bullet dot accent.
- **C — Detail**: bảng kết quả khảo sát 2 dòng, thải `rgba(85,246,255,.16)`, số liệu accent.

### 4. MARKETING — Truyền thông (accent #D45A73, effect pushLeft)
- **A — Title**: gradient line #D45A73→#F08CA4 + H1 trắng + subtitle hồng nhạt.
- **B — Content**: 3 card kênh truyền thông (nền hồng mờ), tên kênh accent đậm + dòng phân bổ ngân sách.
- **C — Detail**: thang đo T1/T2/T3 với nhãn accent bold.

### 5. MINIMAL — Tối giản (accent #90A54F, effect fade) — nền sáng
- **A — Title**: line accent, H1 đen đô (#1C2421) 46px + subtitle xám (#5B665C) — **inline color tối bắt buộc**.
- **B — Content**: heading đen nhạt (#26302A) + 3 bullet dot olive, nền #F7F9F4.
- **C — Detail**: bảng chỉ số nền trắng, header #EDF2E6 (chữ #333D36), số accent #6B7C3C.

## File
- HTML: `tool/template_mockups/{bộ}_{layout}.html` (15 file)
- PNG: cùng tên `.png` (rendered 1280×720)
- Generator: `tool/gen_mockups.py` (sửa lại layout rồi `python tool/gen_mockups.py` + render lại)

## Bước kế tiếp sau khi duyệt (viết HTML template chính thức)
Mỗi bộ → 1 template HTML trong `assets/templates/` (giữ tên file + id + accent + recommendedEffect như cũ, nội dung là content slide mẫu theo layout user chọn trong bộ), có `<aside class="notes">` EN=VI, sau đó preview 100/125/150%, test + l10n CLEAN.

## ✅ KẾT QUẢ CHỐT (2026-09-02) — Duyệt & áp dụng
- **Layout được chọn mọi bộ: B — Content** (tái dùng 3 ô KPI / 3 trụ cột / 3 bullet) làm cấu trúc chính thức.
- HTML chính thức đã viết tại `assets/templates/{business,creative,academic,marketing,minimal}.html` — mỗi file 1 slide, giữ `data-bg-color`, mọi text node có inline `color`, hệ font hệ điều hành, không asset.
- Preview render 100/125/150% không vỡ: `tool/template_previews/*_preview.png` (+ `minimal_125pct/150pct`).
- Pixel-check nền 5/5 khớp hex (`tool/template_previews/check_template_pixels.ps1`).
- Test 7/7 xanh: `test/template_refresh_test.dart` (parse + inline color + export PPTX/PDF/HTML + 20 template cũ).
- i18n: 10 key EN=VI trong `.arb` (templateName*/templateDescription*), Template Studio + search + snackbar áp template đều localized.
- Ma trận chính thức + chi tiết trong RELEASE_PLAN_2.0.5.md mục "KẾT QUẢ T17".
