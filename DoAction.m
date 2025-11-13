function 		    [reward, new_state]  = DoAction( action , currentState, Environment )

reward_s=Environment.reward{currentState, action};

Ps=Environment.ps{currentState, action};

nextState=Environment.nextState{currentState, action};

i=randsample(length(Ps),1,true,Ps');

new_state= nextState(i);

reward= reward_s(i);

end