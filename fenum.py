#!/bin/env python

import os
import sys
import math

def main():
    if len(sys.argv) == 1 or sys.argv[1].lower() == "-h" or sys.argv[1].lower() == "--help":
        print("Syntax: fenum.py [files...]")
        print("\tEnumerate the given files (starting at 1) in the same order as they are passed to the script.")
        return

    for k,v in enumerate(sys.argv[1:], 1):
        path, name = os.path.split(v if not v.endswith("/") else v[:-1])
        if path:
            path += "/"
        try:
            fname = "{}{} - {}".format(
                    path,
                    str(k).zfill(int(math.log10(len(sys.argv) - 1)) + 1),
                    name)
            print("\"{}\" -> \"{}\"".format(v, fname))
            os.rename(v, fname)
        except Exception as e:
            print(str(e))

main()
