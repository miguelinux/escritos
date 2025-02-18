#!/usr/bin/env python3
# c-basic-offset: 4; tab-width: 8; indent-tabs-mode: nil
# vi: set shiftwidth=4 tabstop=8 expandtab:
# :indentSize=4:tabSize=8:noTabs=true:
#
# SPDX-License-Identifier: GPL-3.0-or-later
"""
Filtro para el menejo de usuarios de google
"""


def get_org_unit_path(archivo):
    """Optiene el valor de los Org Unit Path"""

    # Regresamos al inicio
    archivo.seek(0)
    # Leemos el encabezado
    archivo.readline()

    lista_org_path = set()

    for linea in archivo:
        lista = linea.split(",")
        # add "Org Unit Path [Required]"
        lista_org_path.add(lista[5])

    for org_path in lista_org_path:
        print(org_path)


def get_storage_sorted(archivo):
    """Obtiene los nombres y correos junto con su espacio ordenado
    de mayor a menor"""

    # Regresamos al inicio
    archivo.seek(0)
    # Leemos el encabezado
    archivo.readline()


def main(str_archivo):
    """
    Función principal
    """

    with open(str_archivo, mode="r", encoding="utf-8") as archivo:
        # get_org_unit_path(archivo)
        get_storage_sorted(archivo)


if __name__ == "__main__":
    import sys
    from os.path import exists

    if len(sys.argv) != 2:
        print("Error: falta nombre de archivo")
        sys.exit(1)

    if not exists(sys.argv[1]):
        print("Error: el archivo no existe")
        sys.exit(2)

    main(sys.argv[1])
