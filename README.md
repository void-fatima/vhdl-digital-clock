# Digital Clock Mini-Project

ساعت گرینویچ، انتخاب تهران و قالب ۱۲ یا ۲۴ ساعته روی نمایشگر شش‌رقمی شبیه‌سازی شده‌اند.

نیازمندی‌ها و تصمیم‌های طراحی در [docs/requirements.md](docs/requirements.md) ثبت شده‌اند. نتایج و مسیر شکل موج‌ها در مستندات زیر آمده‌اند.

- [docs/stage0_results.md](docs/stage0_results.md)
- [docs/stage1_results.md](docs/stage1_results.md)
- [docs/stage2_results.md](docs/stage2_results.md)

فرمان‌های شبیه‌سازی را از ریشهٔ پروژه در PowerShell اجرا کنید. اسکریپت‌ها از GHDL 6.0.0 قابل‌حمل در `tools/ghdl-6.0.0/bin` یا `ghdl` در `PATH` استفاده می‌کنند.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_setup.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage2.ps1
```
