%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Created :
%%% Node end point  
%%% Creates and deletes Pods
%%% 
%%% API-kube: Interface 
%%% Pod consits beams from all services, app and app and sup erl.
%%% The setup of envs is
%%% -------------------------------------------------------------------
-module(basic_tests).      
 
-export([start/0]).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-define(ClusterName,"test_cluster").
-define(MaxDetectTime,3000).


%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
start()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),

    ok=setup(),
    ok=normal_tests(),
    ok=rpc_tests(),
%    ok=rpc_multi_tests(),
    ok=stop_start_tests(),
   

    io:format("Succeeded !!! ~p~n",[{?MODULE,?FUNCTION_NAME}]),
 
    ok.


%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
rpc_multi_tests()->

    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]), 
    
    Local0=[{type0,node0},{type1,node0}],
    Local1=[{type1,node1}],
    Local2=[{type2,node2},{type21,node2}],
    Target0=[type1,type2],
    Target1=[type0,type21],
    Target2=[type1,type2],
    [Node0,Node1,Node2]=lists:sort(test_nodes:get_nodes()),
    Date=date(),
    {[Date],[]}=rpc:call(Node0,rd,rpc_multicall,[type0,erlang,date,[]]),  
    {[],[]}=rpc:call(Node1,rd,rpc_multicall,[type0,erlang,date,[]]),  
    {[],[]}=rpc:call(Node2,rd,rpc_multicall,[type0,erlang,date,[]]),  
    
    {[Date],[]}=rpc:call(Node0,rd,rpc_multicall,[type1,erlang,date,[]]),
    {[Date],[]}=rpc:call(Node1,rd,rpc_multicall,[type1,erlang,date,[]]),
    {[],[]}=rpc:call(Node2,rd,rpc_multicall,[type1,erlang,date,[]]),
    {[],[]}=rpc:call(Node0,rd,rpc_multicall,[type2,erlang,date,[]]),
    
    

    io:format("Stop OK !!! ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    ok.

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
rpc_tests()->

    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]), 
    
    [Node0,Node1,Node2]=lists:sort(test_nodes:get_nodes()),
    Date=date(), 
    Local0=[{type0,{Node0,erlang}},{type1,{Node0,filelib}}],
    Local1=[{type1,{Node1,filelib}}],
    Local2=[{type2,{Node2,test_module2}},{type0,{Node2,filelib}}],
    Target0=[type1,type2],
    Target1=[type0,type2],
    Target2=[type1,type2],

 
    Date=rpc:call(Node0,rd,call,[type1,erlang,date,[],5000]),  
    Date=rpc:call(Node1,rd,call,[type0,date,[],5000]),  
    {error,[eexists_resources]}=rpc:call(Node2,rd,call,[type0,is_file,["Makefile"],5000]),  
    
    Date=rpc:call(Node0,rd,call,[type1,erlang,date,[],5000]),
    {error,[eexists_resources]}=rpc:call(Node1,rd,call,[type1,erlang,date,[],5000]),
    Date=rpc:call(Node2,rd,call,[type1,erlang,date,[],5000]),
    42=rpc:call(Node1,rd,call,[type2,test_module2,add,[22,20],5000]),
    42=rpc:call(Node1,rd,call,[type2,add,[22,20],5000]),
    

    io:format("Stop OK !!! ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    ok.


%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
stop_start_tests()->

    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]), 
 
    [Node0,Node1,Node2]=lists:sort(test_nodes:get_nodes()),
    [pong,pong,pong]=[net_adm:ping(N)||N<- [Node0,Node1,Node2]],
 
    %% {type0,erlang},{type1,filelib},{type2,test_module2}
    %% Node0 = Provide:{type0,type1}, want {type1,type2}
    %% Node1 = Provide {type1},       want {type0,type2}  
    %% Node2 = Provide {type0,type2}, want {type1,type2}

    Local0=[{type0,{Node0,erlang}},{type1,{Node0,filelib}}],
    Local1=[{type1,{Node1,filelib}}],
    Local2=[{type2,{Node2,test_module2}},{type0,{Node2,filelib}}],
    Target0=[type1,type2],
    Target1=[type0,type2],
    Target2=[type1,type2],
    
    %%
    [Node0,Node1,Node2]=rpc:call(Node0,rd,get_monitored_nodes,[],5000),

    %% Node0
    [{filelib,Node0},{filelib,Node1}]=lists:sort(rpc:call(Node0,rd,fetch_resources,[type1])),
    [{test_module2,Node2}]=lists:sort(rpc:call(Node0,rd,fetch_resources,[type2])),

    [{type1,{filelib,'n0@c50'}},
     {type1,{filelib,'n1@c50'}},
     {type2,{test_module2,'n2@c50'}}
    ]=lists:sort(rpc:call(Node0,rd,get_all_resources,[],5000)),
    
    %% Node1
    [{erlang,Node0},{filelib,Node2}]=lists:sort(rpc:call(Node1,rd,fetch_resources,[type0])),
    [{test_module2,Node2}]=lists:sort(rpc:call(Node1,rd,fetch_resources,[type2])),

    %% Node2
    [{filelib,Node0},{filelib,Node1}]=lists:sort(rpc:call(Node2,rd,fetch_resources,[type1])),
    [{test_module2,Node2}]=lists:sort(rpc:call(Node2,rd,fetch_resources,[type2])),

    []=lists:sort(rpc:call(Node1,rd,fetch_resources,[type1])),
    []=lists:sort(rpc:call(Node2,rd,fetch_resources,[type0])),
    
    %% remove type0 from Node0 
    [{type0,{erlang,Node0}},{type1,{filelib,Node0}}]=lists:sort(rpc:call(Node0,rd_store,get_local_resource_tuples,[],5000)),
    []=lists:sort(rpc:call(Node0,rd_store,get_deleted_resource_tuples,[],5000)),
    ok=rpc:call(Node0,rd,delete_local_resource_tuple,[type0,{erlang,n0@c50}],5000),
    [{type1,{filelib,Node0}}]=lists:sort(rpc:call(Node0,rd_store,get_local_resource_tuples,[],5000)),
    [{type0,{erlang,Node0}}]=lists:sort(rpc:call(Node0,rd_store,get_deleted_resource_tuples,[],5000)),
    
    rpc:call(Node0,rd,trade_resources,[],5000),
    timer:sleep(3000),

    %% Node0
    [{filelib,Node0},{filelib,Node1}]=lists:sort(rpc:call(Node0,rd,fetch_resources,[type1])),
    [{test_module2,Node2}]=lists:sort(rpc:call(Node0,rd,fetch_resources,[type2])),
    
    %% Node1
    [{filelib,Node2}]=lists:sort(rpc:call(Node1,rd,fetch_resources,[type0])),
    [{test_module2,Node2}]=lists:sort(rpc:call(Node1,rd,fetch_resources,[type2])),

    %% Node2
    [{filelib,Node0},{filelib,Node1}]=lists:sort(rpc:call(Node2,rd,fetch_resources,[type1])),
    [{test_module2,Node2}]=lists:sort(rpc:call(Node2,rd,fetch_resources,[type2])),
    
    %% remove type2 from Node2
    ok=rpc:call(Node2,rd,delete_local_resource_tuple,[type2,{test_module2,Node2}],5000),
    rpc:call(Node2,rd,trade_resources,[],5000),
    timer:sleep(3000),
    
     %% Node0
    [{filelib,Node0},{filelib,Node1}]=lists:sort(rpc:call(Node0,rd,fetch_resources,[type1])),
    []=lists:sort(rpc:call(Node0,rd,fetch_resources,[type2])),
    
    %% Node1
    [{filelib,Node2}]=lists:sort(rpc:call(Node1,rd,fetch_resources,[type0])),
    []=lists:sort(rpc:call(Node1,rd,fetch_resources,[type2])),

    %% Node2
    [{filelib,Node0},{filelib,Node1}]=lists:sort(rpc:call(Node2,rd,fetch_resources,[type1])),
    []=lists:sort(rpc:call(Node2,rd,fetch_resources,[type2])),
    
    %% kill Node0

    slave:stop(Node0),
    
    %% Node0
    {badrpc,nodedown}=rpc:call(Node0,rd,fetch_resources,[type1]),
    {badrpc,nodedown}=rpc:call(Node0,rd,fetch_resources,[type2]),

    timer:sleep(5000),
    
    %% Node1
    [{filelib,Node2}]=lists:sort(rpc:call(Node1,rd,fetch_resources,[type0])),
    []=lists:sort(rpc:call(Node1,rd,fetch_resources,[type2])),
    [Node2]=rpc:call(Node1,rd,get_monitored_nodes,[],5000),
    %% Node2
    [{filelib,Node1}]=lists:sort(rpc:call(Node2,rd,fetch_resources,[type1])),
    []=lists:sort(rpc:call(Node2,rd,fetch_resources,[type2])),
    [Node1]=rpc:call(Node2,rd,get_monitored_nodes,[],5000),
  
    io:format("Stop OK !!! ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    ok.
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
normal_tests()->

    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]), 
 
    [Node0,Node1,Node2]=lists:sort(test_nodes:get_nodes()),
    % type0 -> Node0,Node2
    % type1 -> Node0,Node1
    % type2 -> Node2
    Local0=[{type0,{erlang,Node0}},{type1,{filelib,Node0}}],
    Local1=[{type1,{filelib,Node1}}],
    Local2=[{type2,{test_module2,Node2}},{type0,{filelib,Node2}}],
    
    % Node0(type1)-> [Node0,Node1]
    % Node0((type2) -> Node2
    % Node1(type0)-> [Node0,Node2]
    % Node1(type2)-> [Node2]
    % Node2(type1)-> [Node0,Node1]
    % Node2(type2)-> [Node2]
    Target0=[type1,type2],
    Target1=[type0,type2],
    Target2=[type1,type2],
   
    Date=erlang:date(),

    
    % Add Node0
   
    "ebin/log.beam"=rpc:call(Node0,code,where_is_file,["log.beam"],5000),
    "ebin/rd.beam"=rpc:call(Node0,code,where_is_file,["rd.beam"],5000),
  %  {ok,_}=rpc:call(Node0,log,start_link,[],5000),
  %  {ok,_}=rpc:call(Node0,rd,start_link,[],5000),
    ok=rpc:call(Node0,application,start,[log],5000),
    pong=rpc:call(Node0,log,ping,[],5000),
    ok=rpc:call(Node0,application,start,[rd],5000),
    pong=rpc:call(Node0,rd,ping,[],5000),

    [ok=rpc:call(Node0,rd,add_local_resource,[Type,Instance],5000)||{Type,Instance}<-Local0],
    [ok=rpc:call(Node0,rd,add_target_resource_type,[Type],5000)||Type<-Target0],
    ok=rpc:call(Node0,rd,trade_resources,[],5000),
    timer:sleep(5000),
  
    % Test TargetTypesResources are not available type2 for node0
    {error,["Following TargetTypes are not available ",[type2]]}=rpc:call(Node0,rd,detect_target_resources,[Target0,?MaxDetectTime],5000),
    
    [{filelib,Node0}]=rpc:call(Node0,rd,fetch_resources,[type1],5000),
    []=rpc:call(Node0,rd,fetch_resources,[type2],5000),
    
    
    Date=rpc:call(Node0,rd,call,[type1,erlang,date,[],5000],6000),  
    true=rpc:call(Node0,rd,call,[type1,is_file,["Makefile"],5000],6000),
  
  
   %%% Node1
   ok=rpc:call(Node1,application,start,[rd],5000),
    pong=rpc:call(Node1,rd,ping,[]),
    [ok=rpc:call(Node1,rd,add_local_resource,[Type,Instance],5000)||{Type,Instance}<-Local1],
    [ok=rpc:call(Node1,rd,add_target_resource_type,[Type],5000)||Type<-Target1],
    ok=rpc:call(Node1,rd,trade_resources,[],5000),
 
    timer:sleep(5000),
    [{filelib,'n0@c50'},{filelib,'n1@c50'}]=lists:sort(rpc:call(Node0,rd,fetch_resources,[type1],5000)), 
    []=lists:sort(rpc:call(Node1,rd,fetch_resources,[type1],5000)),
    [{erlang,'n0@c50'}]=lists:sort(rpc:call(Node1,rd,fetch_resources,[type0],5000)),
    []=rpc:call(Node0,rd,fetch_resources,[type2],5000),

    %% Node2
    ok=rpc:call(Node2,application,start,[rd],5000),
    pong=rpc:call(Node2,rd,ping,[]),
    [rpc:call(Node2,rd,add_local_resource,[Type,Instance],5000)||{Type,Instance}<-Local2],
    [rpc:call(Node2,rd,add_target_resource_type,[Type],5000)||Type<-Target2],
    ok=rpc:call(Node2,rd,trade_resources,[],5000),
    
    timer:sleep(3000),

    % Test TargetTypesResources are available for node0
    ok=rpc:call(Node0,rd,detect_target_resources,[Target0,?MaxDetectTime],5000),
    
    
    [{filelib,'n0@c50'},{filelib,'n1@c50'}]=lists:sort(rpc:call(Node0,rd,fetch_resources,[type1],5000)), 
    []=lists:sort(rpc:call(Node1,rd,fetch_resources,[type1],5000)),
    [{erlang,'n0@c50'},{filelib,'n2@c50'}]=lists:sort(rpc:call(Node1,rd,fetch_resources,[type0],5000)),
    [{filelib,'n0@c50'},{filelib,'n1@c50'}]=lists:sort(rpc:call(Node2,rd,fetch_resources,[type1],5000)),
    
    io:format("Stop OK !!! ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    ok.


%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
connect_tests()->

    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),  
   
    io:format("Stop OK !!! ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    ok.


%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------

setup()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    ok=test_nodes:start_nodes(),
    [Node0,Node1,Node2]=test_nodes:get_nodes(),
    [Node0,Node1,Node2]=lists:sort([Node0,Node1,Node2]),
    [pong,pong,pong,pong,pong,
     pong,pong,pong,pong]=[rpc:call(N1,net_adm,ping,[N2])||N1<-[Node0,Node1,Node2],
				     N2<-[Node0,Node1,Node2]],
  
    [true,true,true]=[rpc:call(N,code,add_patha,["test_ebin"],2000)||N<-[Node0,Node1,Node2]],
    [true,true,true]=[rpc:call(N,code,add_patha,["ebin"],2000)||N<-[Node0,Node1,Node2]],
    [Node0,Node1,Node2]=[rpc:call(N,erlang,node,[],2000)||N<-[Node0,Node1,Node2]],
    
    [pong,pong,pong]=[net_adm:ping(N)||N<-[Node0,Node1,Node2]],
    ok=application:start(log),
    pong=log:ping(),
    ok=application:start(rd),
    pong=rd:ping(),
    
    ok.
