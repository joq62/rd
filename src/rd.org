%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%%
%%% @end
%%% Created : 18 Apr 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(rd).

-behaviour(gen_server).
%%--------------------------------------------------------------------
-include("log.api").
%%--------------------------------------------------------------------

%-type resource_type() :: atom(). % gen_server or lib module
%-type resource() :: {Node :: node(), Module :: atom()}.      % node()
%-type resource_tuple() :: {resource_type(), resource()}. % {Module,Node} 


-export([
	 detect_target_resources/2
	]).
%% API
-export([add_target_resource_type/1,
	 add_local_resource/2,
	 delete_local_resource_tuple/2,
	 get_delete_local_resource_tuples/0,
	 fetch_resources/1,
	 fetch_nodes/1,
	 trade_resources/0,
	 get_monitored_nodes/0,
	 get_all_resources/0,
	 get_state/0
	]).

-export([
	 call/4,
	 call/5
	]).


-export([
	 ping/0
	]).

-export([start_link/0,
	 start/0,
	 stop/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3, format_status/2]).

-define(SERVER, ?MODULE).

-record(state, {target_resource_types,  % I want part
	        local_resource_tuples,  % I have part
	        found_resource_tuples,  % Local cache of found resources
		monitored_nodes
	       }).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
detect_target_resources(TargetTypes,MaxDetectTime)->
    lib_rd:detect_target_resources(TargetTypes,MaxDetectTime).
    



%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
add_target_resource_type(ResourceType) ->
    gen_server:call(?SERVER, {add_target_resource_type, ResourceType},infinity).
add_local_resource(ResourceType, Resource) ->
    gen_server:call(?SERVER, {add_local_resource, ResourceType, Resource},infinity).
delete_local_resource_tuple(ResourceType, Resource) ->
    gen_server:call(?SERVER, {delete_local_resource_tuple, ResourceType, Resource},infinity).
get_delete_local_resource_tuples() ->
    gen_server:call(?SERVER, {get_delete_local_resource_tuples},infinity).

fetch_nodes(ResourceType) ->
    gen_server:call(?SERVER, {fetch_nodes, ResourceType}).
fetch_resources(ResourceType) ->
    gen_server:call(?SERVER, {fetch_resources, ResourceType}).

trade_resources() ->
    gen_server:cast(?SERVER,{trade_resources}).
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------

start()->
    application:start(?MODULE).
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
get_all_resources()-> 
    gen_server:call(?SERVER, {get_all_resources},infinity).

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
get_monitored_nodes()-> 
    gen_server:call(?SERVER, {get_monitored_nodes},infinity).

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
get_state()-> 
    gen_server:call(?SERVER, {get_state},infinity).
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
ping()-> 
    gen_server:call(?SERVER, {ping},infinity).
%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%% @end
%%--------------------------------------------------------------------
-spec start_link() -> {ok, Pid :: pid()} |
	  {error, Error :: {already_started, pid()}} |
	  {error, Error :: term()} |
	  ignore.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


stop()-> gen_server:call(?SERVER, {stop},infinity).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%% @end
%%--------------------------------------------------------------------
-spec init(Args :: term()) -> {ok, State :: term()} |
	  {ok, State :: term(), Timeout :: timeout()} |
	  {ok, State :: term(), hibernate} |
	  {stop, Reason :: term()} |
	  ignore.

init([]) ->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]), 
    ?LOG_NOTICE("Server started ",[]),
    
    {ok, #state{monitored_nodes=[]},
     0}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------


handle_call({fetch_nodes,Type},_From, State) ->
    Reply=[Node||{_,Node}<-rd_store:get_resources(Type)],
    {reply, Reply, State};

handle_call({fetch_resources,Type},_From, State) ->
    Reply=rd_store:get_resources(Type),
    {reply, Reply, State};

handle_call( {delete_local_resource_tuple,Type,Resource},_From,State) ->
    Reply=rd_store:delete_local_resource_tuple({Type,Resource}),
    {reply,Reply,State};

handle_call( {get_delete_local_resource_tuples},_From,State) ->
    Reply=rd_store:get_deleted_resource_tuples(),
    {reply,Reply,State};

handle_call({add_target_resource_type,ResourceType}, _From, State) ->
    TargetTypes=rd_store:get_target_resource_types(), % TargetTypes=State#state.target_resource_types,
    NewTargetTypes=[ResourceType|lists:delete(ResourceType,TargetTypes)],
    Reply=rd_store:store_target_resource_types(NewTargetTypes),
    {reply, Reply,State};

handle_call( {add_local_resource,ResourceType,Resource}, _From, State) ->
    Reply=rd_store:store_local_resource_tuples([{ResourceType,Resource}]),
    {reply,Reply, State};

handle_call( {get_all_resources}, _From, State) ->
    Reply=rd_store:get_all_resources(),
    {reply,Reply, State};

handle_call({get_monitored_nodes}, _From, State) ->
    Reply=State#state.monitored_nodes,
    {reply, Reply, State}; 

handle_call({get_state}, _From, State) ->
    Reply=[{target_resource_types,rd_store:get_target_resource_types()},
	   {local_resource_tuples,rd_store:get_local_resource_tuples()}
	  ],
    {reply, Reply, State};  

handle_call({ping}, _From, State) ->
    Reply=pong,
    {reply, Reply, State};


handle_call(UnMatchedSignal, From, State) ->
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal, From,?MODULE,?LINE}]),
    Reply = {error,[unmatched_signal,UnMatchedSignal, From]},
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------
handle_cast({trade_resources}, State) ->
    ResourceTuples=rd_store:get_local_resource_tuples(),
    DeletedResourceTuples=rd_store:get_deleted_resource_tuples(),
%    io:format(" I have and delete ~p~n",[{node(),ResourceTuples,DeletedResourceTuples,?FUNCTION_NAME,?MODULE,?LINE}]),
    AllNodes =[node()|nodes()],
    lists:foreach(
      fun(Node) ->
	      gen_server:cast({?MODULE,Node},
			      {trade_resources, {node(),{ResourceTuples,DeletedResourceTuples}}})
      end,
      AllNodes),
    {noreply, State};

handle_cast({trade_resources, {ReplyTo,{RemoteResourceTuples,DeletedResourceTuples}}},State) ->
%    io:format("Receiving node ***************************** ~p~n",[{node(),?FUNCTION_NAME,?MODULE,?LINE}]),    
%    io:format("From node  ~p~n",[{ReplyTo,?FUNCTION_NAME,?MODULE,?LINE}]),  
%    io:format("RemoteResourceTuples  ~p~n",[{RemoteResourceTuples,?FUNCTION_NAME,?MODULE,?LINE}]),  
%    io:format("DeletedResourceTuples  ~p~n",[{DeletedResourceTuples,?FUNCTION_NAME,?MODULE,?LINE}]),  
  
    %% Delete resource tuples and remove monitoring
    _Deleted=[{rd_store:delete_resource_tuple(ResourceTuple),ResourceTuple}||ResourceTuple<-DeletedResourceTuples],
    RemovedMonitoring=[{Node,erlang:monitor_node(Node,false)}||{_Type,{_Module,Node}}<-DeletedResourceTuples],
    L1=[MonitoredNode||MonitoredNode<-State#state.monitored_nodes,
		    false=:=lists:keymember(MonitoredNode,1,RemovedMonitoring)],
    
%    io:format("Receiving node Deleted  ~p~n",[{node(),Deleted,?FUNCTION_NAME,?MODULE,?LINE}]),  
    TargetTypes=rd_store:get_target_resource_types(),
%    io:format("Receiving node wants following TargetTypes ~p~n",[{node(),TargetTypes,?MODULE,?LINE}]),
    FilteredRemotes=[{ResourceType,Resource}||{ResourceType,Resource}<-RemoteResourceTuples,
					      true=:=lists:member(ResourceType,TargetTypes)],
 %   io:format("Receiving node will store following TargetResources from sender ~p~n",[{node(),FilteredRemotes,?MODULE,?LINE}]),
    
    ok=rd_store:store_resource_tuples(FilteredRemotes),
    AddedMonitoringResult=[{Node,erlang:monitor_node(Node,true)}||{_Type,{_Module,Node}}<-FilteredRemotes,
							    false=:=lists:keymember(Node,1,L1)],
    
 %   io:format("AddedMonitoringResult ~p~n",[{node(),AddedMonitoringResult,?MODULE,?LINE}]),
    AddedNodes=[Node||{Node,_}<-AddedMonitoringResult],
    UpdatedMonitoredNodes=lists:usort(lists:append(AddedNodes,L1)),
    NewState=State#state{monitored_nodes=UpdatedMonitoredNodes}, 
 %   io:format("UpdatedMonitoredNodes ~p~n",[{node(),UpdatedMonitoredNodes,?MODULE,?LINE}]),
    
    case ReplyTo of
        noreply ->
	    ok;
	_ ->
	    Locals=rd_store:get_local_resource_tuples(),
	    DeletedLocals=rd_store:get_deleted_resource_tuples(),
	%   io:format("Receiving node replys with following resources tuples  ~p~n",[{node(),Locals,?FUNCTION_NAME,?MODULE,?LINE}]),  
	   gen_server:cast({?MODULE,ReplyTo},
			   {trade_resources, {noreply, {Locals,DeletedLocals}}})
    end,
 
    {noreply, NewState};


handle_cast(UnMatchedSignal, State) ->
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal,?MODULE,?LINE}]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%% @end
%%--------------------------------------------------------------------
-spec handle_info(Info :: timeout() | term(), State :: term()) ->
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: normal | term(), NewState :: term()}.
handle_info({nodedown,NodeDown}, State) ->
%    io:format("node(), NodeDown ~p~n",[{node(),NodeDown,?MODULE,?LINE}]),
%     io:format("node(),get_all_resources ~p~n",[{node(),rd_store:get_all_resources(),?MODULE,?LINE}]),
    DeletedResourceTuples=[{Type,{Module,ResourceNode}}||{Type,{Module,ResourceNode}}<-rd_store:get_all_resources(),
							ResourceNode=:=NodeDown],
  %  io:format("node(), DeletedResourceTuples ~p~n",[{node(),DeletedResourceTuples,?MODULE,?LINE}]),
    %% Delete cache
    _DeletedCache=[{rd_store:delete_resource_tuple(ResourceTuple),ResourceTuple}||ResourceTuple<-DeletedResourceTuples],
%    io:format("DeletedCache ~p~n",[{node(),DeletedCache,?MODULE,?LINE}]),
    %% Remove monitoring
    RemovedMonitoring=[{Node,erlang:monitor_node(Node,false)}||{_Type,{_Module,Node}}<-DeletedResourceTuples],
    L1=[MonitoredNode||MonitoredNode<-State#state.monitored_nodes,
		    false=:=lists:keymember(MonitoredNode,1,RemovedMonitoring)],
    UpdatedMonitoredNodes=lists:usort(L1),
    NewState=State#state{monitored_nodes=UpdatedMonitoredNodes}, 
    rd:trade_resources(),
  %  io:format("node(), UpdatedMonitoredNodes ~p~n",[{NodeDown,UpdatedMonitoredNodes,?MODULE,?LINE}]),
    {noreply, NewState};



handle_info(timeout, State) ->
   
    rd_store:new(),
    {noreply, State};

handle_info(Info, State) ->
    io:format("unmatched_signal ~p~n",[{Info,?MODULE,?LINE}]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%% @end
%%--------------------------------------------------------------------
-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		State :: term()) -> any().
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%% @end
%%--------------------------------------------------------------------
-spec code_change(OldVsn :: term() | {down, term()},
		  State :: term(),
		  Extra :: term()) -> {ok, NewState :: term()} |
	  {error, Reason :: term()}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called for changing the form and appearance
%% of gen_server status when it is returned from sys:get_status/1,2
%% or when it appears in termination error logs.
%% @end
%%--------------------------------------------------------------------
-spec format_status(Opt :: normal | terminate,
		    Status :: list()) -> Status :: term().
format_status(_Opt, Status) ->
    Status.

%%%===================================================================
%%% Internal functions
%%%===================================================================
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
call(ResourceType, Module, Function, Args, Timeout) ->
    Reply=case rd_store:get_resources(ResourceType) of
	      {error,Reason}->
		  {error,Reason};
	      []->
		  {error,["Resource eexists ",ResourceType]};
	      Resources ->
		  [{_,Node}|_]=Resources,
		%  [{Node,_}|_]=Resources,
		  rpc:call(Node, Module, Function, Args, Timeout)
	%	  case rpc:call(Resource, Module, Function, Args, Timeout) of
	%	      {badrpc, _Reason} ->
	%		  case rd:delete_local_resource(ResourceType, Resource) of
	%		      {error,Reason}->
	%			  {error,Reason};
	%		      ok->
	%			  rd:rpc_call(ResourceType, Module, Function, Args, Timeout)
	%		  end;
	%	      R ->
	%		  R
	%	  end;
	     
	  end,
    Reply.

call(ResourceType, Function, Args, Timeout) ->
 %   io:format(" ResourceType, Function, Args, Timeout ~p~n",[{ResourceType, Function, Args, Timeout, ?MODULE,?LINE}]),
    Reply=case rd_store:get_resources(ResourceType) of
	      {error,Reason}->
		  {error,Reason};
	      []->
		  {error,[eexists_resources]};
	      Resources ->
		  [{Module,Node}|_]=Resources,
		  rpc:call(Node, Module, Function, Args, Timeout)
	%	  case rpc:call(Resource, Module, Function, Args, Timeout) of
	%	      {badrpc, _Reason} ->
	%		  case rd:delete_local_resource(ResourceType, Resource) of
	%		      {error,Reason}->
	%			  {error,Reason};
	%		      ok->
	%			  rd:rpc_call(ResourceType, Module, Function, Args, Timeout)
	%		  end;
	%	      R ->
	%		  R
	%	  end;
	     
	  end,
    Reply.


%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
