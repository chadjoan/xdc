#!/bin/bash
set -x
PEGGED_PATH=pegged/pegged
PEGGED_FILES="
 -Ipegged
 ${PEGGED_PATH}/peg.d
 ${PEGGED_PATH}/grammar.d
 ${PEGGED_PATH}/examples/dgrammar.d
 ${PEGGED_PATH}/examples/c.d
 ${PEGGED_PATH}/development/grammarfunctions.d
 ${PEGGED_PATH}/utils/*.d
"
mkdir obj
dmd gen_parser.d ${PEGGED_FILES} grammars/pmlgrammar.d -g -debug -of./bin/gen_parser -odobj
rm obj/*
./bin/gen_parser
dmd main.d generated/*.d ${PEGGED_FILES} -g -debug -inline -of./bin/ladc -odobj
rm obj/*
