%% -*- mode: erlang;erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ft=erlang ts=4 sw=4 et
-module(gmperl_nifs).
-author('Hunter Morris <huntermorris@gmail.com>').

-on_load(init/0).

-export([info_lib/0, mpz_refeq/2]).
-export([mpz_import/7, mpz_export/5]).

-export_type([mpz_t/0, mpq_t/0, mpf_t/0]).

{% for f in mpz %}{% include "priv/templates/export.erl" %}{% endfor %}
{% for f in mpq %}{% include "priv/templates/export.erl" %}{% endfor %}
{% for f in mpf %}{% include "priv/templates/export.erl" %}{% endfor %}
-define(ERR, nif_stub_error(?LINE)).
-define(ERR(Line), erlang:nif_error({nif_not_loaded, module, ?MODULE, line, Line})).

-ifdef(TEST).
-compile(export_all).
-include_lib("eunit/include/eunit.hrl").
-endif.

-opaque mpz_t() :: binary().
-opaque mpq_t() :: binary().
-opaque mpf_t() :: binary().

-type num_base() :: 0 | 2..62.

-spec init() -> ok | {error, any()}.

-spec info_lib() -> [{binary(), binary()}].

-spec mpz_refeq(mpz_t(), mpz_t()) -> boolean().
-spec mpz_import(mpz_t(), non_neg_integer(), -1 | 1, pos_integer(), -1 | 0 | 1,
                 non_neg_integer(), binary()) -> ok.
-spec mpz_export(-1 | 1, pos_integer(), -1 | 0 | 1, non_neg_integer(), mpz_t())
                -> binary().

{% for f in mpz %}{% include "priv/templates/spec.erl" %}{% endfor %}
{% for f in mpq %}{% include "priv/templates/spec.erl" %}{% endfor %}
{% for f in mpf %}{% include "priv/templates/spec.erl" %}{% endfor %}
init() ->
    Dir = case code:priv_dir(gmperl) of
              {error, bad_name} -> "../priv";
              Priv              -> Priv
          end,
    erlang:load_nif(filename:join(Dir, "gmperl"), 0).

nif_stub_error(Line) -> erlang:nif_error({nif_not_loaded,module,?MODULE,line,Line}).

info_lib() -> ?ERR.

mpz_refeq(_, _) -> ?ERR.
mpz_import(_, _, _, _, _, _, _) -> ?ERR.
mpz_export(_, _, _, _, _) -> ?ERR.

{% for f in mpz %}{% include "priv/templates/nif.erl" %}{% endfor %}
{% for f in mpq %}{% include "priv/templates/nif.erl" %}{% endfor %}
{% for f in mpf %}{% include "priv/templates/nif.erl" %}{% endfor %}
-ifdef(TEST).

mpq_str_test() ->
    Ref = mpq_init(),
    ok = mpq_set_str(Ref, "9999999", 10),
    ?assertEqual("9999999", mpq_get_str(Ref, 10)).

mpz_test() ->
    _Ref0 = mpz_init(),
    Ref1 = mpz_init_set_str("1500", 10),
    ?assertEqual(1500, mpz_get_ui(Ref1)),
    ?assertEqual(1500, mpz_get_si(Ref1)),
    ?assertEqual(1500.0, mpz_get_d(Ref1)),
    ?assertEqual("1500", mpz_get_str(Ref1, 10)),
    _Ref2 = mpz_init_set(Ref1).

mpz_add_test() ->
    Ref0 = mpz_init_set_str("1500", 10),
    Ref1 = mpz_init_set_str("22", 10),
    Ref2 = mpz_init(),
    ok = mpz_add(Ref2, Ref0, Ref1),
    ?assertEqual(1522, mpz_get_ui(Ref2)),
    ok = mpz_set_str(Ref0, "-1000", 10),
    ok = mpz_add(Ref2, Ref0, Ref1),
    ?assertEqual(-978, mpz_get_si(Ref2)).

-endif.
