# نتیجهٔ مرحلهٔ ۵

`digital_clock` از قبل `clock_core`، `time_format`، `timer_engine`، `daily_alarm` و `display_driver` را با `port map` به هم متصل می‌کرد. `display_driver` نیز شش نمونه از `seven_segment` را به شش خروجی وصل می‌کند. برای آزمون یکپارچه از همین RTL و پورت‌ها استفاده شد. ساعت و دقیقهٔ ۲۴ ساعتهٔ تهران مستقیماً از تبدیل زمان به زنگ می‌روند و `case` انتخاب نما فقط دادهٔ ورودی نمایشگر و پرچم‌های قالب را تعیین می‌کند.

## فایل‌ها و فرمان‌ها

| فایل | تغییر |
| --- | --- |
| `sim/tb_digital_clock.vhd` | ایجاد تست‌بنچ یکپارچه روی پورت‌های `digital_clock` |
| `scripts/check_stage5.ps1` | ایجاد ساخت تمیز با GHDL و تولید دو موج |
| `docs/stage5_results.md` | ثبت فرمان‌ها، ممیزی RTL، نتایج و بازه‌های موج |
| `README.md` | افزودن دستور مرحلهٔ ۵ و محل موج‌ها |

فرمان‌های زیر از ریشهٔ پروژه با GHDL قابل‌حمل 6.0.0 اجرا شدند. کد خروج هر اسکریپت جداگانه ثبت و بررسی شد.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage1.ps1 2>&1 | Tee-Object -FilePath .\build\stage5_stage1_regression.log | Out-Null
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage2.ps1 2>&1 | Tee-Object -FilePath .\build\stage5_stage2_regression.log | Out-Null
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage3.ps1 2>&1 | Tee-Object -FilePath .\build\stage5_stage3_regression.log | Out-Null
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage4.ps1 2>&1 | Tee-Object -FilePath .\build\stage5_stage4_regression.log | Out-Null
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_stage5.ps1 2>&1 | Tee-Object -FilePath .\build\stage5_run.log | Out-Null
```

اسکریپت مرحلهٔ ۵ پوشهٔ اختصاصی `build/stage5` را می‌سازد. در اجرای مجدد، فقط فایل کتابخانهٔ قبلی `work-obj08.cf` و دو موج قبلی مرحلهٔ ۵ پاک می‌شوند. اسکریپت از داخل همان پوشه فرمان‌های زیر را اجرا می‌کند و مسیرهای ورودی را به‌صورت مطلق به GHDL می‌دهد.

```powershell
..\..\tools\ghdl-6.0.0\bin\ghdl.exe -a --std=08 ..\..\rtl\clock_types_pkg.vhd ..\..\rtl\clock_core.vhd ..\..\rtl\time_format.vhd ..\..\rtl\seven_segment.vhd ..\..\rtl\display_driver.vhd ..\..\rtl\timer_engine.vhd ..\..\rtl\daily_alarm.vhd ..\..\rtl\digital_clock.vhd ..\..\sim\tb_digital_clock.vhd
..\..\tools\ghdl-6.0.0\bin\ghdl.exe -e --std=08 tb_digital_clock
..\..\tools\ghdl-6.0.0\bin\ghdl.exe -r --std=08 tb_digital_clock --assert-level=error --wave=digital_clock.ghw --vcd=digital_clock.vcd
```

تست‌بنچ در اختلاف خروجی از `severity failure` استفاده می‌کند. برای بررسی کد خروج، همان اسکریپت در یک کپی مستقل زیر `build/stage5_failure_probe` اجرا شد. در تست‌بنچ کپی، مقدار مورد انتظار اولین بررسی عمداً از `00:00:00` به `00:00:01` تغییر کرد. GHDL در `6 ns` اختلاف را گزارش کرد و فرایند PowerShell با کد `1` پایان یافت. لاگ در `build/stage5_failure_probe/failure.log` است.

## نتایج اجرا

| اجرا | کد خروج | نتیجه و زمان پایان شبیه‌سازی |
| --- | --- | --- |
| مرحلهٔ ۱، هستهٔ گرینویچ | `0` | PASS، شامل ۸۶٬۴۰۰ تیک متوالی، `900696 ns` |
| مرحلهٔ ۲، شهر و نمایش | `0` | PASS، `738017 ns` |
| مرحلهٔ ۳، زمان‌سنج‌ها | `0` | PASS، اجرای اصلی `1517 ns` و آزمون سقف `3600026 ns` |
| مرحلهٔ ۴، زنگ | `0` | PASS، `2466226 ns` |
| مرحلهٔ ۵، یکپارچه | `0` | PASS، `387669 ns` |
| بررسی شکست در کپی جداگانه | `1` | در `6 ns` خطای عمدی شناسایی شد. انتظار `00:00:01` و مشاهده `00:00:00` بود. |

`check_outputs` شش بردار سگمنت واقعی را با جدول مرجع ارقام می‌خواند و `HH:MM:SS` را با مقدار مورد انتظار مقایسه می‌کند. ترتیب چهار بیت ثبت‌شده در کنار زمان، `am_pm_valid`, `pm`, `countdown_done`, `alarm_active` است. مثلاً `1101` یعنی PM معتبر، پایان معکوس صفر و زنگ فعال. کلاک دورهٔ `10 ns` دارد و زمان‌های جدول، لحظهٔ بررسی هستند. تست‌بنچ تنظیمات و زمان را فقط از راه پورت‌های ورودی به مدار می‌دهد و بررسی‌ها فقط از پورت‌های خروجی استفاده می‌کنند.

| ورودی یا سناریو | زمان بررسی (`ns`) | انتظار، نمایش و چهار پرچم | مشاهده | نتیجه |
| --- | --- | --- | --- | --- |
| ریست اولیه، گرینویچ و ۲۴ ساعته | `6` | `00:00:00 0000` | `00:00:00 0000` | PASS |
| بارگذاری پنج ثانیه، `view_sel=01`، سپس یک تیک | `17`, `26` | `00:00:05 0000` سپس `00:00:04 0000` | `00:00:05 0000` سپس `00:00:04 0000` | PASS |
| نمای ساعت پس از تیک پنهان، سپس دو تیک دیگر | `27`, `46` | `00:00:01 0000` سپس `00:00:03 0000` | `00:00:01 0000` سپس `00:00:03 0000` | PASS |
| بازگشت به معکوس و تیک بعدی | `47`, `56` | `00:00:02 0000` سپس `00:00:01 0000` | `00:00:02 0000` سپس `00:00:01 0000` | PASS |
| نمای ساعت پیش از پایان معکوس و دو تیک بعد | `57`, `66`, `76` | `00:00:04 0000`، `00:00:05 0010`، `00:00:06 0010` | `00:00:04 0000`، `00:00:05 0010`، `00:00:06 0010` | PASS |
| نمایش معکوس کامل‌شده | `77` | `00:00:00 0010` | `00:00:00 0010` | PASS |
| تیک‌های پیوسته تا پیش از موعد زنگ | `386986` | `10:44:57 0010` | `10:44:57 0010` | PASS |
| بارگذاری ۷۰ ثانیه، سپس انتخاب تهران و ۱۲ ساعته در نمای معکوس با تیک غیرفعال | `386997`, `386998`, `386999` | در هر سه بررسی `00:01:10 0000` | در هر سه بررسی `00:01:10 0000` | PASS |
| بازگشت به نمای ساعت با تنظیم جدید و سپس معکوس | `387000`, `387001` | `02:14:57 1100` سپس `00:01:10 0000` | `02:14:57 1100` سپس `00:01:10 0000` | PASS |
| یک ثانیه پیش از `14:15` تهران و تیک ورود به دقیقهٔ زنگ | `387016`, `387026` | `00:01:08 0000` سپس `00:01:07 0000` | `00:01:08 0000` سپس `00:01:07 0000` | PASS |
| لبهٔ بعد از تطبیق با `tick_1s=0` در نمای معکوس | `387036` | `00:01:07 0001` | `00:01:07 0001` | PASS |
| زنگ فعال و تغییر نما به ساعت، کرنومتر و معکوس | `387037`, `387038`, `387039` | `02:15:00 1101`، `10:45:00 0001`، `00:01:07 0001` | `02:15:00 1101`، `10:45:00 0001`، `00:01:07 0001` | PASS |
| تأیید زنگ و سپس ۵۹ تیک باقی‌ماندهٔ دقیقه | `387046`، `387056` تا `387636` | `00:01:07 0000` پس از تأیید، `alarm_active=0` روی هر ۵۹ تیک، در پایان `00:00:08 0000` | همان دو مقدار نمایش، `alarm_active=0` در هر تیک | PASS |
| تنظیم زنگ به `14:16`، تیک ورود و لبهٔ مقایسه با معکوس در حال شمارش | `387646`, `387656` | `00:00:07 0000` سپس `00:00:07 0001` | `00:00:07 0000` سپس `00:00:07 0001` | PASS |
| ریست همزمان با `countdown_load=1` و `tick_1s=1` و زنگ فعال | `387657`, `387666` | قبل از لبه `00:00:07 0001`، پس از لبه `00:00:00 0000` | `00:00:07 0001` سپس `00:00:00 0000` | PASS |
| مشاهدهٔ کرنومتر، ساعت تهران ۱۲ ساعته و گرینویچ ۲۴ ساعته پس از ریست | `387667`, `387668`, `387669` | `00:00:00 0000`، `03:30:00 1000`، `00:00:00 0000` | `00:00:00 0000`، `03:30:00 1000`، `00:00:00 0000` | PASS |

لاگ ۳۲ بررسی موفق نمایش و پرچم‌ها و پیام `PASS: all stage 5 integration checks` را ثبت کرد. شبیه‌سازی با `simulation finished @387669ns` پایان یافت.

## ممیزی سازه‌های VHDL

شمارهٔ خط‌ها مربوط به RTL بررسی‌شده در مرحلهٔ ۵ هستند.

| سازه | فایل و محل | کاربرد |
| --- | --- | --- |
| `entity` | `rtl/digital_clock.vhd:6`، `rtl/clock_core.vhd:7` | تعریف پورت‌های کل سامانه و هسته |
| `architecture` | `rtl/digital_clock.vhd:38`، `rtl/clock_core.vhd:18` | تعریف معماری `structural` و `rtl` |
| توصیف ساختاری | `rtl/digital_clock.vhd:53`، `rtl/display_driver.vhd:22` | نمونه‌سازی زیرمدارها و شش رمزگشا |
| توصیف رفتاری | `rtl/clock_core.vhd:27`، `rtl/timer_engine.vhd:31`، `rtl/daily_alarm.vhd:25` | توصیف شمارش، کنترل، نگهداری وضعیت و ریست |
| `port map` | `rtl/digital_clock.vhd:54`, `:60`, `:69`, `:82`, `:112` | اتصال هسته، تبدیل زمان، زمان‌سنج، زنگ و نمایشگر |
| انتساب مستقیم | `rtl/time_format.vhd:25` | `display_second <= gmt_second;` |
| `if` | `rtl/clock_core.vhd:30`، `rtl/time_format.vhd:34` | اولویت ریست و انتقال دقیقه در اختلاف تهران |
| `case` | `rtl/digital_clock.vhd:93` | انتخاب منبع دادهٔ نمایش |
| `with ... select` | `rtl/seven_segment.vhd:16` | جدول ترکیبی رمزگشایی ارقام ۰ تا ۹ |
| `process` | `rtl/time_format.vhd:27`، `rtl/clock_core.vhd:27` | نمونهٔ `process (all)` و `process (clk)` |
| نوع و بازه | `rtl/clock_types_pkg.vhd:2` تا `:5`، `rtl/digital_clock.vhd:8`, `:13`, `:25` | ساعت ۰ تا ۲۳، ساعت مدت ۰ تا ۹۹، دقیقه و ثانیه ۰ تا ۵۹، رقم ۰ تا ۹، و کنترل‌ها و خروجی‌های بیتی |
| منطق ترکیبی | `rtl/time_format.vhd:27`، `rtl/digital_clock.vhd:89`، `rtl/seven_segment.vhd:16` | تبدیل زمان، انتخاب نما و رمزگشایی |
| منطق کلاک‌دار | `rtl/clock_core.vhd:29`، `rtl/timer_engine.vhd:33`, `:68`، `rtl/daily_alarm.vhd:28` | به‌روزرسانی ثبات‌ها روی لبهٔ بالارونده |

## شکل موج و بازه‌های مناسب گزارش

| مسیر | مشاهده |
| --- | --- |
| `build/stage5/digital_clock.ghw` | ۱٬۲۹۲٬۰۶۴ بایت |
| `build/stage5/digital_clock.vcd` | ۹٬۴۳۱٬۶۰۷ بایت، مقیاس `1 fs` |
| `build/stage5_run.log` | انتظار و مشاهدهٔ همهٔ بررسی‌های یکپارچه |
| `build/stage5_stage1_regression.log` تا `build/stage5_stage4_regression.log` | لاگ‌های اجرای دوبارهٔ مراحل پیشین |

در جدول زیر، نام‌های کوتاه بیرون از `dut` زیر محدودهٔ `tb_digital_clock` هستند. سیگنال‌های اقلام زمان زیر `tb_digital_clock.dut` قرار دارند. `seg_*` شامل `seg_h10`, `seg_h1`, `seg_m10`, `seg_m1`, `seg_s10`, `seg_s1` است. `display_*` سه مقدار عددی فوری را برای خواندن آسان نشان می‌دهد و `seg_*` خروجی واقعی رمزگشاست.

| سناریو | بازهٔ موج (`ns`) | سیگنال‌های اصلی | رخداد مشاهده‌شده |
| --- | --- | --- | --- |
| پیشروی همزمان، تعویض نما و پایان معکوس پنهان | `15–78` | `clk`, `tick_1s`, `view_sel`, `countdown_load`, `countdown_done`, `dut.gmt_second`, `dut.countdown_second`, `dut.display_*`, `seg_*` | در `65 ns` معکوس صفر و `countdown_done=1` شد و نمایش در نمای ساعت رقم ۵ را نشان داد. |
| تغییر شهر و قالب در نمای مدت | `386994–387003` | `view_sel`, `city_tehran`, `format_12h`, `tick_1s`, `am_pm_valid`, `pm`, `dut.display_*`, `seg_*` | شهر در `386997 ns` و قالب در `386998 ns` تغییر کردند. در `386999 ns` نمای ساعت مقدار `02:14:57 PM` را نشان داد. |
| زنگ در نمای مدت، تغییر نما و تأیید | `387014–387050` | `clk`, `tick_1s`, `view_sel`, `alarm_hour`, `alarm_minute`, `alarm_ack`, `alarm_active`, `dut.tehran_hour`, `dut.tehran_minute`, `dut.display_*` | ورود به `14:15` در `387025 ns`، فعال شدن زنگ با تیک غیرفعال در `387035 ns` و خاموشی با تأیید در `387045 ns` ثبت شدند. |
| مهار زنگ در باقی دقیقه | `387045–387636` | `alarm_ack`, `alarm_active`, `tick_1s`, `dut.tehran_minute`, `dut.gmt_second`, `dut.alarm.minute_consumed`, `dut.countdown_second` | پس از تأیید، ۵۹ تیک طی شدند و `alarm_active` صفر ماند. |
| ریست با زنگ و زمان‌سنج فعال | `387643–387669` | `reset`, `clk`, `tick_1s`, `countdown_load`, `countdown_done`, `alarm_active`, `view_sel`, `am_pm_valid`, `pm`, `dut.countdown_second`, `dut.stopwatch_second`, `dut.display_*`, `seg_*` | زنگ جدید در `387655 ns` فعال و با ریست در `387665 ns` صفر شد. تعویض نما صفر هر دو زمان‌سنج و مقدار ساعت تهران پس از ریست را نشان داد. |

فرمان بررسی بخش‌هایی از VCD و اندازهٔ فایل‌ها چنین بود.

```powershell
Get-Content -LiteralPath .\build\stage5\digital_clock.vcd -TotalCount 47
Select-String -LiteralPath .\build\stage5\digital_clock.vcd -Pattern '^#(65|386997|386998|386999|387025|387035|387045|387635|387655|387665)000000$' -Context 0,6
Get-Item -LiteralPath .\build\stage5\digital_clock.ghw,.\build\stage5\digital_clock.vcd | Format-Table Name,Length
```
