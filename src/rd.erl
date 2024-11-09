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
%% Include 
%%
%%--------------------------------------------------------------------

-include("log.api").

%% To be changed when create a new server
-include("rd.hrl").

%% API
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
	 multicall/5,
	 call/6,
	 cast/4
	]).

%% admin




-export([
	 template_call/1,
	 template_cast/1,	 
	 start/0,
	 ping/0,
	 stop/0
	]).

-export([start_link/0]).

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

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
start()->
    application:start(?MODULE).

%%--------------------------------------------------------------------
%% @doc
%% Used to check if the application has started correct
%% @end
%%--------------------------------------------------------------------
-spec ping() -> pong | Error::term().
ping()-> 
    gen_server:call(?SERVER, {ping},infinity).

%%--------------------------------------------------------------------
%% @doc
%% Used to check if the application has started correct
%% @end
%%--------------------------------------------------------------------
-spec template_call(Args::term()) -> {ok,Year::integer(),Month::integer(),Day::integer()} | Error::term().
template_call(Args)-> 
    gen_server:call(?SERVER, {template_call,Args},infinity).
%%--------------------------------------------------------------------
%% @doc
%% Used to check if the application has started correct
%% @end
%%--------------------------------------------------------------------
-spec template_cast(Args::term()) -> ok.
template_cast(Args)-> 
    gen_server:cast(?SERVER, {template_cast,Args}).

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


%stop()-> gen_server:cast(?SERVER, {stop}).
stop()-> gen_server:stop(?SERVER).

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
    
    {ok, #state{
	    monitored_nodes=[]	    
	   },0}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%% @end
%%--------------------------------------------------------------------
-spec handle_call(Request :: term(), From :: {pid(), term()}, State :: term()) ->
	  {reply, Reply :: term(), NewState :: term()} |
	  {reply, Reply :: term(), NewState :: term(), Timeout :: timeout()} |
	  {reply, Reply :: term(), NewState :: term(), hibernate} |
	  {noreply, NewState :: term()} |
	  {noreply, NewState :: term(), Timeout :: timeout()} |
	  {noreply, NewState :: term(), hibernate} |
	  {stop, Reason :: term(), Reply :: term(), NewState :: term()} |
	  {stop, Reason :: term(), NewState :: term()}.


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


%%----- TemplateCode ---------------------------------------------------------------

handle_call({template_call,Args}, _From, State) ->
    Result=try erlang:apply(erlang,date,[])  of
	      {Y,M,D}->
		   {ok,Y,M,D};
	      {error,ErrorR}->
		   {error,["M:F [A]) with reason",erlang,date,[erlang,date,[]],"Reason=", ErrorR]}
	   catch
	       Event:Reason:Stacktrace ->
		   {error,[#{event=>Event,
			     module=>?MODULE,
			     function=>?FUNCTION_NAME,
			     line=>?LINE,
			     args=>Args,
			     reason=>Reason,
			     stacktrace=>[Stacktrace]}]}
	   end,
    Reply=case Result of
	      {ok,Year,Month,Day}->
		  NewState=State,
		  {ok,Year,Month,Day};
	      {error,ErrorReason}->
		  NewState=State,
		  {error,ErrorReason}
	  end,
    {reply, Reply,NewState};

%%----- Admin ---------------------------------------------------------------

handle_call({ping}, _From, State) ->
    Reply=pong,
    {reply, Reply, State};

handle_call(UnMatchedSignal, From, State) ->
   ?LOG_WARNING("Unmatched signal",[UnMatchedSignal]),
    io:format("unmatched_signal ~p~n",[{UnMatchedSignal, From,?MODULE,?LINE}]),
    Reply = {error,[unmatched_signal,UnMatchedSignal, From]},
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------
%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------
handle_cast({trade_resources}, State) ->
    ResourceTuples=rd_store:get_local_resource_tuples(),
    DeletedResourceTuples=rd_store:get_deleted_resource_tuples(),
    AllNodes =[node()|nodes()],
    lists:foreach(
      fun(Node) ->
	      gen_server:cast({?MODULE,Node},
			      {trade_resources, {node(),{ResourceTuples,DeletedResourceTuples}}})
      end,
      AllNodes),
    {noreply, State};

handle_cast({trade_resources, {ReplyTo,{RemoteResourceTuples,DeletedResourceTuples}}},State) ->
    _Deleted=[{rd_store:delete_resource_tuple(ResourceTuple),ResourceTuple}||ResourceTuple<-DeletedResourceTuples],
    RemovedMonitoring=[{Node,erlang:monitor_node(Node,false)}||{_Type,{_Module,Node}}<-DeletedResourceTuples],
    L1=[MonitoredNode||MonitoredNode<-State#state.monitored_nodes,
		    false=:=lists:keymember(MonitoredNode,1,RemovedMonitoring)],
    TargetTypes=rd_store:get_target_resource_types(),
    FilteredRemotes=[{ResourceType,Resource}||{ResourceType,Resource}<-RemoteResourceTuples,
					      true=:=lists:member(ResourceType,TargetTypes)],
    ok=rd_store:store_resource_tuples(FilteredRemotes),
    AddedMonitoringResult=[{Node,erlang:monitor_node(Node,true)}||{_Type,{_Module,Node}}<-FilteredRemotes,
							    false=:=lists:keymember(Node,1,L1)],
    AddedNodes=[Node||{Node,_}<-AddedMonitoringResult],
    UpdatedMonitoredNodes=lists:usort(lists:append(AddedNodes,L1)),
    NewState=State#state{monitored_nodes=UpdatedMonitoredNodes}, 
    case ReplyTo of
        noreply ->
	    ok;
	_ ->
	    Locals=rd_store:get_local_resource_tuples(),
	    DeletedLocals=rd_store:get_deleted_resource_tuples(),
	   gen_server:cast({?MODULE,ReplyTo},
			   {trade_resources, {noreply, {Locals,DeletedLocals}}})
    end,
 
    {noreply, NewState};


handle_cast({template_cast,Args}, State) ->
    Result=try erlang:apply(erlang,date,[])  of
	      {Year,Month,Day}->
		   {ok,Year,Month,Day};
	      {error,ErrorR}->
		   {error,["M:F [A]) with reason",erlang,date,[erlang,date,[]],"Reason=", ErrorR]}
	   catch
	       Event:Reason:Stacktrace ->
		   {error,[#{event=>Event,
			     module=>?MODULE,
			     function=>?FUNCTION_NAME,
			     line=>?LINE,
			     args=>Args,
			     reason=>Reason,
			     stacktrace=>[Stacktrace]}]}
	   end,
    case Result of
	{ok,_Year,_Month,_Day}->
	    NewState=State;
	{error,_ErrorReason}->
	    NewState=State
    end,
    {noreply, NewState};



handle_cast({stop}, State) ->
    
    {stop,normal,ok,State};

handle_cast(UnMatchedSignal, State) ->
    ?LOG_WARNING("Unmatched signal",[UnMatchedSignal]),
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
    DeletedResourceTuples=[{Type,{Module,ResourceNode}}||{Type,{Module,ResourceNode}}<-rd_store:get_all_resources(),
							ResourceNode=:=NodeDown],
    _DeletedCache=[{rd_store:delete_resource_tuple(ResourceTuple),ResourceTuple}||ResourceTuple<-DeletedResourceTuples],
    RemovedMonitoring=[{Node,erlang:monitor_node(Node,false)}||{_Type,{_Module,Node}}<-DeletedResourceTuples],
    L1=[MonitoredNode||MonitoredNode<-State#state.monitored_nodes,
		    false=:=lists:keymember(MonitoredNode,1,RemovedMonitoring)],
    UpdatedMonitoredNodes=lists:usort(L1),
    NewState=State#state{monitored_nodes=UpdatedMonitoredNodes}, 
    rd:trade_resources(),
    {noreply, NewState};

handle_info(timeout, State) ->
    rd_store:new(),
    ?LOG_NOTICE("Server started ",[?MODULE]),
    {noreply, State};

handle_info(Info, State) ->
    ?LOG_WARNING("Unmatched signal",[Info]),
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

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
multicall(ResourceType,M,F,A,TO)->
    Result=case [N||{_,N}<-rd:fetch_resources(ResourceType)] of
	       []->
		   ?LOG_WARNING("No resources",[ResourceType]),
		   {error,["No target resources ",ResourceType]};
	       Resources->
		   {ResL,NonExistingNodes}=rpc:multicall(Resources,M,F,A,TO),
		   case NonExistingNodes of
		       []->
			   ok;
		       NonExistingNodes->
			   ?LOG_WARNING("NonExistingNodes",[NonExistingNodes])
		   end,
		   BadRpcList=[{badrpc,Reason}||{badrpc,Reason}<-ResL],
		   case BadRpcList of
		       []->
			   ok;
		       BadRpcList->
			   ?LOG_WARNING("BadRpcList",[BadRpcList])
		   end,
		   case [R||R<-ResL,false=:=lists:member(R,BadRpcList)] of
		       []->
			   {error,["NonExistingNodes and BadRpcList ",NonExistingNodes,BadRpcList]};
		       [Res|T]->
			   case [R||R<-T,Res=/=R] of
			       []->
				   {ok,Res};
			       DiffList ->
				   {error,["Different results",Res,DiffList]}
			   end;
		       X ->
			   {error,["Unmatched signal ",X]}
		   end	   
	   end,
    Result.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
call(WantedHost,ResourceType,M,F,A,TO)->
    Result=case [N||{_,N}<-rd:fetch_resources(ResourceType)] of
	       []->
		   ?LOG_WARNING("No resources",[ResourceType]),
		   {error,["No target resources ",ResourceType]};
	       Resources->
		   L1=[{N,string:lexemes(atom_to_list(node()),"@")}||N<-Resources],
		   ResourcesHost=[N||{N,[_NodeName,Host]}<-L1,
				     Host=:=WantedHost],
		   case ResourcesHost of
		       []->
			   {error,["No target resources on Host ",ResourceType,WantedHost]};
		       [Resource|_]->
			   case rpc:call(Resource,M,F,A,TO) of
			       {badrpc,Reason}->
				   {error,["Badrpc reason ",Reason]};
			       Res->
				   {ok,Res};
			       X ->
				   {error,["Unmatched signal ",X]}
			   end
		   end
	   end,
    Result.
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
cast(ResourceType,M,F,A)->
    Result=case [N||{_,N}<-rd:fetch_resources(ResourceType)] of
	       []->
		   ?LOG_WARNING("No resources",[ResourceType]),
		   {error,["No target resources ",ResourceType]};
	       Resources->
		   {ResL,NonExistingNodes}=rpc:cast(Resources,M,F,A),
		   case NonExistingNodes of
		       []->
			   ok;
		       NonExistingNodes->
			   ?LOG_WARNING("NonExistingNodes",[NonExistingNodes])
		   end,
		   BadRpcList=[{badrpc,Reason}||{badrpc,Reason}<-ResL],
		   case BadRpcList of
		       []->
			   ok;
		       BadRpcList->
			   ?LOG_WARNING("BadRpcList",[BadRpcList])
		   end,
		   case [R||R<-ResL,false=:=lists:member(R,BadRpcList)] of
		       []->
			   {error,["NonExistingNodes and BadRpcList ",NonExistingNodes,BadRpcList]};
		       [Res|T]->
			   case [R||R<-T,Res=/=R] of
			       []->
				   {ok,Res};
			       DiffList ->
				   {error,["Different results",Res,DiffList]}
			   end;
		       X ->
			   {error,["Unmatched signal ",X]}
		   end	   
	   end,
    Result.
