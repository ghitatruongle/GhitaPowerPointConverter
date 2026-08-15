
## Benchmark deck chuẩn 20 slide (Track 01) — 2026-08-11 06:55:18

| Đo lường | Parse | Build XML | Nén ZIP | Tổng | Dung lượng |
|---|---|---|---|---|---|
| Trước (v1.6.3): parse lẻ + ZIP mức 1, nén cả media | 58.1 ms | — (nằm trong Tổng) | — | 106 ms | 40878 B |
| Sau (T01): parse 1 lần + ZIP mức 9, media stored | 2.1 ms | 17.3 ms | 15.1 ms | 36.6 ms | 38956 B |
| Sau, lần 2 cùng phiên (cache đã ấm) | 0.0 ms | 9.7 ms | 8.9 ms | 20.1 ms | 38956 B |
| Sau (T01): PDF (tổng) | — | — | — | 277 ms | 165084 B |
| Sau (T01): HTML (tổng) | — | — | — | 30.7 ms | 25723 B |
| Tham khảo | deck 20 slide, 4 nội dung duy nhất (lặp 5 lần), có ảnh PNG 128x96 | — | — | — | — |
