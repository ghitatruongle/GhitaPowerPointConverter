# MANUAL CHECKLIST — GhitaPPT v2.0.5-demo

> Cận kề thủ công trên máy Windows thật (dành cho người duyệt; phần tự động
> đã nằm trong suite/probe — mục "Đã xác minh tự động" bên dưới).
> Ký hiệu: [ ] chưa làm · [x] đã qua.

## Runtime chung
- [x] **Cài đặt thật + mở app** (bản trước khi đổi mặc định): silent install passed, app sống >6s — máy đã xóa sạch sau đó (2026-08-31)
- [ ] **Cài bản MỚI (Program Files mặc định + chọn vị trí)**: bấm Setup → UAC → mặc định `C:\Program Files\GhitaPPT Converter` → thử "Browse" chọn thư mục khác → cài + mở app — máy hiện sạch, chờ bạn cài thật khi nghiệm thu
- [ ] Settings → Engine: dòng trạng thái mặc định Dart (quyết định đo T02); bật Rust thử → "Running on the Rust engine (ghita_core 0.1.0)"; đổi lại Dart — **chuyển beta1 manual pass**
- [ ] Settings → Engine → "Tối ưu ảnh (beta)": bật/tắt + persist sau restart — **chuyển beta1 manual pass**

## N1 — Báo cáo Word (.docx)
- [ ] Ctrl+Shift+E → chip "Word report (.docx)" + checkbox "Kèm danh sách slide" — **chuyển beta1 manual pass**
- [ ] Xuất deck Việt + ghi chú → mở Word: không repair — **đã có bằng chứng tự động**: Word 16.0 COM OPEN_OK (15 paragraph, "Báo cáo demo")
- [ ] Tắt "Kèm danh sách slide" → cuối báo cáo không còn danh sách — **đã có test unit** (docx_report_service_test)

## N2 — Tối ưu ảnh (beta)
- [ ] Bật flag → xuất deck 10 ảnh → snackbar "Tiết kiệm: …" — **chuyển beta1 manual pass** (logic đã test 54,0%)
- [ ] Tắt flag → snackbar không có dòng tiết kiệm — **chuyển beta1 manual pass**

## PowerPoint (PPTX) + Rust engine
- [x] PPTX engine mở bằng PowerPoint thật (COM OPEN_OK, không repair) — bằng chứng tự động build/t02_engine_probe.pptx
- [ ] Xuất PDF bookmarks/notes pages → mở PDF reader — **chuyển beta1 manual pass** (suite có test advanced)
- [ ] Xuất HTML deck → trình duyệt: mũi tên + F fullscreen — **chuyển beta1 manual pass**

## Đóng gói
- [x] Cài bản Setup trên máy này: silent install + launch alive (mục trên)
- [ ] Cài máy khác/sạch + gỡ cài: project/settings giữ nguyên — **chuyển beta1 manual pass**
- [x] Bản cài đặt không có thông tin sai: Version 2.0.5-demo+4 (manifest release.json)

## Đã xác minh TỰ ĐỘNG (không cần thủ công)
- Suite 1041/1041 xanh ×2 · analyze 0 · l10n audit CLEAN · coverage 51,9% (ex-l10n ≥ ratchet 51,5%)
- Probe real-DLL (integration_test/rust_engine_probe_test.dart -d windows): 4/4
- Office thật: PPTX PowerPoint 16.0 COM OPEN_OK · DOCX Word 16.0 COM OPEN_OK
- 0 TCP outbound trong 7s đầu trên exe Release (privacy) · installer verify smoke install/launch/validation Passed
