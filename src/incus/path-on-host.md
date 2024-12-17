# Path on host

How to share local path to the container

```
incus config device add <instance_name> <device_name> disk source=<path_on_host> [path=<path_in_instance>] shift=true
```


