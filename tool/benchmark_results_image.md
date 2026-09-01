# Benchmark image pipeline — ghita_image (T06)

> Cùng máy, cùng ảnh giả lập (10 JPEG 2048×1536 + 10 PNG 1400×1050); decode → EXIF bake → resize 1600 → re-encode q80.
> Ngày: 2026-09-01T09:33:24.318501

| Kịch bản | Thời gian (tốt nhất 5 lần) | Kích thước |
|---|---|---|
| Pipeline **Dart `image`** | 8.47 s ms | 72.1 MB → 18.8 MB |
| **Đối chiếu Rust vs Dart (T07 P6)** | byte lệch 3.6 MB · PSNR trung bình 27.9 dB · PSNR tệ nhất 16.3 dB | — |
| Pipeline **ghita_image (Rust, tuần tự)** | 4.68 s ms | 72.1 MB → 18.8 MB |
| **Speedup (Dart/Rust tuần tự)** | 1.81× | — |
| Pipeline **ghita_image (Rust, batch/rayon)** | 995.6 ms ms | — |
| **Speedup (Dart/Rust batch)** | 8.51× | — |

