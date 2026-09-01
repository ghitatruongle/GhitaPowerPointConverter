# Benchmark beta1 (T09) — đối chiếu & hotspot

> Ngày: 2026-09-01 · Deck chuẩn 20 slide (4 nội dung duy nhất × 5) + deck ảnh 72,1 MB.
> Bảng chi tiết: `benchmark_results_t01.md` (PPTX parse/build/zip), `t02.md` (media zip),
> `t07.md` (PDF/HTML), `media.md` (zip 21,1 MB), `image.md` (ghita_image).

## Bảng tổng hợp (beta1)

| Đo lường | Parse | Build XML | ZIP | Tổng | Ghi chú |
|---|---|---|---|---|---|
| PPTX lần 1 | 3,0 ms | 23,3 ms | 29,3 ms | 58,3 ms | 45.278 B |
| PPTX lần 2 (cache ấm) | 0,0 ms | 8,1 ms | 19,4 ms | 30,9 ms | — |
| PDF (tổng) | — | — | — | 422 ms | 165.314 B |
| HTML (tổng) | — | — | — | 114 ms | 17.032 B |
| ZIP media deck 21,1 MB (Dart) | — | — | 105–119 ms | — | Rust 132–142 ms (FRB copy) |
| Images 72,1 MB (Dart) | — | — | — | 8,47 s | — |
| **Images (Rust batch/rayon)** | — | — | — | **0,996 s** | **8,51×** |

## Hotspot bảng chứng (theo số, không đoán)

1. **Ảnh (decode/resize/re-encode)** — là chi phí lớn nhất toàn mốc: 8,47 s/72 MB trên đường Dart → **8,51× với Rust batch** (T06, `image.md`). Đã chuyển default engine ảnh = Rust.
2. **ZIP encode deck 20 slide** — 19,4–29,3 ms (còn nhỏ); deck media: chi phí FRB copy nuốt lợi thế Rust (T02 — đã chốt Dart default, có số).
3. **Build XML** — 8,1–23,3 ms; PDF 422 ms chủ yếu là layout/draw (không thay đổi trong mốc — không refactor lớn theo đúng "đo rồi mới sửa").
4. **Parse HTML** — cache parse hiệu quả tuyệt đối: 3,0 ms → **0,0 ms** khi ấm (T01 đã làm, tái xác nhận beta1).

## Quyết định "giữ/loại" (T09.8)

| Tối ưu | Số đo | Kết luận |
|---|---|---|
| Cache parse HTML theo hash | 3,0 → 0,0 ms | **GIỮ** (đã có, xác nhận lại) |
| Rust batch xử lý ảnh | 8,51× | **GIỮ** (T06/T07) |
| Cache đĩa ảnh đã xử lý | bỏ qua decode/re-encode lần sau | **GIỮ** (T07.5) |
| Tối ưu đường build XML / player | không có bằng chứng vượt trội trong mốc | **LOẠI — ghi lý do, hoãn beta2 nếu hotspot thật** |
| API streaming zip file→file (T02 đề xuất) | media deck Rust kém do copy | **HOÃN** chỉ làm khi profile cho thấy lợi |
