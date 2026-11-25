# Digital Clock Mini-Project

این پروژه با `VHDL-2008` ساخته شده است. در مرحلهٔ ۵، ساعت گرینویچ و تهران، قالب ۱۲ یا ۲۴ ساعته، شمارش معکوس، کرنومتر و زنگ روزانه در `digital_clock` با آزمون یکپارچه بررسی شدند.

نیازمندی‌ها، معماری پیشنهادی، خلاصهٔ پورت‌ها و تصمیم‌های مربوط به ریست، زمان‌سنج و زنگ در [docs/requirements.md](docs/requirements.md) ثبت شده‌اند. وضعیت ابزار و نتایج مرحلهٔ ۰ در [docs/stage0_results.md](docs/stage0_results.md) آمده‌اند.

برای اجرای آزمون‌های هسته، نمایش، زمان‌سنج‌ها، زنگ و یکپارچه‌سازی با `--std=08`، از ریشهٔ پروژه اجرا کنید.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage2.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage3.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage4.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage5.ps1
```

موج‌های هسته در `build/stage1/clock_core.ghw` و `build/stage1/clock_core.vcd` ذخیره می‌شوند و نتایج آن در [docs/stage1_results.md](docs/stage1_results.md) آمده‌اند. موج‌های نمایش در `build/stage2/clock_display.ghw` و `build/stage2/clock_display.vcd` تولید می‌شوند. نتایج و قرارداد نمایش در [docs/stage2_results.md](docs/stage2_results.md) ثبت شده‌اند.

موج‌های مرحلهٔ ۳ در `build/stage3/clock_timers.ghw` و `build/stage3/clock_timers.vcd` تولید می‌شوند. همان اسکریپت آزمون سقف کرنومتر را هم در یک اجرای جداگانه انجام می‌دهد. قواعد کنترل و زمان‌های آزمون در [docs/stage3_results.md](docs/stage3_results.md) آمده‌اند.

موج‌های زنگ در `build/stage4/daily_alarm.ghw` و `build/stage4/daily_alarm.vcd` تولید می‌شوند. کنترل‌ها، نتایج و بازه‌های موج در [docs/stage4_results.md](docs/stage4_results.md) ثبت شده‌اند.

`check_stage5.ps1` ساخت یکپارچه را در پوشهٔ اختصاصی `build/stage5` از نو انجام می‌دهد و `digital_clock.ghw` و `digital_clock.vcd` را در همان پوشه تولید می‌کند. مکان سازه‌های VHDL، نتیجهٔ هر سناریو و بازه‌های موج در [docs/stage5_results.md](docs/stage5_results.md) آمده‌اند.

خروجی‌های `display_driver` از چپ به راست `seg_h10`, `seg_h1`, `seg_m10`, `seg_m1`, `seg_s10`, `seg_s1` هستند. هر خروجی با ترتیب `abcdefg` و فعال با `1` است. صفرهای پیشرو همیشه نمایش داده می‌شوند. در نمای ساعت ۱۲ ساعته، `am_pm_valid=1` است و `pm=0` یعنی AM و `pm=1` یعنی PM. در نمای ساعت ۲۴ ساعته و هر دو نمای زمان‌سنج، هر دو خروجی صفرند.

در `digital_clock`، مقدار `view_sel` برابر `00` یا `11` ساعت را نشان می‌دهد. `01` شمارش معکوس و `10` کرنومتر را نشان می‌دهد. هر زمان‌سنج با `run=1` و تیک فعال حرکت می‌کند و با `run=0` مکث می‌کند. `countdown_load` مدت جدید را ثبت می‌کند و `stopwatch_clear` کرنومتر را صفر می‌کند.

`alarm_hour` و `alarm_minute` با زمان ۲۴ ساعتهٔ تهران مقایسه می‌شوند. `alarm_enable=1` اجازهٔ فعال شدن می‌دهد و `alarm_ack=1` زنگ را در لبهٔ بالارونده تأیید و خاموش می‌کند. پس از ورود به دقیقهٔ تنظیم‌شده، زنگ روی نخستین لبهٔ بالارونده که زمان جدید در ورودی مقایسه حاضر است، فعال می‌شود. این لبه می‌تواند `tick_1s=0` داشته باشد.

برای تکرار تست محیط در PowerShell از ریشهٔ پروژه:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_setup.ps1
```

اسکریپت ابتدا `tools/ghdl-6.0.0/bin/ghdl.exe` و سپس `ghdl` موجود در `PATH` را بررسی می‌کند. همهٔ مراحل تحلیل، آماده‌سازی و اجرای تست با `--std=08` انجام می‌شوند. خروجی‌های تست محیط در `build/setup` هستند؛ این موج‌ها فقط صحت ابزار را نشان می‌دهند و موج آزمون ساعت نیستند.

نسخهٔ قابل‌حمل انتخاب‌شده: GHDL 6.0.0، Windows x86-64، mcode، از [انتشار رسمی](https://github.com/ghdl/ghdl/releases/tag/v6.0.0). ابزار و محصولات ساخت در تحویل نهایی ZIP قرار نمی‌گیرند؛ دستورهای کامل اجرای طراحی در مراحل بعد افزوده می‌شوند.
