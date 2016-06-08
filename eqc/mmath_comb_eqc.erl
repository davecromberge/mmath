-module(mmath_comb_eqc).

-include("../include/mmath.hrl").

-import(mmath_helper, [number_array/0, defined_number_array/0, almost_equal/2, realise/1]).

-include_lib("eqc/include/eqc.hrl").

-compile(export_all).

prop_sum() ->
    ?FORALL({La, _, Ba}, number_array(),
            begin
                Lr = realise(La),
                R1 = sum(Lr, Lr),
                R2 = mmath_comb:sum([Ba, Ba]),
                R3 = mmath_bin:to_list(mmath_bin:derealize(R2)),
                ?WHENFAIL(io:format(user, "~p /= ~p~n", [R1, R3]),
                          almost_equal(R1, R3))
            end).

prop_avg() ->
    ?FORALL({La, _, Ba}, number_array(),
            begin
                Lr = realise(La),
                R1 = avg(Lr, Lr),
                R2 = mmath_comb:avg([Ba, Ba]),
                R3 = mmath_bin:to_list(mmath_bin:derealize(R2)),
                ?WHENFAIL(io:format(user, "~p /= ~p~n", [R1, R3]),
                          almost_equal(R1, R3))
            end).


%% prop_mul() ->
%%     ?FORALL({La, _, Ba}, number_array(),
%%             begin
%%                 R1 = mul(La, La),
%%                 R2 = mmath_bin:to_list(mmath_comb:mul([Ba, Ba])),
%%                 ?WHENFAIL(io:format(user, "~p /= ~p~n", [R1, R2]),
%%                           almost_equal(R1, R2))
%%             end).

%% prop_zip() ->
%%     ?FORALL({La, _, Ba}, number_array(),
%%             begin
%% 				F = fun(A, B) -> A * B end,
%%                 R1 = mul(La, La),
%%                 R2 = mmath_bin:to_list(mmath_comb:zip(F, [Ba, Ba])),
%%                 ?WHENFAIL(io:format(user, "~p /= ~p~n", [R1, R2]),
%%                           almost_equal(R1, R2))
%%             end).

avg(A, B) ->
    [N / 2 ||  N <- sum(A, B)].

sum(A, B) ->
    sum(A, B, []).

sum([A | R1], [B | R2], Acc) ->
    sum(R1, R2, [A + B | Acc]);
sum([], [], Acc) ->
    lists:reverse(Acc).


mul(A, B) ->
    mul(A, B, 1, 1, []).

mul([{false, _} | R1], [{true, B} | R2], LA, _, Acc) ->
    mul(R1, R2, LA, B, [LA * B | Acc]);
mul([{true, A} | R1], [{false, _} | R2], _, LB, Acc) ->
    mul(R1, R2, A, LB, [A * LB | Acc]);
mul([{false, _} | R1], [{false, _} | R2], LA, LB, Acc) ->
    mul(R1, R2, LA, LB, [LA * LB | Acc]);
mul([{true, A} | R1], [{true, B} | R2], _, _, Acc) ->
    mul(R1, R2, A, B, [A * B | Acc]);
mul([], [], _, _, Acc) ->
    lists:reverse(Acc);
mul([], [{true, B} | R], LA, _, Acc) ->
    mul([], R, LA, B, [LA * B | Acc]);
mul([], [{false, _} | R], LA, LB, Acc) ->
    mul([], R, LA, LB, [LA * LB | Acc]);
mul(A, [], LA, LB, Acc) ->
    mul([], A, LA, LB, Acc).
