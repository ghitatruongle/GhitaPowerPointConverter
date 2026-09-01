
## Benchmark deck chuẩn 20 slide (Track 01) — 2026-08-11 06:55:18

| Đo lường | Parse | Build XML | Nén ZIP | Tổng | Dung lượng |
|---|---|---|---|---|---|
| Trước (v1.6.3): parse lẻ + ZIP mức 1, nén cả media | 58.1 ms | — (nằm trong Tổng) | — | 106 ms | 40878 B |
| Sau (T01): parse 1 lần + ZIP mức 9, media stored | 2.1 ms | 17.3 ms | 15.1 ms | 36.6 ms | 38956 B |
| Sau, lần 2 cùng phiên (cache đã ấm) | 0.0 ms | 9.7 ms | 8.9 ms | 20.1 ms | 38956 B |
| Sau (T01): PDF (tổng) | — | — | — | 277 ms | 165084 B |
| Sau (T01): HTML (tổng) | — | — | — | 30.7 ms | 25723 B |
| Tham khảo | deck 20 slide, 4 nội dung duy nhất (lặp 5 lần), có ảnh PNG 128x96 | — | — | — | — |

## Baseline v2.0.1-stable Phase1 (2026-08-24) — 2026-08-24 23:08:17

| Đo lường | Parse | Build XML | Nén ZIP | Tổng | Dung lượng |
|---|---|---|---|---|---|
| Trước (v1.6.3): parse lẻ + ZIP mức 1, nén cả media | 79.9 ms | — (nằm trong Tổng) | — | 167 ms | 48138 B |
| Sau (T01): parse 1 lần + ZIP mức 9, media stored | 1.2 ms | 15.3 ms | 17.0 ms | 35.2 ms | 45278 B |
| Sau, lần 2 cùng phiên (cache đã ấm) | 0.0 ms | 4.5 ms | 13.3 ms | 20.1 ms | 45278 B |
| Sau (T01): PDF (tổng) | — | — | — | 269 ms | 165314 B |
| Sau (T01): HTML (tổng) | — | — | — | 97.7 ms | 22037 B |
| Tham khảo | deck 20 slide, 4 nội dung duy nhất (lặp 5 lần), có ảnh PNG 128x96 | — | — | — | — |

## P3a re-run 1 — 2026-08-25 10:28:26

| Đo lường | Parse | Build XML | Nén ZIP | Tổng | Dung lượng |
|---|---|---|---|---|---|
| Trước (v1.6.3): parse lẻ + ZIP mức 1, nén cả media | 86.5 ms | — (nằm trong Tổng) | — | 186 ms | 48138 B |
| Sau (T01): parse 1 lần + ZIP mức 9, media stored | 1.7 ms | 14.1 ms | 20.1 ms | 37.7 ms | 45278 B |
| Sau, lần 2 cùng phiên (cache đã ấm) | 0.0 ms | 4.6 ms | 14.6 ms | 21.0 ms | 45278 B |
| Sau (T01): PDF (tổng) | — | — | — | 284 ms | 165314 B |
| Sau (T01): HTML (tổng) | — | — | — | 99.5 ms | 22037 B |
| Tham khảo | deck 20 slide, 4 nội dung duy nhất (lặp 5 lần), có ảnh PNG 128x96 | — | — | — | — |

## P3a re-run 2 — 2026-08-25 10:41:37

| Đo lường | Parse | Build XML | Nén ZIP | Tổng | Dung lượng |
|---|---|---|---|---|---|
| Trước (v1.6.3): parse lẻ + ZIP mức 1, nén cả media | 64.1 ms | — (nằm trong Tổng) | — | 149 ms | 48138 B |
| Sau (T01): parse 1 lần + ZIP mức 9, media stored | 1.3 ms | 13.3 ms | 16.6 ms | 32.9 ms | 45278 B |
| Sau, lần 2 cùng phiên (cache đã ấm) | 0.0 ms | 4.7 ms | 11.5 ms | 18.2 ms | 45278 B |
| Sau (T01): PDF (tổng) | — | — | — | 290 ms | 165314 B |
| Sau (T01): HTML (tổng) | — | — | — | 88.9 ms | 22037 B |
| Tham khảo | deck 20 slide, 4 nội dung duy nhất (lặp 5 lần), có ảnh PNG 128x96 | — | — | — | — |

## P3a re-run 3 — 2026-08-25 10:41:42

| Đo lường | Parse | Build XML | Nén ZIP | Tổng | Dung lượng |
|---|---|---|---|---|---|
| Trước (v1.6.3): parse lẻ + ZIP mức 1, nén cả media | 61.0 ms | — (nằm trong Tổng) | — | 139 ms | 48138 B |
| Sau (T01): parse 1 lần + ZIP mức 9, media stored | 1.6 ms | 13.4 ms | 19.0 ms | 36.0 ms | 45278 B |
| Sau, lần 2 cùng phiên (cache đã ấm) | 0.0 ms | 5.6 ms | 11.2 ms | 19.2 ms | 45278 B |
| Sau (T01): PDF (tổng) | — | — | — | 256 ms | 165314 B |
| Sau (T01): HTML (tổng) | — | — | — | 89.8 ms | 22037 B |
| Tham khảo | deck 20 slide, 4 nội dung duy nhất (lặp 5 lần), có ảnh PNG 128x96 | — | — | — | — |

## beta1 — 2026-09-01 09:44:56

| Đo lường | Parse | Build XML | Nén ZIP | Tổng | Dung lượng |
|---|---|---|---|---|---|
| Trước (v1.6.3): parse lẻ + ZIP mức 1, nén cả media | 121 ms | — (nằm trong Tổng) | — | 255 ms | 48138 B |
| Sau (T01): parse 1 lần + ZIP mức 9, media stored | 3.0 ms | 23.3 ms | 29.3 ms | 58.3 ms | 45278 B |
| Sau, lần 2 cùng phiên (cache đã ấm) | 0.0 ms | 8.1 ms | 19.4 ms | 30.9 ms | 45278 B |
| Sau (T01): PDF (tổng) | — | — | — | 422 ms | 165314 B |
| Sau (T01): HTML (tổng) | — | — | — | 114 ms | 17032 B |
| Tham khảo | deck 20 slide, 4 nội dung duy nhất (lặp 5 lần), có ảnh PNG 128x96 | — | — | — | — |
