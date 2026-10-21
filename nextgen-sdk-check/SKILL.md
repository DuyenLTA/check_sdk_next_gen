---
name: nextgen-sdk-check
description: Chấm checklist nâng cấp SDK quảng cáo Next-Gen (GMA next-gen + Apero lib + SDK tutorial VslTemplate4) trên máy Android thật — mục 1 SDK/build, mục 2 hiển thị HT, mục 3 event EV, mục 4 KT/MED/CMP/EV-30..32/HV/RG — ra report Khớp/Sai rồi publish artifact. Dùng khi user đưa APK/package mới lên Next-Gen và bảo check SDK next gen, check checklist ads, so bản cũ.
user-invocable: true
when_to_use: "Invoke when the user asks to check/verify the Next-Gen ads SDK checklist (SDK build, HT display, EV events, KT/MED/CMP/HV cases) for an Android app on a real device."
category: dev-tools
keywords: [android, ads, admob, next-gen, checklist, logcat, firebase, tutorial-sdk]
argument-hint: "<package> [mục: 1|2|3|4|all] [link checklist]"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Artifact
---

# Next-Gen SDK check

Tham số: `$ARGUMENTS` (package, mục cần chấm, có thể kèm checklist dán vào).

Checklist gốc (nguyên văn user gửi): `references/checklist-muc1-sdk-build.txt`, `checklist-muc2-hien-thi-HT.txt`,
`checklist-muc3-event-EV.txt`, `checklist-muc4-nextgen-KT-MED-CMP-EV3x-HV-RG.txt`.
User dán checklist mới thì **dùng bản user dán**, bản trong references chỉ để tham chiếu.
Cách đo từng case + bẫy đã gặp: **đọc `references/how-to-measure-each-case.md` trước khi chạy**.

## Luật chấm (user chốt — không ngoại lệ)

1. Chỉ **Khớp** hoặc **Sai**. Không "Chưa test", "Không xác định", "Blocked". Lái hụt thì tự lái lại tới khi ra kết quả.
2. **Chỉ chấm Sai bug dev sửa được bằng code** (app, lib ads, SDK). Cấu hình tài khoản AdMob (form UMP…), quyết định PO (minSdk app, có nhắm EEA…), giới hạn SDK Google/server → mục "Ngoài phạm vi / không áp dụng", không viết "PO xác nhận".
3. minSdk: chấm theo **lib ads + SDK tutorial**, minSdk app kệ.
4. Phạm vi mặc định: **luồng tutorial** (splash, Language, onboarding, Question, paywall, app open khi quay lại). Case chỉ có in-app (rewarded chat, native danh sách, banner Home…) → mục ngoài phạm vi, trừ khi user bảo check in-app.
5. Case cần điều kiện không tạo được trên máy (RC phải đổi mà app không debuggable, không có máy Android 7…) → tìm đường khác trước (đọc manifest, đọc RC qua REST, bản cũ để so); hết cách thật thì đưa vào mục riêng không tính và nói rõ cần gì.
6. Sai phải lặp ≥2 lần cùng điều kiện, và với case "so bản cũ" phải đo bản cũ cùng điều kiện, trước khi báo.
7. **Không git add / commit / push.**

## Quy trình

1. **Máy + bản**: `adb devices -l` (1 máy). `dumpsys package <pkg> | grep -E "versionName|versionCode|lastUpdateTime"`, `sha256sum` APK (`adb pull $(pm path)` vào scratchpad, dùng lại cho cài đè). Máy khoá thì mở khoá trước. Kiểm sub test còn hạn (xem bẫy).
2. **Bản cũ để so** — mặc định BỎ (user chốt 15/10): CMP-01/02/03, KT-07, HV-06, EV-27 ghi "bỏ theo yêu cầu"; KT-02 chấm theo timeout RC, MED-01 theo adapter bản mới. Chỉ dùng bản cũ khi user đưa APK cùng key: `~/.cache/ad-checklist-diff/<pkg>-<versionCode>.apk`; kiểm `unzip -l | grep play-services-ads.properties` (= SDK cũ). Không có thì hỏi user APK bản cũ.
3. **Log**: `setprop debug.firebase.analytics.app <pkg>`, `log.tag.FA`/`FA-SVC VERBOSE`; mỗi lượt một file `adb logcat -v threadtime > <scratchpad>/log-X.txt &` + file marks ghi mốc thao tác.
4. **Lái app** bằng script trong `scripts/` (đều nhận package làm tham số):
   - `ui-dump.sh` — liệt kê node + toạ độ; `tap-by-id.sh '<regex id/text>'`
   - `cold-start-new-user.sh <pkg> <marks>` — pm clear + mở + chờ qua splash
   - `drive-fo-to-home.sh <pkg> <marks> [noclear]` — đi hết FO tới Home, đóng ads (tìm nút theo resource-id VslTemplate4)
   - `continue-fo-from-current-screen.sh <marks> [stop-regex]` — đi tiếp FO từ màn đang mở (sau khi bật lại mạng…)
   - `splash-inter-display-cases.sh <pkg> <out>` — HT-03/HV-01/HV-02/HT-05/HT-04 trên inter splash (user cũ)
   - `hunt-fullscreen-native-onboarding.sh <pkg> <out> [n]` — chạy user mới tới khi OB toàn màn có fill (HT-09)
   - `slow_ads_proxy.py PORT DELAY KBPS [HOST_REGEX]` — mạng chậm (docstring có lệnh nối/gỡ proxy)
5. **Phân tích**: `parse_fa_events.py` + `summarize_ad_events.py` (EV), `compare_ad_requests.py old new` (CMP-01/02), `launch_stage_timing.py logs…` (CMP-03, KT-02), `fetch_remote_config.py <apk> out.json` (đọc RC thật của bản release: timeout, key bật/tắt unit, `_o_`/`_n_` id).
6. Mỗi vòng nói 1 dòng đang ở case nào / màn nào.

## Report

- HTML artifact, một report mỗi lần user gửi một mục (hoặc gộp nếu user bảo). Khung: `assets/report-style-and-filter-script.html` (style + script lọc), mẫu đầy đủ: `assets/example-report-lingospeak.html`.
- Bố cục: header (package, bản + sha, máy, giờ chạy, phạm vi) → 4 thẻ lọc (Tất cả / Khớp / Sai / Sai mới — không phải lỗi có sẵn ở bản cũ) → khối **Cần báo dev** (chỉ bug dev) → danh sách `<details data-v="pass|fail" [data-new="1"]>` gập theo nhóm, mỗi case có dòng log bằng chứng **cùng lượt** với kết luận → mục "Ngoài phạm vi / không áp dụng" → mục "Cần bản debuggable" nếu có → footer liệt kê lượt chạy + trạng thái máy để lại.
- Viết tiếng Việt, ngắn, có số đo thật. Không có mục ảnh chụp.
- Publish bằng Artifact (icon `checklist`), rồi **mở link bằng trình duyệt thật**: `setsid nohup xdg-open "<url>" >/dev/null 2>&1 &`. Chạy lại case → cập nhật đúng file/URL cũ (thêm khối "Lượt n" trong case, sửa thẻ đếm).
- Trả lời user: link (riêng tư, bật Share nếu cần), số Khớp/Sai, từng Sai là gì, case không tính và vì sao, trạng thái máy (proxy đã gỡ, sub test, bản đang cài).
