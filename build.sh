#!/bin/bash
set -x
PEGGED_PATH=pegged/pegged
PEGGED_FILES="-Ipegged ${PEGGED_PATH}/*.d ${PEGGED_PATH}/examples/dgrammar.d ${PEGGED_PATH}/examples/c.d ${PEGGED_PATH}/development/grammarfunctions.d 
${PEGGED_PATH}/utils/*.d"
dmd gen_parser.d ${PEGGED_FILES} -g -debug
./gen_parser
dmd main.d generated/*.d ${PEGGED_FILES} -g -debug -inline
