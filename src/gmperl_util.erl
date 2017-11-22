%% -*- mode: erlang;erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ft=erlang ts=4 sw=4 et

%% @doc Utilities around gmperl_nifs using the mutable (gmperl_nifs) API.
-module(gmperl_util).

-export([mpz_set_bignum/2, mpz_to_bignum/1]).
-export([mpz_from_bignum/1]).

-type mpz_t() :: gmperl_nifs:mpz_t().
%% -type mpq_t() :: gmperl_nifs:mpq_t().
%% -type mpf_t() :: gmperl_nifs:mpf_t().

-spec mpz_from_bignum(integer()) -> mpz_t().
mpz_from_bignum(X) ->
    Z = gmperl_nifs:mpz_init(),
    mpz_set_bignum(Z, X),
    Z.

-define(WORD_SIZE, erlang:system_info({wordsize,internal})).
-define(WORD_SIZE_IN_BITS, (?WORD_SIZE*8)).
-define(MACHINE_WORD_SIZE, erlang:system_info({wordsize,external})).
-define(ENDIANESS, erlang:system_info(endian)).

-spec mpz_set_bignum(mpz_t(), integer()) -> ok.
mpz_set_bignum(Z, X) when is_integer(X) ->
    %% XXX: Can we do this efficiently without erts_debug:flat_size/1?
    Words = max(1, erts_debug:flat_size(X) - 1),
    WordSize = ?WORD_SIZE,
    B = <<(abs(X)):(Words * WordSize)/native-unit:8>>,
    Order = case ?ENDIANESS of little -> -1; big -> 1 end,
    gmperl_nifs:mpz_import(Z, Words, Order, WordSize, Order, 0, B),
    case X < 0 of
	false -> ok;
	true ->
	    gmperl_nifs:mpz_neg(Z, Z)
    end.

-spec mpz_to_bignum(mpz_t()) -> integer().
mpz_to_bignum(Z) ->
    %% Bignums seem to have a max size of 32*1024*1024 - WORD_SIZE_IN_BITS
    %% bits. Throw system_limit if we can't fit.
    case gmperl_nifs:mpz_sizeinbase(Z, 2)
        > (32*1024*1024 - ?WORD_SIZE_IN_BITS)
    of
        false -> ok;
        true -> error(system_limit, [Z])
    end,
    case ?ENDIANESS of
	little ->
	    B = gmperl_nifs:mpz_export(-1, ?MACHINE_WORD_SIZE, -1, 0, Z),
	    S = byte_size(B),
	    Sign = case gmperl_nifs:mpz_sgn(Z) of
		       -1 -> 1;
		       _ -> 0
		   end,
	    binary_to_term(<<131, 111, S:32, Sign, B/binary>>);
	big ->
            %% TODO: test the assumption that this is faster on big-endian
	    %% systems (it isn't, even with /little, on little-endian systems)
	    B = gmperl_nifs:mpz_export(1, ?MACHINE_WORD_SIZE, 1, 0, Z),
	    S = byte_size(B),
	    <<X:S/native-unit:8>> = B,
	    case gmperl_nifs:mpz_sgn(Z) of
		-1 -> -X;
		_ -> X
	    end
    end.
