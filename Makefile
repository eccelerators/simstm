PWD=$(shell pwd)

test_basic:
	@cd ./test/basic/abort/ghdl/             && ./test.sh
	@cd ./test/basic/const_2/ghdl/           && ./test.sh
	@cd ./test/basic/const/ghdl/             && ./test.sh
	@cd ./test/basic/elsif/ghdl/             && ./test.sh
	@cd ./test/basic/else/ghdl/              && ./test.sh
	@cd ./test/basic/finish/ghdl/            && ./test.sh
	@cd ./test/basic/if/ghdl/                && ./test.sh
	@cd ./test/basic/include/ghdl/           && ./test.sh
	@cd ./test/basic/jump/ghdl/              && ./test.sh
	@cd ./test/basic/loop/ghdl/              && ./test.sh
	@cd ./test/basic/var_2/ghdl/             && ./test.sh
	@cd ./test/basic/var_3/ghdl/             && ./test.sh
	@cd ./test/basic/var/ghdl/               && ./test.sh

test_signals:
	@cd ./test/signals/signal_read/ghdl/         && ./test.sh
	@cd ./test/signals/signal_write/ghdl/        && ./test.sh
	@cd ./test/signals/signal_verify/ghdl/       && ./test.sh
	@cd ./test/signals/signal_verify_fail/ghdl/  && ./test.sh

test_bus:
	@cd ./test/bus/wishbone/ghdl/                   && ./test.sh
	@cd ./test/bus/wishbone_timeout_read/ghdl/      && ./test.sh
	@cd ./test/bus/wishbone_timeout_write/ghdl/     && ./test.sh
	@cd ./test/bus/wishbone_verification/ghdl/      && ./test.sh
	@cd ./test/bus/wishbone_verification_fail/ghdl/ && ./test.sh

test_variable:
	@cd ./test/variable/add_2/ghdl/             && ./test.sh
	@cd ./test/variable/add/ghdl/               && ./test.sh
	@cd ./test/variable/and/ghdl/               && ./test.sh
	@cd ./test/variable/mul/ghdl/               && ./test.sh
	@cd ./test/variable/or/ghdl/                && ./test.sh
	@cd ./test/variable/div/ghdl/               && ./test.sh
	@cd ./test/variable/equ_2/ghdl/             && ./test.sh
	@cd ./test/variable/equ/ghdl/               && ./test.sh
	@cd ./test/variable/sub/ghdl/               && ./test.sh
	@cd ./test/variable/xor/ghdl/               && ./test.sh


test_others:
	@cd ./test/others/call/ghdl/              && ./test.sh
	@cd ./test/others/begin_sub/ghdl/         && ./test.sh
	@cd ./test/others/return_call/ghdl/       && ./test.sh
	@cd ./test/others/end_sub/ghdl/           && ./test.sh
	@cd ./test/others/log/ghdl/               && ./test.sh
	@cd ./test/others/random/ghdl/            && ./test.sh
	@cd ./test/others/set_randomseeds/ghdl/   && ./test.sh


test_array:
	@cd ./test/array/array/ghdl/                && ./test.sh
	@cd ./test/array/array_get/ghdl/            && ./test.sh
	@cd ./test/array/array_get_out_pos/ghdl/    && ./test.sh
	@cd ./test/array/array_zero_size/ghdl/      && ./test.sh
	@cd ./test/array/array_set/ghdl/            && ./test.sh
	@cd ./test/array/array_set_out_pos/ghdl/    && ./test.sh
	@cd ./test/array/array_size/ghdl/           && ./test.sh

start_ghdl_docker:
	docker run -it -v ${PWD}:/work -w /work ghdl/ghdl:ubuntu22-llvm-11

.PHONY: ghdl test $(TARGETS)

test: test_basic test_variable test_bus test_signals test_others test_array
