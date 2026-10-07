#!/bin/bash
set -e

echo "🚀 Starting X-UI + nginx reverse proxy..."

# ==================== متغیرها ====================
# Nginx همیشه روی PORT که Railway می‌ده گوش می‌ده
export NGINX_PORT=${PORT:-3000}

# مسیر و پورت پنل x-ui
export PANEL_PATH=${PANEL_PATH:-/managepanel/}
export PANEL_PORT=${PANEL_PORT:-2053}

# مسیر و پورت ساب
export SUB_PATH=${SUB_PATH:-/sub/}
export SUB_PORT=${SUB_PORT:-2096}

# پورت اینباند اصلی
export INBOUND_PORT=${INBOUND_PORT:-9000}

# پورت‌های اینباندهای اضافی
export INBOUND_PORT_1=${INBOUND_PORT_1:-9001}
export INBOUND_PORT_2=${INBOUND_PORT_2:-9002}
export INBOUND_PORT_3=${INBOUND_PORT_3:-9003}
export INBOUND_PORT_4=${INBOUND_PORT_4:-9004}
export INBOUND_PORT_5=${INBOUND_PORT_5:-9005}
export INBOUND_PORT_6=${INBOUND_PORT_6:-9006}
export INBOUND_PORT_7=${INBOUND_PORT_7:-9007}
export INBOUND_PORT_8=${INBOUND_PORT_8:-9008}
export INBOUND_PORT_9=${INBOUND_PORT_9:-9009}

# مسیر گواهی SSL (اختیاری - اگر فایل نباشه x-ui با HTTP بالا میاد)
export CERT_FILE=${CERT_FILE:-/etc/ssl/cloudflare/electrohafezco.ir.pem}
export KEY_FILE=${KEY_FILE:-/etc/ssl/cloudflare/electrohafezco.ir.key}

echo "==========================================="
echo "🔧 Configuration:"
echo "   NGINX_PORT    = $NGINX_PORT"
echo "   PANEL_PATH    = $PANEL_PATH"
echo "   PANEL_PORT    = $PANEL_PORT"
echo "   SUB_PATH      = $SUB_PATH"
echo "   SUB_PORT      = $SUB_PORT"
echo "   INBOUND_PORT  = $INBOUND_PORT"
echo "   INBOUND 1-9   = $INBOUND_PORT_1..$INBOUND_PORT_9"
echo "   CERT_FILE     = $CERT_FILE"
echo "==========================================="

cd /usr/local/x-ui

# ==================== تنظیمات x-ui ====================
echo "🔧 Applying panel settings..."
./x-ui setting -port "$PANEL_PORT" -webBasePath "$PANEL_PATH" || true

# ==================== تنظیمات دیتابیس ====================
echo "🔧 Applying database settings..."
sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subPath', '$SUB_PATH');" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subPort', '$SUB_PORT');" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subEnable', 'true');" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subEnableRouting', 'false');" 2>/dev/null || true

# اگر فایل گواهی وجود داشت، تنظیمات HTTPS اعمال شود
if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
    echo "🔒 SSL certificate found, enabling HTTPS..."
    sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('webCertFile', '$CERT_FILE');" 2>/dev/null || true
    sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('webKeyFile', '$KEY_FILE');" 2>/dev/null || true
    sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subCertFile', '$CERT_FILE');" 2>/dev/null || true
    sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subKeyFile', '$KEY_FILE');" 2>/dev/null || true
else
    echo "⚠️  SSL certificate not found, using HTTP for x-ui..."
    sqlite3 /etc/x-ui/x-ui.db "DELETE FROM settings WHERE key IN ('webCertFile','webKeyFile','subCertFile','subKeyFile');" 2>/dev/null || true
fi

# ==================== ساخت nginx.conf ====================
echo "🔧 Building nginx.conf..."
envsubst '${NGINX_PORT} ${PANEL_PATH} ${PANEL_PORT} ${SUB_PATH} ${SUB_PORT} ${INBOUND_PORT} ${INBOUND_PORT_1} ${INBOUND_PORT_2} ${INBOUND_PORT_3} ${INBOUND_PORT_4} ${INBOUND_PORT_5} ${INBOUND_PORT_6} ${INBOUND_PORT_7} ${INBOUND_PORT_8} ${INBOUND_PORT_9}' \
    < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# ==================== اجرا ====================
echo "▶️  Starting x-ui in background..."
./x-ui &
X_UI_PID=$!

sleep 3

echo "▶️  Starting nginx on port $NGINX_PORT..."
nginx -t
exec nginx -g "daemon off;"