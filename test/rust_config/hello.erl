-module(hello).
-include_lib("eunit/include/eunit.hrl").

areyouthere_test() ->
	{ok, ExtPrg} = find_crate:find_executable(test_rust_tests, "hello", "hello"),
    _Port = open_port({spawn, ExtPrg}, []),
	ok.
