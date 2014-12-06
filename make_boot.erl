#!/usr/bin/env escript
%% -*- erlang -*-
%%! -pz erlpmd/ebin -pz noepmd/ebin

-module(make_boot).

make_rel() ->
    application:load(erlpmd),
    application:load(noepmd),
    Apps = [{N,V} || {N,_,V} <- application:loaded_applications()],

    {release, {"NOEPMD", "0"}, {erts, erlang:system_info(version)},
     [{kernel, proplists:get_value(kernel, Apps)},
      {stdlib, proplists:get_value(stdlib, Apps)},
      {erlpmd, proplists:get_value(erlpmd, Apps), load},
      {noepmd, proplists:get_value(noepmd, Apps)}]}.


make_start_sh() ->
    {ok, Root} = init:get_argument(root),
    {ok, ProgName} = init:get_argument(progname),
    {ok, Home} = init:get_argument(home),
    [<<"#!/usr/bin/env bash\n\n">>,
     <<"export ROOTDIR=\"">>, Root, <<"\"\n">>,
     <<"export BINDIR=\"${ROOTDIR}/erts-">>, erlang:system_info(version), <<"/bin\"\n\n">>,
     <<"exec \"${BINDIR}/beam.smp\" -- -root \"${ROOTDIR}\" -progname ">>, ProgName,
     <<" -- -pz erlpmd/ebin -pz noepmd/ebin -home ">>, Home,
     <<" -- -mode minimal -sname foo -boot noepmd\n">>
    ].

main(_) ->
    ok = file:write_file("noepmd.rel", io_lib:format("~p.~n", [make_rel()])),
    ok = systools:make_script("noepmd"),
    ok = file:write_file("start.sh", make_start_sh()).
