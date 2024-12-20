%%%-------------------------------------------------------------------
%% @doc application_server public API
%% @end
%%%-------------------------------------------------------------------

-module(rd_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    rd_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
