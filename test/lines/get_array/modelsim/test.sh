#!/bin/bash

RED='\033[0;31m'
GREEN='\e[32m'
NC='\033[0;0m'

base=$PWD/../../../../
test_name=./$(dirname ${PWD#$(realpath $base)/})

ant unit_test_general.build > build.log 2>&1

# run simulation
vsim -t ps -L work tb_top -batch -do run.do > out.log 2> error.log
return_value=$?
set -e

error=$(cat error.log)
error_not_contain="error"

out=$(cat out.log)
out_expected=$(cat <<EOF
# include found: loading file ./../Array.stm
# 00000000 00000001 0000000A 00000002 0000000B 7FFFFFFF 80000000 FFFFFFFF 
# 00000000 00000001 0000000A 00000002 0000000B 7FFFFFFF 80000000 FFFFFFFF 
# 00000001 00000001 0000000A 00000002 0000000B 7FFFFFFF 80000000 FFFFFFFF 
# 00000000 00000001 0000000A 00000002 0000000B 7FFFFFFF 80000000 FFFFFFFF 
# 00000001 00000001 0000000A 00000002 0000000B 7FFFFFFF 80000000 FFFFFFFF 
# 00000002 00000001 0000000A 00000002 0000000B 7FFFFFFF 80000000 FFFFFFFF 
# number_of_elements_got 0x8
# array: dump 
#  0x 0x1 0xA 0x2 0xB 0x7FFFFFFF 0x80000000 0xFFFFFFFF
# number_of_elements_got 0x8
# array: dump 
#  0x1 0x1 0xA 0x2 0xB 0x7FFFFFFF 0x80000000 0xFFFFFFFF
# number_of_elements_got 0x8
# array: dump 
#  0x2 0x1 0xA 0x2 0xB 0x7FFFFFFF 0x80000000 0xFFFFFFFF
# Main test finished
EOF
)

if [[ $return_value == 0 ]] &&
   [[ ! "$error" =~ "$error_not_contain" ]] &&
   [[ "$out" =~ "$out_expected" ]] ; then
    echo -e "$test_name -> ${GREEN}successfull${NC}"
    exit 0
else
    echo -e "$test_name -> ${RED}error${NC}"
    exit 1
fi
