%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%%
%%% @end
%%% Created : 22 Nov 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(lib_rd).

-define(NumberOfAttemps,10).
%% API
-export([
	 detect_target_resources/2
	]).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
detect_target_resources(TargetTypes,MaxDetectTime)->
    Interval=erlang:trunc(MaxDetectTime/?NumberOfAttemps),
    case detect(TargetTypes,Interval,?NumberOfAttemps-1) of
	ok->
	    ok;
	{error,Reason} ->
	    {error,Reason}
    end.
%%%===================================================================
%%% Internal functions
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
detect(TargetTypes,Interval,NumberOfAttemps)->
    detect(TargetTypes,Interval,NumberOfAttemps,false,[]).


detect(_TargetTypes,_Interval,_NumberOfAttemps,true,_Acc)->
    ok;
detect(_TargetTypes,_Interval,0,true,_Acc) ->
    ok;
detect(_TargetTypes,_Interval,0,false,MissingTargetTypes) ->
    {error,["Following TargetTypes are not available ",MissingTargetTypes]};

detect(TargetTypes,Interval,NumberOfAttemps,false,_MissingTargetTypes)->
    TargetResources=[{TargetType,rd:fetch_resources(TargetType)}||TargetType<-TargetTypes],
    NewMissingTargetTypes=[TargetType||{TargetType,[]}<-TargetResources],
 %   io:format("NewMissingTargetTypes ~p~n",[{NewMissingTargetTypes,?MODULE,?LINE}]),  
    
    case NewMissingTargetTypes of
	[]->
	    NewNumberOfAttemps=0,
	    TargetTypesAvaiable=true;
	NewMissingTargetTypes->
	    timer:sleep(Interval),
	    NewNumberOfAttemps=NumberOfAttemps-1,
	    TargetTypesAvaiable=false
    end,
detect(TargetTypes,Interval,NewNumberOfAttemps,TargetTypesAvaiable,NewMissingTargetTypes).    
	

    
