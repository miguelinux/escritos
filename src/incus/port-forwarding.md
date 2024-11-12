# Configure listen external port to be forwarede to internal port

Creación de la redirección de puerto
```
incus config device add apache puerto-80 proxy listen=tcp:0.0.0.0:8080 connect=tcp:127.0.0.1:80
```

Listar puertos
```
incus config device list
```
