# Configure listen external port to be forwarede to internal port

Creación de la redirección de puerto

incus config device add [<remote>:]<instance> <device> <type> [key=value...] [flags]

```
incus config device add apache puerto-80 proxy listen=tcp:0.0.0.0:8080 connect=tcp:127.0.0.1:80

incus config device add el-contenedor nuevo-nombre proxy listen=tcp:X.Y.Z.W:8080 connect=tcp:0.0.0.0:80 nat=true

incus config device add <instance> <device> \
   proxy \
   listen=tcp:127.0.0.1:8080 \
   connect=tcp:127.0.0.1:4943
```

## How to Fix

1. Assign a Static IPv4 via LXD (Recommended) 
This tells the internal LXD DHCP server (dnsmasq) to always reserve
a specific IP for that instance's MAC address. 

```bash
lxc config device set <instance_name> eth0 ipv4.address <desired_ip>
```
o este comando

```bash
lxc config device override <instance> <device> ipv4.address=...

lxc config device override laravel-dt eth0 ipv4.address=10.21.41.14
```

Note: The IP must be within the subnet of the bridge (e.g., lxdbr0) and outside the dynamic DHCP pool to avoid conflicts. 

## Listar puertos
```
incus config device list
```
