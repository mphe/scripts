#!/usr/bin/env bash
python -m cProfile -s time -o out.profile "$@"
