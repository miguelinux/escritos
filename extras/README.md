# Mappings for DMI/SMBIOS to Linux and dmidecode
Information can be put into dmi tables via some qemu-system hosts (x86_64 and aarch64).  That information is exposed in Linux under `/sys/class/dmi/id` and can be read with `dmidecode`.  The names are very annoyingly inconsistent.  The point of this doc is to map them.

## Mappings
Example qemu cmdline:

    qemu-system-x86_64 -smbios type=<type>,field=value[,...]
    
    qemu-system-x86_64 -smbios type=0,vendor=superco,version=1.2.3

| type | -smbios field   | Linux path        | dmidecode --string=F     |
| -----| -------------   | ----------------  | ----------------         |
| 0    | vendor          | bios_vendor       | bios-vendor              |
| 0    | date            | bios_date         | bios-release-date        |
| 0    | version         | bios_version      | bios-version             |
| 0    | release=(%d.%d) | n/a               | n/a                      |
| 0    | uefi=(on\|off)  | n/a               | n/a                      |
| 1    | manufacturer    | sys_vendor        | system-manufacturer      |
| 1    | product         | product_name      | system-product-name      |
| 1    | version         | product_version   | system-version           |
| 1    | serial          | product_serial    | system-serial-number     |
| 1    | uuid            | product_uuid      | system-uuid              |
| 1    | sku             | n/a               | n/a                      |
| 1    | family          | product_family    | n/a                      |
| 2    | manufacturer    | board_vendor      | baseboard-manufacturer   |
| 2    | product         | board_name        | baseboard-product-name   |
| 2    | version         | board_version     | baseboard-version        |
| 2    | serial          | board_serial      | baseboard-serial-number  |
| 2    | asset           | asset_tag         | baseboard-asset-tag      |
| 2    | location        | n/a               | n/a                      |
| 3    | manufacturer    | chassis_vendor    | chassis-manufacturer     |
| 3    | version         | chassis_version   | chassis-version          |
| 3    | serial          | chassis_serial    | chassis-serial-number    |
| 3    | asset           | chassis_asset_tag | chassis-asset-tag        |
| 3    | sku             | n/a               | n/a                      |
| 4    | sock_pfx        | n/a               | n/a                      |
| 4    | manufacturer    | n/a               | processor-manufacturer   |
| 4    | version         | n/a               | processor-version        |
| 4    | serial          | n/a               | n/a                      |
| 4    | asset           | n/a               | n/a                      |
| 4    | part            | n/a               | n/a                      |
| 11   | value           | n/a               | --oem-string=N           |
| 17   | loc_pfx         | n/a               | n/a                      |
| 17   | bank            | n/a               | n/a                      |
| 17   | manufacturer    | n/a               | n/a                      |
| 17   | serial          | n/a               | n/a                      |
| 17   | asset           | n/a               | n/a                      |
| 17   | part=(%d)       | n/a               | n/a                      |
| 17   | speed=(%d)      | n/a               | n/a                      |


## Notes
 * product_family not available in 4.4.0-28-generic kernel but 4.15 is.
 * More info on OEM string information linked from [Bug 1753558](https://bugs.launchpad.net/cloud-init/+bug/1753558)
 * linux exposes these files in `/sys/devices/virtual/dmi/id` and `/sys/class/dmi/id`

### values in /sys/class/dmi/id
 * cirros 0.4.0 (4.4.0-28-generic)

       bios_date:0date
       bios_vendor:0vendor
       bios_version:0version
       board_asset_tag:t2asset
       board_name:t2product
       board_serial:t2serial
       board_vendor:t2manufacturer
       board_version:t2version
       chassis_asset_tag:t3asset
       chassis_serial:t3serial
       chassis_type:1
       chassis_vendor:t3manufacturer
       chassis_version:t3version
       modalias:dmi:bvn0vendor:bvr0version:bd0date:svnt1manufacturer:pnt1product:pvrt1:
       power/control:auto
       power/async:disabled
       power/runtime_enabled:disabled
       power/runtime_active_kids:0
       power/runtime_active_time:0
       power/runtime_status:unsupported
       power/runtime_usage:0
       power/runtime_suspended_time:0
       product_name:t1product
       product_serial:t1serial
       product_uuid:11111111-1111-1111-1111-111111111111
       product_version:t1version
       sys_vendor:t1manufacturer
       uevent:MODALIAS=dmi:bvn0vendor:bvr0version:bd0date:svnt1manufacturer:pnt1produc:


 * 4.14.57

       bios_date:0date
       bios_vendor:0vendor
       bios_version:0version
       board_asset_tag:t2asset
       board_name:t2product
       board_serial:t2serial
       board_vendor:t2manufacturer
       board_version:t2version
       chassis_asset_tag:t3asset
       chassis_serial:t3serial
       chassis_type:1
       chassis_vendor:t3manufacturer
       chassis_version:t3version
       modalias:dmi:bvn0vendor:bvr0version:bd0date:svnt1manufacturer:pnt1product:pvrt1version:rvnt2manufacturer:rnt2product:rvrt2version:cvnt3manufacturer:ct1:cvrt3version:
       power/control:auto
       power/runtime_active_time:0
       power/runtime_status:unsupported
       power/runtime_suspended_time:0
       product_family:t1family
       product_name:t1product
       product_serial:t1serial
       product_uuid:11111111-1111-1111-1111-111111111111
       product_version:t1version
       sys_vendor:t1manufacturer
       uevent:MODALIAS=dmi:bvn0vendor:bvr0version:bd0date:svnt1manufacturer:pnt1product:pvrt1version:rvnt2manufacturer:rnt2product:rvrt2version:cvnt3manufacturer:ct1:cvrt3version:


