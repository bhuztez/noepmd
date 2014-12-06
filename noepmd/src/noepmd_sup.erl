%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 1996-2013. All Rights Reserved.
%% 
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%% 
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%% 
%% %CopyrightEnd%
%%

-module(noepmd_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    SupFlags = {one_for_all, 0, 1},
    Rpc = {rex, {rpc, start_link, []},
           permanent, 2000, worker, [rpc]},
    Global = {global_name_server, {global, start_link, []},
              permanent, 2000, worker, [global]},
    Glo_grp = {global_group, {global_group,start_link,[]},
               permanent, 2000, worker, [global_group]},
    InetDb = {inet_db, {inet_db, start_link, []},
              permanent, 2000, worker, [inet_db]},
    NetSup = {net_sup, {erl_distribution, start_link, []},
              permanent, infinity, supervisor,[erl_distribution]},
    DistAC = start_dist_ac(),
    Timer = start_timer(),

    ErlPMD = [{erlpmd, {erlpmd, start_link, [[]]},
               transient, 5000, worker, [erlpmd]},
              {erlpmd_listener, {tcp_listener, start_link, [[{0,0,0,0}, 4369]]},
               transient, 5000, worker, [tcp_listener]}],

    {ok, {SupFlags,
          [Rpc, Global, InetDb|DistAC] ++ ErlPMD ++
          [NetSup, Glo_grp] ++ Timer}}.


start_dist_ac() ->
    Spec = [{dist_ac,{dist_ac,start_link,[]},permanent,2000,worker,[dist_ac]}],
    case application:get_env(kernel, start_dist_ac) of
        {ok, true} -> Spec;
        {ok, false} -> [];
        undefined ->
            case application:get_env(kernel, distributed) of
                {ok, _} -> Spec;
                _ -> []
            end
    end.


start_timer() ->
    case application:get_env(kernel, start_timer) of
        {ok, true} -> 
            [{timer_server, {timer, start_link, []}, permanent, 1000, worker, 
              [timer]}];
        _ ->
            []
    end.
