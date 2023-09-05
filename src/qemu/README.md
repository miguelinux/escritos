# Useful commands

## Create image

Create an image with 
```
qemu-img create -f qcow2 -o lazy_refcounts=on,preallocation=metadata image.qcow2 20G
```
> lazy_refcounts
>    - If this option is set to on, reference count updates are postponed
>      with the goal of avoiding metadata I/O and improving performance. This
>      is particularly interesting with cache=writethrough which doesn't batch
>      metadata updates. The tradeoff is that after a  host  crash,  the
>      reference count tables must be rebuilt, i.e. on the next open an
>      (automatic) qemu-img check -r all is required, which may take some time.

Create a raw image with 

```
qemu-img create -f raw  image.qcow2 20G
```
