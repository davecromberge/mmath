-module(mmath_bin_eqc).

-include("../include/mmath.hrl").

-import(mmath_helper, [int_array/0, pos_int/0, non_neg_int/0, realise/1,
                       defined_int_array/0, non_empty_i_list/0, confidence/1,
                       fully_defined_int_array/0]).

-include_lib("eqc/include/eqc.hrl").

-compile(export_all).

prop_empty() ->
    ?FORALL(Length, non_neg_int(),
            byte_size(mmath_bin:empty(Length)) == Length*?DATA_SIZE).

prop_length() ->
    ?FORALL(Length, non_neg_int(),
            mmath_bin:length(mmath_bin:empty(Length)) == Length).

prop_l2b_b2l() ->
    ?FORALL(List, list(int()),
            List == ?B2L(?L2B(List))).

prop_b2l() ->
    ?FORALL({_, L, B}, int_array(),
            L == ?B2L(B)).

prop_l2b() ->
    ?FORALL({_, L, B}, fully_defined_int_array(),
            B == ?L2B(L)).

prop_realize_derealize() ->
    ?FORALL({L, _, B}, int_array(),
            begin
                Exp = realise(L),
                Calc = ?B2L(mmath_bin:derealize(mmath_bin:realize(B))),
                ?WHENFAIL(io:format(user, "~p =/= ~p~n",
                                    [Exp, Calc]),
                          Exp == Calc)
            end).

prop_confidence() ->
    ?FORALL({L, _, B}, int_array(),
            begin
                CExp = confidence(L),
                CCalc = ?B2L(mmath_bin:derealize(mmath_bin:confidence_r(mmath_bin:realize(B)))),
                ?WHENFAIL(io:format(user, "~p =/= ~p~n",
                                    [CExp, CCalc]),
                          CExp == CCalc)
            end).

prop_realize() ->
    ?FORALL({T, _, B}, defined_int_array(),
            begin
                %% This unpacking pattern will work on 64 bit machines.
                L1 = [I || <<I:64/signed-native, _E:64/signed-native>> <= mmath_bin:realize(B)],
                L = realise(T),
                ?WHENFAIL(io:format(user, "~p =/= ~p~n",
                                    [L, L1]),
                          L == L1)
            end).
