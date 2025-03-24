# Configure listen external port to be forwarede to internal port

Creación de la redirección de puerto

incus config device add [<remote>:]<instance> <device> <type> [key=value...] [flags]

```
incus config device add apache puerto-80 proxy listen=tcp:0.0.0.0:8080 connect=tcp:127.0.0.1:80

incus config device add <instance> <device> \
   proxy \
   listen=tcp:127.0.0.1:8080 \
   connect=tcp:127.0.0.1:4943
```

Listar puertos
```
incus config device list
```
