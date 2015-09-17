#!/usr/bin/python

import sys
import os

def createHeader(guard, namespace):
    return "#ifndef {}_HPP\n#define {}_HPP\n\n{}\n\n#endif".format(guard, guard, namespace)
    
def createSource(name, namespace):
    return '#include "{}.hpp"\n\n{}'.format(name, namespace)

def createNamespace(namespace):
    return "namespace {}\n{{\n\n}}".format(namespace)

if len(sys.argv) > 1:
    path, name = os.path.split(sys.argv[1])
    if not name:
        print("No name specified")
        sys.exit(1)
    if path:
        path += "/"

    namespace = createNamespace(sys.argv[2]) if len(sys.argv) > 2 else ""
    guard = name.replace(" ", "_").upper()
    name = name.replace(" ", "") # Remove spaces for filename
    path += name

    with open(path + ".hpp", "w") as f:
        f.write(createHeader(guard, namespace))
    
    with open(path + ".cpp", "w") as f:
        f.write(createSource(name, namespace))

else:
    print("Create a C++ header and source file.")
    print("Usage:\n\t{} <fname> [namespace]".format(sys.argv[0]))
    print("\n<fname>\t\tThe name of the file. Spaces will be removed. Include guards will have the same name but spaces replaced with underscores (_).")
    print("[namespace]\tA namespace (what a surprise).")
