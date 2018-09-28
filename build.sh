#!/bin/bash
set -x -e
#PEGGED_PATH=pegged/pegged
#PEGGED_FILES="
# -Ipegged
# -L-Lpegged
# -L-lpegged
# ${PEGGED_PATH}/examples/c.d
# ${PEGGED_PATH}/examples/dgrammar.d
#"
#
#ALL_FILES="${PEGGED_FILES} src/xdc/parser_builder/*.d src/xdc/common/*.d src/xdc/rules/*.d -Isrc"
ALL_FILES="src/xdc/parser_builder/*.d src/xdc/common/*.d -Isrc"
DFLAGS="-g -debug -odobj -unittest"

mkdir -p obj
#
#dmd src/xdc/gen_parsers/*.d ${ALL_FILES} ${DFLAGS} -of./bin/gen_parsers
#./bin/gen_parsers
#rm obj/*
#
#dmd src/xdc/gen_pipelines/*.d src/xdc/generated/parsers.d ${ALL_FILES} ${DFLAGS} -of./bin/gen_pipelines
#./bin/gen_pipelines
#rm obj/*
#
#dmd src/xdc/compiler/*.d src/xdc/generated/parsers.d src/xdc/generated/pipelines.d ${ALL_FILES} ${DFLAGS} -of./bin/xdc
#rm obj/*

#dmd testing/scratch.d src/misc.d src/generated/*.d -Isrc ${PEGGED_FILES} -g -debug -inline -of./bin/scratch -odobj -unittest
dmd $ALL_FILES -g -debug -inline -of./bin/scratch -odobj -unittest
