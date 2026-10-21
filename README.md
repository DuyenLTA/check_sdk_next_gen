# check_sdk_next_gen

Claude Code skill `nextgen-sdk-check`: chấm checklist SDK Next-Gen (Mục 1–4: SDK/build, hiển thị HT, event EV, KT/MED/CMP/HV) trên máy Android thật, chỉ ra Khớp / Sai, xuất report HTML.

## Cài

```
cp -r nextgen-sdk-check ~/.claude/skills/
```

Gọi: `/nextgen-sdk-check <package>`.

## Nội dung

- `nextgen-sdk-check/SKILL.md` — luật chấm + quy trình
- `nextgen-sdk-check/references/` — checklist gốc, cách đo từng case + bẫy đã gặp
- `nextgen-sdk-check/scripts/` — lái app (adb), proxy mạng chậm, parse log Firebase Analytics, đọc Remote Config bản release
- `nextgen-sdk-check/assets/` — khung report HTML + report mẫu
