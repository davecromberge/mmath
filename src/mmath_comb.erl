%%%-------------------------------------------------------------------
%%% @author Heinz Nikolaus Gies <heinz@licenser.net>
%%% @copyright (C) 2016, Project-FiFo UG
%%% @doc
%%% Module that provide mmath functions that combine metrics.
%%% All functions take a list of realized metrics and return a single
%%% realized metric
%%% @end
%%% Created : 29 Apr 2016 by Heinz Nikolaus Gies <heinz@licenser.net>
%%%-------------------------------------------------------------------
-module(mmath_comb).
-include("mmath.hrl").

-ifdef(TEST).
-compile(export_all).
-endif.

-export([avg/1,
         sum/1,
         min/1,
         mul/1
         %%merge/1,
         %%zip/2
        ]).


-define(APPNAME, mmath).
-define(LIBNAME, comb_nif).
-on_load(load_nif/0).
load_nif() ->
    SoName = case code:priv_dir(?APPNAME) of
                 {error, bad_name} ->
                     case filelib:is_dir(filename:join(["..", priv])) of
                         true ->
                             filename:join(["..", priv, ?LIBNAME]);
                         _ ->
                             filename:join([priv, ?LIBNAME])
                     end;
                 Dir ->
                     filename:join(Dir, ?LIBNAME)
             end,
    erlang:load_nif(SoName, 0).

%%--------------------------------------------------------------------
%% @doc
%% Creates a new dataset with each element being the sum of the
%% elements of the passed datasets.
%% @end
%%--------------------------------------------------------------------
-spec sum([binary()]) -> binary().
sum([A, B]) ->
    sum(A, B);

sum([A, B, C]) ->
    sum(A, B, C);

sum(Es) when is_list(Es) ->
    rcomb(fun sum/2, fun sum/3, Es).

%%--------------------------------------------------------------------
%% @doc
%% Creates a new dataset with each element being the multiple of the
%% elements of the passed datasets.
%% @end
%%--------------------------------------------------------------------
-spec mul([binary()]) -> binary().
mul([A, B]) ->
    mul(A, B).

%%--------------------------------------------------------------------
%% @doc
%% Creates a new dataset with each element being the min of the
%% elements of the passed datasets.
%% @end
%%--------------------------------------------------------------------
-spec min([binary()]) -> binary().
min([A, B]) ->
    min_(A, B);

min([A, B, C]) ->
    min_(A, B, C);

min(Es) when is_list(Es) ->
    rcomb(fun min_/2, fun min_/3, Es).

%%--------------------------------------------------------------------
%% @doc
%% Creates a new dataset with each element being the average (mean)
%% of the elements of the passed datasets.
%% @end
%%--------------------------------------------------------------------
-spec avg([binary()]) -> binary().
avg(Es) when is_list(Es), length(Es) > 0 ->
    mmath_trans:divide(sum(Es), length(Es)).

%%-------------------------------------------------------------------
%% Utility functions
%%-------------------------------------------------------------------

sum(_A, _B) ->
    erlang:nif_error(nif_library_not_loaded).

sum(_A, _B, _C) ->
    erlang:nif_error(nif_library_not_loaded).

mul(_A, _B) ->
    erlang:nif_error(nif_library_not_loaded).

min_(_A, _B) ->
    erlang:nif_error(nif_library_not_loaded).

min_(_A, _B, _C) ->
    erlang:nif_error(nif_library_not_loaded).

%%--------------------------------------------------------------------
%% @doc
%% Combines a set of datasets with a given combinator function.
%% this requires the combinator to be associative!
%%--------------------------------------------------------------------

-type comb_fun2() :: fun((binary(), binary()) -> binary()).
-type comb_fun3() :: fun((binary(), binary(), binary()) -> binary()).

-spec rcomb(comb_fun2(), comb_fun3(), L :: [binary()]) ->
                   binary().
rcomb(F2, F3, [A, B, C | R]) when is_function(F3) ->
    rcomb(F2, F3, [F3(A, B, C) | R]);

rcomb(F2, F3, [A, B | R]) ->
    rcomb(F2, F3, [F2(A, B) | R]);
rcomb(_, _, [E]) ->
    E.
