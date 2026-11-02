# digitalpay-web (Next.js 15 · App Router)
فرانت‌اند دیجی‌بایل پی روی API ی ASP.NET Core. Server Components + Server Actions (فرم‌ها بدون JS هم کار می‌کنند)، توکن JWT فقط در کوکی HttpOnly (`dp_t`)، CSP با nonce، فقط یک کامپوننت کلاینتی (جداکننده‌ی هزارگان).

## اجرا
- توسعه: `npm i` ← `npm run mock` (ترمینال ۱) ← `API_URL=http://127.0.0.1:5290 npm run dev` (ترمینال ۲) → http://127.0.0.1:3000
  (مشتری: هر نام کاربری با رمز دلخواه؛ مدیر: نام کاربری که به 0000 ختم شود، کد دومرحله‌ای 123456)
- تولید: `npm run build && npm start`، یا روی سرور: `sudo bash install-web.sh` (standalone + systemd) و nginx.snippet

## آزمون (بدون نیاز به نصب Next)
`npm test` — کد واقعی صفحه‌ها/اکشن‌ها/روت‌ها با esbuild + شیم‌های `next/*` روی mock API اجرا می‌شود (۱۶ آزمون).
`npm run preview` — همه‌ی صفحه‌ها به HTML ایستا (preview-out/).
**محدودیت صادقانه:** `next build` و `tsc` در محیط ساخت این بسته اجرا نشده (Next/@types نصب‌شدنی نبود). اولین کار روی سرور/لپ‌تاپ شما: `npm i && npm run build`؛ خطای تایپ احتمالی کوچک است و در همان لحظه دیده می‌شود.

## ساختار
- `middleware.ts` — CSP+nonce، نگهبان /app و /admin، پاک‌کردن پیام یک‌بارمصرف
- `src/lib` — api.ts (fetch با Bearer/X-Real-IP/Host)، session.ts (نشست، flash، حالت چندمرحله‌ای)، format.ts، calc.ts (آینه‌ی ContractEngine)
- `src/actions/*` — Server Action ها (همه با `requireUser` و فهرست مجاز عملیات)
- `src/app/(site)` عمومی، `src/app/app` مشتری، `src/app/admin` مدیریت، `src/app/files/*` روت‌های فایل (قرارداد در iframe سندباکس، تصویر مدرک، نمونه‌ی قالب)
- قرارداد API: `mock/mock-api.mjs`

## امنیت (خلاصه)
Origin check ی Server Actions + `allowedOrigins`؛ ضدکلیک‌جکینگ؛ هیچ مسیر API از ورودی کاربر ساخته نمی‌شود؛ مقدارهای حساس (کلید ۲FA، کد بازیابی، CVV) فقط در کوکی ۶۰ثانیه‌ای HttpOnly و هرگز در URL؛ محدودیت نرخ در nginx.

## بررسی تایپ سبک (بدون @types)
`tools/typecheck-stubs.d.ts` نوع‌های ساده‌ی react/next را می‌دهد تا `tsc` بتواند import/export و نام‌های ناشناخته‌ی خود پروژه را بدون نصب بسته‌ها بررسی کند (همین بررسی روی همه‌ی src/ بدون خطا گذشت). جایگزین `npm run build` نیست.

## اعتبارسنجی (اعتبارسنجی ایران — MyCreditAPIs v3.2)
- بک‌اند: `backend/credit` (کلاینت، جریان رمز یکبارمصرف، کال‌بک، صف پرسش وضعیت، ریزلاگ). تنظیمات محرمانه‌ی سرور: `MyCredit:BaseUrl/Username/Password/ApiKey/CallbackSecret`؛ IP سرور باید نزد شرکت ثبت شود و آدرس کال‌بک `/api/v1/credit/callback/<راز>` به آن‌ها داده شود.
- مشتری: `/app/credit` (فرم + رضایت‌نامه)، `/app/credit/[id]` (رمز، ارسال مجدد، وضعیت، گزارش، PDF).
- مدیر: `/admin/credit` (سلامت اتصال، فهرست، استعلام برای مشتری، تنظیمات)، `/admin/credit/[id]` (ردپا و عملیات)، `/admin/credit/[id]/report`، `/admin/credit/records` (ریزلاگ بخش ۱۱).
- ساختار JSON گزارش در پیوست مستند نیامده؛ نمایش گزارش عمومی است (`ReportTree`) تا نمونه‌ی واقعی را ببینیم.
