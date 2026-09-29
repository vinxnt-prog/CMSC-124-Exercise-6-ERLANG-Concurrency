-module(pingpong).
-compile(export_all).

start_pong() ->
	register (pong, spawn(pingpong,pong,[])).

pong() ->
	receive
		finished ->
			io:format("Pong finished ~n");
		{ping, Ping_Pid} ->
			io:format("Pong got ping ~n"),
			Ping_Pid ! pong,
			pong()
	end.

start_ping(Pong_Node) ->
	spawn(pingpong, ping, [3,Pong_Node]).

ping(0, Pong_Node) ->
	{pong, Pong_Node} ! finished,
	io:format("Ping finished");
ping(N, Pong_Node) ->
	{pong, Pong_Node} ! {ping, self()},
	receive
		pong ->
			io:format("Ping got pong~n")
	end,
	ping(N-1,Pong_Node).