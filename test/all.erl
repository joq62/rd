%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Created :
%%%
%%% -------------------------------------------------------------------
-module(all).       
 
-export([start/0]).
%%---------- Log
-define(MainLogDir,"logs").
-define(LocalLogDir,"log.logs").
-define(LogFile,"test_logfile").
-define(MaxNumFiles,10).
-define(MaxNumBytes,100000).


-define(Appl,t).
-define(TestAppl,test_t).

%%---------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
start()->
   
    ok=setup(),
    ok=test_rd:test_resources_multicall_normal(),
    ok=test_rd:test_resources_call_normal(),
    ok=test_rd:test_resources_multicall_error(),
    timer:sleep(5000),
    ok=test_rd:test_resources_call_error(),


    io:format("Test OK !!! ~p~n",[?MODULE]),
    timer:sleep(2000),
    init:stop(),
    ok.
%%-----------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
setup()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
  
    ok=application:start(test_appl),
    pong=log:ping(),
    %% Fix log
    file:del_dir_r(?MainLogDir),
    file:make_dir(?MainLogDir),
    [NodeName,_HostName]=string:tokens(atom_to_list(node()),"@"),
    NodeNodeLogDir=filename:join(?MainLogDir,NodeName),
    ok=log:create_logger(NodeNodeLogDir,?LocalLogDir,?LogFile,?MaxNumFiles,?MaxNumBytes),
 
    %% To be changed when create a new server
    pong=rd:ping(),
    timer:sleep(10*1000),

    ok.
