function [Q,maxk,maxvar,dreward,MA_noise_n]=updateQTablePermNoResetMBFW(Qtable_Integrated,reward, new_state,action , currentState, counts, Parameters)
Q=Qtable_Integrated;
if Parameters.useKTD 
    msgID = 'noKTD in no reset mode';
    msg = 'cannot use useKTD parameter in no reset mode.';
    baseException = MException(msgID,msg);
    
else
    
    [nQ,maxvar,dreward]=...
        updateQTablePermBase(Qtable_Integrated.mean,reward, new_state,action , currentState,counts, Parameters);
    Q(currentState,currentState)=nQ;
    maxk=0;
    MA_noise_n=0;    
        
end
end