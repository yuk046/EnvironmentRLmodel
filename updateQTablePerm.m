function [Q,maxk,maxvar,dreward,MA_noise_n]=updateQTablePerm(Qtable_Integrated,reward, new_state,action , currentState, counts, Parameters,reset)
Q=Qtable_Integrated;
if Parameters.useKTD 
    [Q,maxk,maxvar,dreward,MA_noise_n]=updateQTablePermKTD(Qtable_Integrated,reward, new_state,action , currentState, Parameters,reset);
else
    
    [nq,maxvar,dreward]=...
        updateQTablePermBase(Qtable_Integrated.mean,reward, new_state,action , currentState,counts, Parameters);
    Q.mean(currentState,action)=nq;
    maxk=0;
    MA_noise_n=0;    
        
end
end