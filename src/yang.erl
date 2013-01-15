%%%---- BEGIN COPYRIGHT -------------------------------------------------------
%%%
%%% Copyright (C) 2007 - 2012, Rogvall Invest AB, <tony@rogvall.se>
%%%
%%% This software is licensed as described in the file COPYRIGHT, which
%%% you should have received as part of this distribution. The terms
%%% are also available at http://www.rogvall.se/docs/copyright.txt.
%%%
%%% You may opt to use, copy, modify, merge, publish, distribute and/or sell
%%% copies of the Software, and permit persons to whom the Software is
%%% furnished to do so, under the terms of the COPYRIGHT file.
%%%
%%% This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
%%% KIND, either express or implied.
%%%
%%%---- END COPYRIGHT ---------------------------------------------------------
%%% @author Tony Rogvall <tony@rogvall.se>
%%% @doc
%%%     YANG scanner & parser
%%% @end
%%% Created :  2 Jan 2012 by Tony Rogvall <tony@rogvall.se>

-module(yang).

-export([scan_file/1,
	 parse_file/1,
	 deep_parse_file/1,
	 validate_file/1,
	 json_rpc/1,
	 typespec/1, 
	 check_type/2]).
-import(lists, [reverse/1]).

-type  type() :: binary() | {type,integer(),binary(),list()}.


scan_file(File) ->
    yang_scan:file(File).

parse_file(File) ->
    yang_parser:parse(File).

deep_parse_file(File) ->
    yang_parser:deep_parse(File).

validate_file(File) ->
    yang_parser:validate(File).

json_rpc(YangFile) ->
    yang_json:json_rpc(YangFile).

typespec(Module) ->
    yang_typespec:typespec(Module).

-spec check_type(any(), type()) -> {true, any()} | false.
%% @spec check_type(Value, Type) -> {true, ConvertedValue} | false
%% Check Value against a YANG type definition.
%%
%% The "types" object, array and untyped are not actually YANG types, but used in the
%% YANG_JSON spec. They are only included here initially; it should be an error to call
%% this function for such objects (except perhaps for "untyped", which indicates that no
%% YANG type could be found).
%% @end
check_type(X, <<"object">> ) -> {true, X};
check_type(X, <<"array">>  ) -> {true, X};
check_type(X, undefined) -> {true, X};
check_type(X, anyxml) when is_list(X); is_binary(X) -> {true, X};
check_type(X, {type,_,<<"enumeration">>,En}) ->
    case [E || {E,V} <- [{E1,get_value(I)} || {enum,_,E1,I} <- En],
	       V == X] of
	[] -> false;
	[Val] ->
	    {true, Val}
    end;
check_type(X, {type,_,<<"binary">>,_}) when is_binary(X) -> {true, X};
check_type(X, {type,_,<<"bits">>,_}) when is_bitstring(X) -> {true, X};
check_type(X, {type,_,<<"string">>,_}) ->
    try {true, iolist_to_binary(X)}
    catch
	error:_ ->
	    false
    end;
check_type(<<"1">>, {type,_,<<"boolean">>,_}) -> {true, true};
check_type(<<"0">>, {type,_,<<"boolean">>,_}) -> {true, false};
check_type(X, {type,_,<<"empty">>,_} ) ->
    case is_empty(X) of
	true -> {true, []};
	false -> false
    end;
check_type(X, {type,_,<<"decimal64">>,_}) ->
    case re:split(X, "\\.", [{return,list}]) of
	[_Ib, _Fb]  ->
	    case io_lib:fread("~f", binary_to_list(X)) of
		{ok, [F], []} ->
		    {true, F};
		_ ->
		    false
	    end;
	_ ->
	    false
    end;
check_type(X, {type,_,<<"int", _/binary>> = T,_}) when is_integer(X) ->
    check_int_type(X, T);
check_type(X, {type,_,<<"int", _/binary>> = T,_}) ->
    try check_int_type(list_to_integer(to_list(X)), T)
    catch
	error:_ ->
	    false
    end;
check_type(X, {type,_,<<"uint", _/binary>> = T,_}) when is_integer(X) ->
    check_uint_type(X, T);
check_type(X, {type,_,<<"uint", _/binary>> = T,_}) ->
    try check_uint_type(list_to_integer(to_list(X)), T)
    catch
	error:_ ->
	    false
    end;
check_type(X, _) ->
    %% TODO: cover all types
    {true, X}.

check_int_type(N, T) when is_integer(N) ->
    if 	T == <<"uint8">>, 08 =< N, N =< 255 -> {true, N};
	T == <<"uint16">>, 0 =< N, N =< 65535 -> {true, N};
	T == <<"uint32">>, 0 =< N, N =< 4294967295 -> {true, N};
	T == <<"uint64">>, 0 =< N, N =< 18446744073709551615 -> {true, N};
	true -> false
    end.

check_uint_type(N, T) when is_integer(N) ->
    if T == <<"uint8">>, 08 =< N, N =< 255 -> {true, N};
       T == <<"uint16">>, 0 =< N, N =< 65535 -> {true, N};
       T == <<"uint32">>, 0 =< N, N =< 4294967295 -> {true, N};
       T == <<"uint64">>, 0 =< N, N =< 18446744073709551615 -> {true, N};
       true -> false
    end.

to_list(B) when is_binary(B) ->
    binary_to_list(B);
to_list(L) when is_list(L) ->
    L.

get_value(I) ->
    {value, V} = lists:keyfind(value, 1, I),
    V.

is_empty(<<>>) -> true;
is_empty([])   -> true;
is_empty(_)    -> false.

