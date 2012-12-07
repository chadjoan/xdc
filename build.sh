#!/bin/bash
set -x -e
PEGGED_PATH=pegged/pegged
PEGGED_FILES="
 -Ipegged
 -L-Lpegged
 -L-lpegged
 ${PEGGED_PATH}/examples/c.d
 ${PEGGED_PATH}/examples/dgrammar.d
"
#PEGGED_FILES="
# -Ipegged
# ${PEGGED_PATH}/examples/c.d
# ${PEGGED_PATH}/examples/dgrammar.d
# ${PEGGED_PATH}/examples/arithmetic.d
# ${PEGGED_PATH}/*.d
#"
mkdir -p obj
dmd src/gen_parser.d ${PEGGED_FILES} src/grammars/pmlgrammar.d -g -debug -of./bin/gen_parser -odobj
rm obj/*
./bin/gen_parser
dmd testing/scratch.d src/misc.d src/generated/*.d -Isrc ${PEGGED_FILES} -g -debug -inline -of./bin/scratch -odobj -unittest
dmd src/*.d src/rules/*.d src/generated/*.d -Isrc ${PEGGED_FILES} -g -debug -inline -of./bin/xdc -unittest
rm obj/*
