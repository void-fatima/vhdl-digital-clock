# نتیجهٔ مرحلهٔ ۰

## بررسی محیط

- مسیر کار: `CA`، پیش از شروع خالی بود.
- فایل `AGENTS.md` در ریشهٔ پروژه یا مسیرهای والد بررسی‌شده وجود نداشت.
- دو تصویر پیوست، صفحات ۲ تا ۴ سند را نشان می‌دهند؛ PDF اصلی و صفحهٔ ۱ در دسترس نبودند.
- `Get-Command ghdl,nvc,vsim,iverilog` هیچ شبیه‌سازی در `PATH` پیدا نکرد. مسیرهای متداول نصب بررسی‌شده نیز GHDL نداشتند؛ این بررسی ادعای جست‌وجوی تمام دیسک نیست.
- Python و PowerShell در دسترس‌اند.
- نسخهٔ قابل‌حمل رسمی GHDL 6.0.0 با backend نوع mcode در `tools/ghdl-6.0.0` آماده شد. نیازی به تغییر `PATH` سیستم نبود.

منبع ابزار: https://github.com/ghdl/ghdl/releases/tag/v6.0.0

فایل دریافت‌شده: `ghdl-mcode-6.0.0-mingw64.zip`، اندازهٔ واقعی `24053403` بایت.

SHA256 محلی برای شناسایی همین فایل دریافت‌شده، بدون ادعای تأیید امضای ناشر:

```text
C1562B2A4767E34D33159B536B5E36A8A38EBDB6E7672AA9969A4F4AC2CADFFE
```

## فایل‌های ایجادشده

| فایل | کاربرد |
| --- | --- |
| `docs/requirements.md` | نیازمندی‌های سند، معماری، پورت‌ها و تصمیم‌های پیشنهادی |
| `docs/stage0_results.md` | دستورات و نتایج واقعی مرحلهٔ ۰ |
| `README.md` | وضعیت فعلی و دستور تکرار تست محیط |
| `sim/tb_setup.vhd` | تست کوچک صحت ابزار؛ مستقل از طراحی ساعت |
| `scripts/check_setup.ps1` | تحلیل، آماده‌سازی، اجرا و بررسی خالی نبودن موج‌ها |
| `.gitignore` | کنار گذاشتن ابزارهای محلی و محصولات ساخت از کنترل نسخه |

## فرمان‌های بررسی و آماده‌سازی

بررسی فایل‌ها و ابزارها با `Get-ChildItem`, `rg --files --hidden`, `Get-Command` و بررسی فایل‌های `AGENTS.md` در والدها انجام شد. برای دریافت و آماده‌سازی ابزار از این فرمان‌ها استفاده شد:

```powershell
$taskRelease = Invoke-RestMethod -Uri 'https://api.github.com/repos/ghdl/ghdl/releases/latest'
New-Item -ItemType Directory -Force -Path tools,docs,sim,scripts,build
Invoke-WebRequest -Uri 'https://github.com/ghdl/ghdl/releases/download/v6.0.0/ghdl-mcode-6.0.0-mingw64.zip' -OutFile 'tools\ghdl-mcode-6.0.0-mingw64.zip'
Expand-Archive -LiteralPath 'tools\ghdl-mcode-6.0.0-mingw64.zip' -DestinationPath 'tools\ghdl-6.0.0'
Get-FileHash -LiteralPath 'tools\ghdl-mcode-6.0.0-mingw64.zip' -Algorithm SHA256
```

فرمان اجرای واقعی از ریشهٔ پروژه:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\check_setup.ps1 2>&1 | Tee-Object -FilePath .\build\setup_run.log
```

اسکریپت از داخل `build/setup` این فرمان‌ها را روی GHDL اجرا کرد؛ مسیر ورودی در اجرای واقعی مطلق بود:

```powershell
..\..\tools\ghdl-6.0.0\bin\ghdl.exe --version
..\..\tools\ghdl-6.0.0\bin\ghdl.exe -a --std=08 ..\..\sim\tb_setup.vhd
..\..\tools\ghdl-6.0.0\bin\ghdl.exe -e --std=08 tb_setup
..\..\tools\ghdl-6.0.0\bin\ghdl.exe -r --std=08 tb_setup --assert-level=error --wave=setup.ghw --vcd=setup.vcd
```

## نتیجهٔ مشاهده‌شده

تحلیل، آماده‌سازی و اجرای تست با کد خروجی صفر پایان یافتند. نسخهٔ ابزار در خروجی `GHDL 6.0.0` و backend آن `mcode` بود.

| سناریو | ورودی / زمان | انتظار | مشاهده | نتیجه |
| --- | --- | --- | --- | --- |
| مقدار آغازین | شروع شبیه‌سازی | `sampled=0` | assertion بدون خطا گذشت | PASS |
| ثبت لبهٔ بالا | `clk` در `5 ns` بالا رفت | `sampled=1` پس از لبه | assertion در `6 ns` گذشت | PASS |
| پشتیبانی زبان | اجرای `std.env.finish` با `--std=08` | پایان عادی | `simulation finished @6ns` | PASS |
| خروجی موج | گزینه‌های `--wave` و `--vcd` | دو فایل غیرخالی | `setup.ghw`: 378 بایت؛ `setup.vcd`: 425 بایت | PASS |

پیام واقعی تست:

```text
PASS: VHDL-2008 setup smoke test
simulation finished @6ns
```

لاگ اجرا در `build/setup_run.log` و موج‌ها در `build/setup` قرار دارند. این نتایج فقط ابزار را تأیید می‌کنند؛ هنوز هیچ قابلیت ساعت، زمان‌سنج یا زنگ آزمایش نشده است.

مرحلهٔ ۰ پایان یافته و مرحلهٔ ۱ تا پیام «ادامه بده» شروع نمی‌شود.
