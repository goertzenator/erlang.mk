# Rust crate plugin.

RUST_CASES = tests
RUST_TARGETS = $(addprefix rust-,$(RUST_CASES))

.PHONY: $(C_SRC_TARGETS)

rust: $(RUST_TARGETS)


rust-tests: build clean

	$i "Bootstrap a new OTP library named $(APP)"
	$t mkdir $(APP)/
	$t cp ../erlang.mk $(APP)/
	$t $(MAKE) -C $(APP) -f erlang.mk bootstrap-lib $v
	$t cp rust_config/Makefile $(APP)
	$t cp rust_config/hello.erl $(APP)/src/

	$i "Generate an executable crate"
	$t mkdir $(APP)/crates
	cd $(APP)/crates && cargo new --bin hello

	$i "Test the application"
	$t $(MAKE) -C $(APP) tests $v
