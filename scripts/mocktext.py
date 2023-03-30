#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys

if len(sys.argv) > 1:
    s = list(" ".join(sys.argv[1:]))
    for i in range(0, len(s), 2):
        s[i] = s[i].upper()
    print("".join(s))
