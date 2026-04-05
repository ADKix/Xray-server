#!/bin/sh
set -e
if [ -z "$(ls -A "data" 2>/dev/null)" ]; then
  xray uuid >"data/uuid"
  xray x25519 >"data/keys"
fi
ID="$(cat "data/uuid")"
PRIVATE_KEY="$(awk '/PrivateKey/{print $2}' "data/keys")"
PUBLIC_KEY="$(awk '/Password/{print $2}' "data/keys")"
ADDRESS="${ADDRESS:-$(wget -q "ifconfig.me/ip" -O-)}"

if [ -z "${ADDRESS}" ]; then echo "The ADDRESS environment variable must be set!" >&2; exit 1; fi
if [ "${NETWORK}" = "xhttp" ]; then
  echo "vless://${ID}@${ADDRESS}:${PORT}?type=xhttp&security=reality&pbk=${PUBLIC_KEY}&sni=${SNI}&fp=chrome#${ADDRESS}" | qrencode -t ansiutf8
  cat >"/etc/xray.json" <<-EOF
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
								"id": "${ID}"
							}
						],
						"decryption": "none"
					},
					"streamSettings": {
						"network": "xhttp",
						"security": "reality",
						"realitySettings": {
							"dest": "${SNI}:443",
							"serverNames": [
								"${SNI}"
							],
						"privateKey": "${PRIVATE_KEY}",
						"shortIds": [
							""
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
elif [ "${NETWORK}" = "tcp" ]; then
  echo "vless://${ID}@${ADDRESS}:${PORT}?type=tcp&flow=xtls-rprx-vision&security=reality&pbk=${PUBLIC_KEY}&sni=${SNI}&fp=chrome#${ADDRESS}" | qrencode -t ansiutf8
  cat >"/etc/xray.json" <<-EOF
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
							"dest": "${SNI}:443",
							"serverNames": [
								"${SNI}"
							],
						"privateKey": "${PRIVATE_KEY}",
						"shortIds": [
							""
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
else
  echo 'The NETWORK environment variable must be set to "tcp" or "xhttp"!' >&2
  exit 1
fi

{
  echo
  echo "Address: ${ADDRESS}"
  echo "Port: ${PORT}"
  echo "Network: ${NETWORK:-tcp}"
  echo "ID: ${ID}"
  echo "PublicKey: ${PUBLIC_KEY}"
  echo "SNI: ${SNI}"
  echo
} | column -L -t

exec xray run -config "/etc/xray.json"