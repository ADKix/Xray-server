#!/bin/sh
set -e
if [ -z "$(ls -A "data" 2>/dev/null)" ]; then
  xray uuid >"data/uuid"
  xray x25519 >"data/keys"
  openssl rand -hex 8 >"data/sid"
fi
ID="$(cat "data/uuid")"
PRIVATE_KEY="$(awk '/PrivateKey/{print $2}' "data/keys")"
PUBLIC_KEY="$(awk '/Password/{print $2}' "data/keys")"
SHORT_ID="$(cat "data/sid")"
ADDRESS="${ADDRESS:-"$(wget -q "ifconfig.me/ip" -O-)"}"
if [ -z "${ADDRESS}" ]; then echo "The ADDRESS environment variable must be set!" >&2; exit 1; fi
{
  echo "Address: ${ADDRESS}"
  echo "Port: ${PORT}"
  echo "ID: ${ID}"
  echo "PublicKey: ${PUBLIC_KEY}"
  echo "ShortID: ${SHORT_ID}"
  echo "SNI: ${SNI}"
} | column -t
echo "vless://${ID}@${ADDRESS}:${PORT}?security=reality&pbk=${PUBLIC_KEY}&fp=chrome&type=tcp&flow=xtls-rprx-vision&sni=${SNI}&sid=${SHORT_ID}#${ADDRESS}" | qrencode -t ansiutf8
cat >"/etc/xray.json" <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "flow": "xtls-rprx-vision",
            "id": "${ID}"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "www.samsung.com:443",
          "serverNames": [
            "${SNI}"
          ],
        "privateKey": "${PRIVATE_KEY}",
        "shortIds": [
          "${SHORT_ID}"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF
exec xray run -config "/etc/xray.json"