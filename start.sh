#!/bin/bash
set -e

echo "🚀 Starting X-UI + nginx reverse proxy..."

# ===== متغیرها (با مقادیر پیش‌فرض) =====
export NGINX_PORT=${PORT:-3000}
export PANEL_PATH=${PANEL_PATH:-/managepanel/}
export PANEL_PORT=${PANEL_PORT:-2053}
export SUB_PATH=${SUB_PATH:-/sub/}
export SUB_PORT=${SUB_PORT:-2096}
export INBOUND_PORT=${INBOUND_PORT:-8080}
export INBOUND_PORT_1=${INBOUND_PORT_1:-8081}
export INBOUND_PORT_2=${INBOUND_PORT_2:-8082}
export INBOUND_PORT_3=${INBOUND_PORT_3:-8083}
export INBOUND_PORT_4=${INBOUND_PORT_4:-8084}
export INBOUND_PORT_5=${INBOUND_PORT_5:-8085}
export INBOUND_PORT_6=${INBOUND_PORT_6:-8086}
export INBOUND_PORT_7=${INBOUND_PORT_7:-8087}
export INBOUND_PORT_8=${INBOUND_PORT_8:-8088}
export INBOUND_PORT_9=${INBOUND_PORT_9:-8089}

echo "🔧 Config:"
echo "   NGINX_PORT    = $NGINX_PORT"
echo "   PANEL_PATH    = $PANEL_PATH"
echo "   PANEL_PORT    = $PANEL_PORT"
echo "   SUB_PATH      = $SUB_PATH"
echo "   SUB_PORT      = $SUB_PORT"
echo "   INBOUND_PORT  = $INBOUND_PORT"

cd /usr/local/x-ui

# ===== تنظیمات پنل =====
echo "🔧 Applying panel settings..."
./x-ui setting -port "$PANEL_PORT" -webBasePath "$PANEL_PATH" || true

# ===== تنظیمات ساب در دیتابیس =====
echo "🔧 Applying sub settings..."
sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subPath', '$SUB_PATH');" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subPort', '$SUB_PORT');" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subEnable', 'true');" 2>/dev/null || true
sqlite3 /etc/x-ui/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subEnableRouting', 'false');" 2>/dev/null || true

# ===== ساخت کانفیگ Nginx =====
echo "🔧 Building nginx.conf..."
envsubst '${NGINX_PORT} ${PANEL_PATH} ${PANEL_PORT} ${SUB_PATH} ${SUB_PORT} ${INBOUND_PORT} ${INBOUND_PORT_1} ${INBOUND_PORT_2} ${INBOUND_PORT_3} ${INBOUND_PORT_4} ${INBOUND_PORT_5} ${INBOUND_PORT_6} ${INBOUND_PORT_7} ${INBOUND_PORT_8} ${INBOUND_PORT_9}' \
    < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# ===== اجرای x-ui در پس‌زمینه =====
echo "▶️  Starting x-ui in background..."
./x-ui &
X_UI_PID=$!

sleep 3

# ===== اجرای Nginx در foreground =====
echo "▶️  Starting nginx on port $NGINX_PORT..."
nginx -t
exec nginx -g "daemon off;"