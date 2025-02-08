#!/bin/bash

CONFIG_FILE="bot.json"

# Cek apakah file konfigurasi sudah ada
if [[ -f "$CONFIG_FILE" ]]; then
    # Baca data dari bot.json
    api_domain=$(jq -r '.api_domain' "$CONFIG_FILE")
    API_KEY=$(jq -r '.API_KEY' "$CONFIG_FILE")

    echo "📂 Config loaded from $CONFIG_FILE"
else
    # Jika file tidak ada, minta input dan simpan ke file
    read -p "Enter your domain without https:// (default: official.gaia.domains): " api_domain
    api_domain=${api_domain:-official.gaia.domains}

    read -p "Enter your GAIA API key: " API_KEY

    # Simpan ke bot.json
    echo "{
    \"api_domain\": \"$api_domain\",
    \"API_KEY\": \"$API_KEY\"
    }" > "$CONFIG_FILE"

    echo "✅ Config saved to $CONFIG_FILE"
fi

# API URL
API_URL="https://${api_domain}/v1/chat/completions"

# File yang berisi daftar pertanyaan
QUESTION_FILE="chat.txt"

# Periksa apakah file pertanyaan ada
if [[ ! -f "$QUESTION_FILE" ]]; then
    echo "❌ Error: $QUESTION_FILE not found!"
    exit 1
fi

echo "🚀 Starting Gaia Chatbot... Press CTRL+C to stop."

# Loop tak terbatas
while true; do
    # Pilih pertanyaan secara acak
    USER_QUESTION=$(shuf -n 1 "$QUESTION_FILE")

    echo -e "\n[🤖] Asking: $USER_QUESTION"

    # Kirim pertanyaan ke API
    RESPONSE=$(curl -s -X POST "$API_URL" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -d '{
            "messages": [
                {"role": "system", "content": "You are a helpful AI assistant."},
                {"role": "user", "content": "'"$USER_QUESTION"'"}
            ]
        }')

    # Ambil jawaban AI dari JSON
    AI_RESPONSE=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null)

    # Cek apakah jawaban valid
    if [[ -z "$AI_RESPONSE" || "$AI_RESPONSE" == "null" ]]; then
        echo "[⚠️] No response from AI, retrying..."
    else
        echo -e "[💬] Answer:\n$AI_RESPONSE"
    fi

    # Tunggu sebelum bertanya lagi
    sleep 3
done
