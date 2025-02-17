#!/usr/bin/env python3
# c-basic-offset: 4; tab-width: 8; indent-tabs-mode: nil
# vi: set shiftwidth=4 tabstop=8 expandtab:
# :indentSize=4:tabSize=8:noTabs=true:
#
# SPDX-License-Identifier: GPL-3.0-or-later
"""
Filtro para el menejo de usuarios de google
"""


def main():
    """
    Comentario de la función
    """
    print("Hola Mundo")


if __name__ == "__main__":
    import sys
    from os.path import exists

    if len(sys.argv) != 2:
        print("Error: falta nombre de archivo")
        sys.exit(1)

    if not exists(sys.argv[1]):
        print("Error: el archivo no existe")
        sys.exit(2)

    main()
