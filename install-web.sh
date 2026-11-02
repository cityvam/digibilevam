#!/usr/bin/env bash
# نصب فرانت Next.js روی Ubuntu (با sudo). سرویس ASP.NET را تغییر نمی‌دهد.
# دو حالت: (۱) ساخت روی سرور (نیازمند دسترسی به registry ی npm)  (۲) اگر پوشه‌ی .next/standalone از قبل (روی ماشین دیگر) ساخته و کنار این اسکریپت کپی شده باشد، همان نصب می‌شود.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "با sudo اجرا کنید"; exit 1; }
command -v node >/dev/null || { echo "Node.js ≥ 20.9 لازم است (NodeSource یا nvm)"; exit 1; }
node -e 'const [a,b]=process.versions.node.split(".").map(Number);process.exit(a>20||(a===20&&b>=9)?0:1)' || { echo "Node قدیمی است (≥ 20.9 لازم)"; exit 1; }
SRC="$(cd "$(dirname "$0")" && pwd)"; DEST=/opt/digitalpay-web; BUILD=/opt/digitalpay-web-build
id dpweb >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin dpweb
mkdir -p "$DEST" /etc/digitalpay

if [ -f "$SRC/.next/standalone/server.js" ]; then
  echo "▸ بسته‌ی از پیش ساخته‌شده پیدا شد؛ بدون npm نصب می‌شود"; BUILD="$SRC"
else
  echo "▸ ساخت روی سرور (npm install + next build) — چند دقیقه طول می‌کشد"
  mkdir -p "$BUILD"; rsync -a --delete --exclude node_modules --exclude .next --exclude tools/.build --exclude mock --exclude test "$SRC/" "$BUILD/"
  cd "$BUILD"; export NEXT_TELEMETRY_DISABLED=1
  npm install --no-audit --no-fund
  npm run build
fi
rsync -a --delete "$BUILD/.next/standalone/" "$DEST/"
mkdir -p "$DEST/.next/static" "$DEST/.next/cache"; rsync -a --delete "$BUILD/.next/static/" "$DEST/.next/static/"
[ -d "$BUILD/public" ] && rsync -a --delete "$BUILD/public/" "$DEST/public/"
chown -R root:root "$DEST"; chown -R dpweb:dpweb "$DEST/.next/cache"

if [ ! -f /etc/digitalpay/web.env ]; then
  cp "$SRC/.env.sample" /etc/digitalpay/web.env; chown root:dpweb /etc/digitalpay/web.env; chmod 640 /etc/digitalpay/web.env
  echo "ساخته شد: /etc/digitalpay/web.env — API_HOST_HEADER و SITE_ORIGINS را با دامنه‌ی خودتان بررسی کنید"
fi
cp "$SRC/digitalpay-web.service" /etc/systemd/system/ && systemctl daemon-reload && systemctl enable digitalpay-web && systemctl restart digitalpay-web
for i in 1 2 3 4 5 6 7 8; do sleep 1; curl -fsS http://127.0.0.1:3000/healthz >/dev/null 2>&1 && { echo "✔ سرویس بالا است"; break; }; [ "$i" = 8 ] && { echo "✘ بالا نیامد: journalctl -u digitalpay-web -n 50"; exit 1; }; done
echo "بعد: nginx را طبق nginx.snippet تنظیم کنید و nginx -t && systemctl reload nginx"
