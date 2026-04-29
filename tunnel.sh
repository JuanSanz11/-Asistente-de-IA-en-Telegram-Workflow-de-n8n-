#!/bin/bash

# Configuración
PORT=5678
PID_FILE=".ngrok.pid"

function start() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "⚠️  Ngrok ya está en ejecución (PID: $(cat $PID_FILE))"
        get_url
        return
    fi

    echo "🚀 Iniciando túnel ngrok en el puerto $PORT..."
    # Ejecutamos ngrok en segundo plano
    npx ngrok http $PORT --log=stdout > /dev/null 2>&1 &
    echo $! > "$PID_FILE"

    # Esperamos a que se establezca la conexión
    echo "⏳ Esperando conexión..."
    sleep 5

    get_url
}

function stop() {
    echo "🛑 Deteniendo ngrok..."
    # 1. Intentar por PID
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        kill $PID 2>/dev/null
        rm "$PID_FILE"
    fi
    # 2. Asegurar matando cualquier proceso remanente
    pkill -9 -f "ngrok" 2>/dev/null
    echo "✅ Todo proceso de ngrok ha sido detenido."
}

function get_url() {
    # Reintento para dar tiempo a ngrok a conectar
    for i in {1..5}; do
        URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
        if [ "$URL" != "null" ] && [ -n "$URL" ]; then
            echo "🔗 URL Pública: $URL"
            echo "📌 Usa esta URL en n8n como WEBHOOK_URL"
            return
        fi
        sleep 2
    done
    echo "❌ No se pudo obtener la URL tras varios intentos. Revisa './tunnel.sh status'"
}

function status() {
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "✅ Ngrok está activo."
        get_url
    else
        echo "❌ Ngrok está apagado."
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    *)
        echo "Uso: ./tunnel.sh {start|stop|status}"
        exit 1
        ;;
esac
