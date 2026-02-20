# Xray server in a tiny Docker image based on Alpine Linux.

### It uses [Xray-core](https://github.com/XTLS/Xray-core).

Supported protocols:
- VLESS Reality

Supported architectures:
- linux/arm64/v8
- linux/arm/v7
- linux/386
- linux/amd64

Verified clients:
- [ADKix/Xray-server](https://github.com/ADKix/Xray-server)
- [v2RayTun](https://v2raytun.com)
- [Amnezia VPN](https://amnezia.org)

------------
### Examples:
* [RouterOS](#routeros-example)
* [GNU/Linux](#linux-example)
------------

### RouterOS example:
##### (tested on MikroTik hAP ax³ with ROS 7.21.3 using internal storage with tmpfs in RAM)

Enable container mode (only once):
```
/system/package enable container
/system/package apply-changes
/system/device-mode update container=yes
```

Creating a container and a network interface for it, providing internet access:
```
/interface/veth add address=172.16.0.2/24 gateway=172.16.0.1 name=veth1
/ip/address add address=172.16.0.1/24 interface=veth1
/ip/firewall/nat add action=masquerade chain=srcnat out-interface=veth1
/container/config set registry-url=registry-1.docker.io
/container/envs add key=ADDRESS value="<public IP address of the host [optional, default gets from "ifconfig.me"]>" list=xray-server
/container/envs add key=PORT value="<port number on the host, 443 for example>" list=xray-server
/container/envs add key=SNI value="<SNI [optional, default "google.com"]>" list=xray-server
/container/mounts add src="xray-server_data" dst="/opt/data" list=xray-server
/container add remote-image=adkix/xray-server root-dir=xray-server/ mountlists=xray-server tmpfs=/tmp:64M:0777 interface=veth1 envlist=xray-server start-on-boot=yes
/container start 0
/ip/firewall/nat add chain=dstnat in-interface-list=WAN protocol=tcp dst-port=([/container/envs get [find list=xray-server key=PORT ] value]) action=dst-nat to-addresses=172.16.0.2 to-ports=443 comment="xray-server"
```

View generated credentials and logs:
```
/container/log print where container="xray-server"
```

### Linux example:
##### (using docker-compose)

Create a ".env" file with the following contents \[optional]:
```
ADDRESS=<public IP address of the host [optional, default gets from "ifconfig.me"]>
PORT=<port number on the host [optional, default "443"]>
SNI=<SNI [optional, default "google.com"]>
```

Create a "docker-compose.yml" file with the following contents:
```
services:
  server:
    image: "adkix/xray-server"
    env_file: ".env"  # if it was created
    ports:
      - "${PORT:-443}:443"
    volumes:
      - "./data:/opt/data"
    restart: unless-stopped
```

Creating a container and a network interface for it:
```
docker-compose up -d
```

View generated credentials, QR code and logs:
```
docker-compose logs
```
