%%% SHA-1 module
%%% Author: Nicolas Favre-Felix - n.favrefelix@gmail.com
%%% License: Public Domain
%%% Original page: http://github.com/nicolasff/sha1-erlang/
%%% 
%%% exports binstring(Str), hexstring(Str). binstring/1 returns the hash as
%%% a binary, hexstring/1 as an erlang string, uppercase.
%%% in case of failure, the returned value is {error, Reason}.
%%% *file/1 functions show very bad performance.

-module(sha1).
-export([binstring/1, hexstring/1, binfile/1, hexfile/1, bin2hex/1]).
-import(lists, [nth/2, map/2, foldl/3]).
-import(erlang,[integer_to_list/2, list_to_integer/2]).

binstring(S) -> fun_apply(S, fun list_to_binary/1, fun(X)->X end).
hexstring(S) -> fun_apply(S, fun list_to_binary/1, fun bin2hex/1).
binfile(S) -> fun_apply(S, fun read_unsafe/1, fun(X)->X end).
hexfile(S) -> fun_apply(S, fun read_unsafe/1, fun bin2hex/1).

fun_apply(S, FunRead, FunTransform) ->
	case catch binstring_unsafe(FunRead(S)) of 
		{'EXIT', Stuff} -> {error, Stuff};
		Data -> FunTransform(Data)
	end.

read_unsafe(File) ->  {ok, L} = file:read_file(File), 	L.

bin2hex(B) ->
	L = binary_to_list(B),
	LH0 = map(fun(X)->integer_to_list(X,16) end, L),
	LH = map(fun([X,Y])->[X,Y];([X])->[$0,X] end, LH0), % add zeros
	lists:flatten(LH).

binstring_unsafe(S) ->
	X = pad_str(S),
	N = length(binary_to_list(X)) div 64,
	Hs = {16#67452301, 16#EFCDAB89, 16#98BADCFE, 16#10325476, 16#C3D2E1F0},
	compute(X, N, Hs).

pad_str(B) ->
	L = 8 * size(B),
	D = (512 + ((447 - L) rem 512)) rem 512, % negative (447-L) handled
	<<B/binary, 1:1, 0:D, L:64>>. % hehe i like how 0:D looks


add([]) -> 0;
add([H|T]) -> (H + add(T)) rem 16#100000000.


compute(<<>>, 0, {H0,H1,H2,H3,H4}) -> <<H0:32, H1:32, H2:32, H3:32, H4:32>>;

compute(<<Bin:512, Other/binary>>, I, {H0,H1,H2,H3,H4} = Hs) ->
	W0_15 = compute_ws(<<Bin:512>>),
	Ws = compute_wt(W0_15), 
	{A,B,C,D,E} = inner_loop(0, Hs, Ws),
	compute(Other, I-1, {add([H0,A]), add([H1,B]), add([H2,C]),
		add([H3,D]),add([H4,E])}).

%% generates K_i
k(I) when  0 =< I, I =< 19 -> 16#5A827999;
k(I) when 20 =< I, I =< 39 -> 16#6ED9EBA1;
k(I) when 40 =< I, I =< 59 -> 16#8F1BBCDC;
k(I) when 60 =< I, I =< 79 -> 16#CA62C1D6.

%% f_t
f(T, B,C,D) when  0 =< T, T =< 19 -> (B band C) bor ((bnot B) band D);
f(T, B,C,D) when 20 =< T, T =< 39 -> B bxor C bxor D;
f(T, B,C,D) when 40 =< T, T =< 59 -> (B band C) bor (B band D) bor (C band D);
f(T, B,C,D) when 60 =< T, T =< 79 -> B bxor C bxor D.
 
%% rotates S bytes to the left on 32 bits
rotl(S, Num) ->
	Max = 16#ffffffff,
	LMask = (Max bsl (32-S)) ,
	RMask = (Max bsr (S)) ,
	L = Num band LMask,
	R = Num band RMask,
	NewL = (R bsl S) ,
	NewR = (L bsr (32-S)) ,
	NewL + NewR.

compute_ws(<<>>) -> [];
compute_ws(<<Wi:32, Other/binary>>) -> [Wi] ++ compute_ws(Other).

%% generates W_t. 
compute_wt(Ws) -> compute_wt(Ws, 16).
compute_wt(Ws, 80) -> Ws;
compute_wt(Ws, T) -> 
	Wp = map(fun(X)->nth(1 + T - X, Ws) end, [3,8,14,16]),
	Wt_pre = foldl(fun(X,Y)->X bxor Y end, 0, Wp),
	Wt = rotl(1, Wt_pre),
	compute_wt(Ws ++ [Wt], T+1).

%% the SHA-1 inner loop
inner_loop(80, {A,B,C,D,E}, _Ws) -> {A,B,C,D,E};
inner_loop(T, {A,B,C,D,E}, Ws) ->
	Temp = add([rotl(5, A), f(T, B,C,D), E, nth(1+T, Ws), k(T)]),
	inner_loop(T+1, {Temp, A, rotl(30, B), C, D}, Ws).
	
