%%! -sname n@172.30.0.22 -setcookie riak
-module(riakadmin).
-export([main/1]).

main(Args) -> 
  io:format("Args: ~p\n", [Args]),
  Node = lists:nth(1, Args),
  Key = lists:concat([lists:nth(2, Args)]),
  Secret = lists:concat([lists:nth(3, Args)]),
  NewArgs = [Secret, Key, Node],
  io:format("NewArgs: ~p\n", [NewArgs]),
  List = ["name", "a@a.com", Key, Secret],
  io:format("~p", [rpc:call(Node, riak_cs_user, create_user, List)]).