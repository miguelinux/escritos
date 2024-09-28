# Agregar nuevo paquete en Debian

* git clone origin
* git branch -m main upstream/latest
* git checkout -b debian/latest vX.Y
* dh_make --packagename name_version --copyright expat -l --createorig
  - expat es MIT

## Usando debmake

* debmake -c
  - scan source for copyright+license text and exit.

* debmake -d -i debuild
* debmake -t -i debuild

  -a
  -p -u -z

* debmake --package intel-qpl \
          --upstreamversion 1.6.0 \
          --revision 1 \
          --targz tar.gz \
          --monoarch \
          --binaryspec ""





