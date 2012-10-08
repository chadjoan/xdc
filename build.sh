#!/bin/bash
set -x -e
PEGGED_PATH=pegged/pegged
PEGGED_FILES="
 -Ipegged
 ${PEGGED_PATH}/examples/c.d
 ${PEGGED_PATH}/*.d
"
mkdir -p obj
dmd gen_parser.d ${PEGGED_FILES} grammars/pmlgrammar.d -g -debug -of./bin/gen_parser -odobj
rm obj/*
./bin/gen_parser
dmd main.d generated/*.d ${PEGGED_FILES} -g -debug -inline -of./bin/xdc -odobj
rm obj/*
