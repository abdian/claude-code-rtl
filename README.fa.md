<div align="center">

<img src="docs/social-card.png" alt="Claude Code · RTL" width="820">

# Claude Code · RTL

[English](README.md) · **فارسی**

**چتِ افزونه‌ی [Claude Code](https://www.anthropic.com/claude-code) در VSCode را راست‌به‌چپ کن، با یک فونتِ تمیزِ همراه (Vazir).**

روی **ویندوز · مک · لینوکس** کار می‌کند — نصب‌کننده خودش سیستم‌عامل را تشخیص می‌دهد.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Platforms](https://img.shields.io/badge/platform-Windows_%7C_macOS_%7C_Linux-informational)
![Install](https://img.shields.io/badge/install-one_line-d97757)
![Reversible](https://img.shields.io/badge/fully-reversible-blue)

</div>

---

<div dir="rtl">

## چی‌کار می‌کند

چتِ Claude Code انگلیسی‌محور و چپ‌به‌راست است. اگر فارسی، عربی، عبری یا هر خطِ راست‌به‌چپی می‌نویسی، بد و به‌هم‌ریخته خوانده می‌شود. این ابزار کلِ گفتگو را تمیز راست‌به‌چپ می‌کند:

- **پاسخ‌ها، پیام‌های خودت، کادرِ نوشتن، و دیالوگ‌های گزینه‌دار** را راست‌به‌چپ می‌کند،
- **کد، diff و ادیتورهای Monaco را چپ‌به‌راست** نگه می‌دارد تا چیزی خراب رندر نشود،
- کادرِ نوشتن **هوشمند** است — خطِ فارسی راست‌به‌چپ، ولی کد/انگلیسی چپ‌به‌راست،
- یک فونتِ **Vazir**‌ تمیز می‌گذارد (فقط روی پنلِ چت اثر دارد)،
- **idempotent**، **برگشت‌پذیر** است و **بعد از هر آپدیت خودش دوباره اعمال می‌شود**.

</div>

---

<div dir="rtl">

## نصب — یک خط

> **پیش‌نیاز:** خودِ افزونه‌ی [Claude Code](https://www.anthropic.com/claude-code) باید در VSCode نصب باشد. (نصب‌کننده چک می‌کند و اگر نبود بهت می‌گوید.)

**مک / لینوکس** — این را در ترمینال کپی کن:

</div>

```bash
curl -fsSL https://raw.githubusercontent.com/abdian/claude-code-rtl/main/install.sh | bash
```

<div dir="rtl">

**ویندوز** — این را در PowerShell کپی کن:

</div>

```powershell
irm https://raw.githubusercontent.com/abdian/claude-code-rtl/main/install.ps1 | iex
```

<div dir="rtl">

همین! خودش نصب و اعمال می‌کند و auto-apply را هم روشن می‌کند. **قدم آخر:** VSCode را ری‌لود کن —
`Ctrl`/`Cmd` `Shift` `P` → **Developer: Reload Window**.

بدون clone، بدون `chmod`، بدون Gatekeeper، و **ویندوز هم به Git نیاز ندارد**.

</div>

<details>
<summary>ترجیح می‌دهی ریپو را دانلود کنی و از منو استفاده کنی؟</summary>

<div dir="rtl">

ریپو را clone یا ZIP دانلود کن، بعد:

- **ویندوز** — روی **`install-windows.cmd`** دابل‌کلیک کن _(به [Git for Windows](https://git-scm.com/download/win) نیاز دارد)_.
- **مک** — یک‌بار `chmod +x install-macos.command scripts/*.sh`، بعد دابل‌کلیک روی **`install-macos.command`** (اگر Gatekeeper بست: راست‌کلیک → **Open**).
- **لینوکس** — `bash scripts/menu.sh`.

این یک منوی تعاملی باز می‌کند (اعمال، تغییر فونت، auto-apply، بازگردانی). بعد VSCode را ری‌لود کن.

</div>
</details>

---

<div dir="rtl">

## حذف — یک خط

**مک / لینوکس:**

</div>

```bash
curl -fsSL https://raw.githubusercontent.com/abdian/claude-code-rtl/main/uninstall.sh | bash
```

<div dir="rtl">

**ویندوز:**

</div>

```powershell
irm https://raw.githubusercontent.com/abdian/claude-code-rtl/main/uninstall.ps1 | iex
```

---

<div dir="rtl">

## منو

نصبِ مک/لینوکس و روشِ دانلود، یک منوی تعاملی دارند. هر وقت خواستی با
`bash ~/.claude-code-rtl/scripts/menu.sh` بازش کن. _(نصبِ تک‌خطیِ ویندوز عمداً منو ندارد —
فقط دستورِ نصب/حذف را دوباره اجرا کن.)_

</div>

```
   ╭────────────────────────────╮
   │      Claude Code · RTL      │
   ╰────────────────────────────╯
   right-to-left  +  Vazir font

   [1] Apply now                 RTL + font  (auto-apply هم روشن می‌شود)
   [2] Change font               Vazir / system   (گزینه‌ی Back دارد)
   [3] Enable / Disable auto-apply
   [4] Reset to original         remove everything
   [0] Exit
```

---

<div dir="rtl">

## اعمالِ خودکار بعد از آپدیت

وقتی Claude Code آپدیت می‌شود، VSCode آن را در یک **پوشه‌ی جدید** نصب می‌کند و patch از بین می‌رود. نصبِ تک‌خطی **خودش این را روشن می‌کند** — یک هوکِ مخصوصِ هر سیستم‌عامل که در هر ورود، بی‌صدا دوباره اعمال می‌کند:

| سیستم‌عامل | محل |
|---|---|
| ویندوز | `Start Menu\Programs\Startup\ClaudeCodeRTL.vbs` |
| مک | `~/Library/LaunchAgents/com.claude-code-rtl.plist` |
| لینوکس | `~/.config/autostart/claude-code-rtl.desktop` |

هیچ‌کدام به دسترسیِ admin/root نیاز ندارند. بعد از آپدیت فقط یک‌بار **Reload Window** بزن.

</div>

---

<div dir="rtl">

## فونت‌ها و لایسنس

- فونتِ **Vazir** همراهِ ریپوست (`fonts/Vazir-Variable.ttf`) تحتِ **SIL Open Font License 1.1** — انتشارش آزاد است. تنها فونتِ همراه همین است.
- فونتِ دیگری می‌خواهی؟ فایلِ `.ttf` آن را داخلِ `fonts/` بگذار و در منو انتخابش کن. **فونتِ تجاری را روی ریپوی عمومی commit نکن** — `.gitignore` موارد رایج را از قبل بلاک کرده.

## چطور کار می‌کند

هیچ راهِ رسمی‌ای نیست که یک افزونه‌ی VSCode به webviewِ افزونه‌ی دیگر استایل بدهد — یک `<iframe>`ِ sandbox است. پس این ابزار، استایل‌شیتِ خودِ Claude Code را روی دیسک patch می‌کند:

```
~/.vscode/extensions/anthropic.claude-code-*/webview/index.css
```

یک بلوکِ CSSِ کوچک و علامت‌گذاری‌شده اضافه می‌شود (و فونت کنارش کپی می‌شود، چون CSPِ webview فقط فونتِ داخلِ پوشه‌ی افزونه را مجاز می‌داند). راست‌به‌چپ فقط روی **سطح‌های متنی** — پاسخ‌ها، پیام‌های خودت، کادرِ نوشتن و دیالوگ‌ها — با هوک‌های پایدار اعمال می‌شود، و کد/diff/Monaco به‌زور LTR می‌مانند تا چیزی خراب نشود.

## ساختارِ ریپو

</div>

```
install.sh / install.ps1      نصبِ تک‌خطی (curl … | bash  /  irm … | iex)
uninstall.sh / uninstall.ps1  حذفِ تک‌خطی
install-windows.cmd           دستی: دابل‌کلیک روی ویندوز (به Git نیاز دارد)
install-macos.command         دستی: دابل‌کلیک روی مک
scripts/
  menu.sh                     منوی تعاملی (رابط کاربری)
  apply.sh                    موتورِ bash: patch / --revert (auto-apply هم همین را صدا می‌زند)
  apply.ps1                   موتورِ PowerShell (ویندوزِ بدونِ Git)
fonts/Vazir-Variable.ttf
```

<div dir="rtl">

## لایسنس

- کدِ پروژه (اسکریپت‌ها و لانچرها): **MIT** — فایلِ [`LICENSE`](LICENSE).
- فونتِ همراه **Vazir**: **SIL Open Font License 1.1** — فایلِ [`fonts/LICENSE-Vazir.txt`](fonts/LICENSE-Vazir.txt).

</div>

<div align="center"><sub>وابسته به Anthropic نیست. فقط فایل‌های محلی را patch می‌کند؛ چیزی آپلود نمی‌شود.</sub></div>
