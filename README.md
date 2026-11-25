# Digital Clock Mini-Project

ساعت، زمان‌سنج‌ها و زنگ روزانهٔ تهران در `digital_clock` به هم وصل شده‌اند.

نیازمندی‌ها و تصمیم‌های طراحی در [docs/requirements.md](docs/requirements.md) ثبت شده‌اند. نتایج و مسیر شکل موج‌ها در مستندات زیر آمده‌اند.

- [docs/stage0_results.md](docs/stage0_results.md)
- [docs/stage1_results.md](docs/stage1_results.md)
- [docs/stage2_results.md](docs/stage2_results.md)
- [docs/stage3_results.md](docs/stage3_results.md)
- [docs/stage4_results.md](docs/stage4_results.md)

فرمان‌های شبیه‌سازی را از ریشهٔ پروژه در PowerShell اجرا کنید. اسکریپت‌ها از GHDL 6.0.0 قابل‌حمل در `tools/ghdl-6.0.0/bin` یا `ghdl` در `PATH` استفاده می‌کنند.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_setup.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage2.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage3.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage4.ps1
```
