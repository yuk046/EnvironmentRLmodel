%environmentParameters=struct(...
%   n_healthy_goals,V_n_healthy_goals,...
%   rew_Goals,Vrew_Goals,...
%   p_GetRewardGoals,Vp_GetRewardGoals
%   n_drug_goals,V_n_drug_goals,...
%   rew_DG,V_rew_DG,...
%   pun_DG,V_pun_DG,...
%   escaLation_factor_DG,V_escaLation_factor_DG,...
%   n_base_states,V_n_base_states,...
%   deterministic,V_deterministic);

function [Environment]  = CreateEnvironmentMultiStepDeterministic3(environmentParameters)
%%define state space
Num_States=environmentParameters.n_healthy_goals+environmentParameters.n_drug_goals+environmentParameters.n_base_states;
%%define action space
if (environmentParameters.n_drug_goals>0)
    Num_Actions=environmentParameters.n_healthy_goals+environmentParameters.n_base_states+2;
    a_getDrugs=(environmentParameters.n_healthy_goals+environmentParameters.n_base_states+2);
    actionName{a_getDrugs}='a-getDrugs';
else
    Num_Actions=environmentParameters.n_healthy_goals+environmentParameters.n_base_states+1;
end;

a_stay=(environmentParameters.n_healthy_goals+environmentParameters.n_base_states+1);
actionName{a_stay}='a-stay';


ps=cell(Num_States,Num_Actions);
reward=cell(Num_States,Num_Actions);
nextState=cell(Num_States,Num_Actions);
gr_idx=1;
%% define transition and reward probabilites
%% define goal state dynamics

%% define goal states dynamics
for st = 1:(environmentParameters.n_healthy_goals)
    nodenames{st}=strcat('goal-', int2str(st));
    for action=1:Num_Actions
        if (action==st)
            actionName{st}=strcat('a-Goal-',num2str(st));
            r=environmentParameters.rew_Goals(st);
            reward{st,action}=r;
            
            ps{st,action}(:)=1;
            
            nextState{st,action}(:)=...
                environmentParameters.n_healthy_goals+ceil(environmentParameters.n_base_states/2);
            
        else
            reward{st,action}=0 ;
            ps{st,action}=1;
            nextState{st,action}=st;
        end
    end
end
%%%
%% set base states
%%
for st = (environmentParameters.n_healthy_goals+1):(environmentParameters.n_healthy_goals+environmentParameters.n_base_states)
    nodenames{st}=['base-', int2str(st)];
    id=st-environmentParameters.n_healthy_goals;
    for action=1:Num_Actions
        display(['start: ' nodenames(st) ' act: ' actionName{action}])
        
        if(action<=environmentParameters.n_healthy_goals)
            
            reward{st,action}=0;
            ps{st,action}=1;
            if(id==1)
                
                nextState{st, action}=action;
                
            else
                nextState{st, action}=st;
            end
            
            
            
        elseif (action<=environmentParameters.n_healthy_goals+environmentParameters.n_base_states)
            actionName{action}=strcat('a-toState-',num2str(action));
            
            if abs(st-action)<=1
                p=0.99;
                reward{st,action}=[0 0];
            else
                p=0.0001;
                reward{st,action}=[0 environmentParameters.punishmentOutsideLine];
            end
            %p=min(0.9(abs(st-action)/environmentParameters.n_base_states).^6,1);
            
            ps{st,action}=[1-p, p];
            nextState{st, action}=[st,action];
        elseif action==(a_stay)
            
            reward{st,action}=0;
            ps{st,action}=1;
            nextState{st, action}=st;
            
        else if action==(a_getDrugs)%action_get_drugs
                id=st-environmentParameters.n_healthy_goals;
                
                if (st==(environmentParameters.n_healthy_goals+environmentParameters.n_base_states))
                    Environment.baseRewardBaseState{id,1}=environmentParameters.rew_DG;
                    
                    nextState{st, action}=environmentParameters.n_healthy_goals+environmentParameters.n_base_states+1;
                    
                else
                    Environment.baseRewardBaseState{id,1}=0;
                    nextState{st, action}=st;
                    
                end
                Environment.therapyRewardBaseState{id,1}=0;
                ps{st,action}=1;
                reward{st,action}=0;
            end
        end
    end
end

%% set drug states
for st= (environmentParameters.n_healthy_goals+environmentParameters.n_base_states)+(1:environmentParameters.n_drug_goals)
    nodenames{st}=['drug-', int2str(st)];
    stpos=(st-environmentParameters.n_healthy_goals-environmentParameters.n_base_states);
    reducedPunishmentF=0.1;
    r1=environmentParameters.pun_DG;%*environmentParameters.escaLation_factor_DG^(environmentParameters.n_drug_goals-stpos)
    p1=environmentParameters.pDG;%*environmentParameters.escaLation_factor_DG^(environmentParameters.n_drug_goals-stpos)
    
    for action=1:Num_Actions
        if(action<=environmentParameters.n_healthy_goals+environmentParameters.n_base_states)
            Environment.baseReward{stpos,action}=reducedPunishmentF*r1;
            Environment.therapyReward{stpos,action}=Environment.baseReward{stpos,action};
            reward{st,action}=environmentParameters.punishmentOutsideLine;
            ps{st,action}=1;
            nextState{st, action}=st;
            
        elseif(action==a_stay)
            if st==environmentParameters.n_healthy_goals+environmentParameters.n_base_states+environmentParameters.n_drug_goals
                
                Environment.baseReward{stpos,action}(:)=...
                    [reducedPunishmentF*r1,r1, reducedPunishmentF*r1];
                
                Environment.therapyReward{stpos,action}(:)=[reducedPunishmentF*r1,r1, reducedPunishmentF*r1];
                
                reward{st,action}(:)=...
                    [environmentParameters.punishmentOutsideLine,environmentParameters.punishmentOutsideLine,environmentParameters.punishmentOutsideLine];
                
                ps{st,action}=...
                    [0.3,0.4,0.3];
                
                ns=mod(stpos+1,environmentParameters.n_drug_goals)+1 +environmentParameters.n_healthy_goals+environmentParameters.n_base_states;
                pstat=mod(stpos-1,environmentParameters.n_drug_goals)+1 +environmentParameters.n_healthy_goals+environmentParameters.n_base_states;
                nextState{st, action}=...
                    [ns,(environmentParameters.n_healthy_goals+ceil(environmentParameters.n_base_states/2)),pstat];
            else
                
                Environment.baseReward{stpos,action}(:)=...
                    [reducedPunishmentF*r1,r1, reducedPunishmentF*r1];
                
                Environment.therapyReward{stpos,action}(:)=[reducedPunishmentF*r1,r1, reducedPunishmentF*r1];
                
                reward{st,action}(:)=...
                    [environmentParameters.punishmentOutsideLine,environmentParameters.punishmentOutsideLine,environmentParameters.punishmentOutsideLine];
                
                ps{st,action}=...
                    [0.45,0.1,0.45];
                
                ns=mod(stpos+1,environmentParameters.n_drug_goals)+1 +environmentParameters.n_healthy_goals+environmentParameters.n_base_states;
                pstat=mod(stpos-1,environmentParameters.n_drug_goals)+1 +environmentParameters.n_healthy_goals+environmentParameters.n_base_states;
                nextState{st, action}=...
                    [ns,(environmentParameters.n_healthy_goals+ceil(environmentParameters.n_base_states/2)),pstat];
                
            end
            
        elseif(action==a_getDrugs)
            Environment.therapyReward{stpos,action}(:)=reducedPunishmentF*[r1,r1];
            Environment.baseReward{stpos,action}(:)...
                =reducedPunishmentF*[r1,r1];
            reward{st,action}(:)=[environmentParameters.punishmentOutsideLine,environmentParameters.punishmentOutsideLine];
            ps{st,action}=[p1,(1-p1)];
            ns=mod(stpos+1,environmentParameters.n_drug_goals)+1 +environmentParameters.n_healthy_goals+environmentParameters.n_base_states;
            nextState{st, action}=[st, ns];
        end
    end
end

for st=1:Num_States
    for action=1:Num_Actions
        p=sum(ps{st,action}(:));
        if abs(p-1)>0.00005
            display ('fail prob distribution to sum 1')
            display (p)
            display (nodenames{st})
            display (actionName{action})
            pause
        end
    end
end


%% back search model

kx=ones(Num_States,1);
for previousState=1:Num_States
    for action=1:Num_Actions
        for j=1:length(nextState{previousState, action})
            %                 previousState=previousState
            %                 action=action
            %                 j=j
            endState=nextState{previousState, action}(j);
            k=kx(endState);
            kx(endState)=k+1;
            PreviousStates{endState}(k)=previousState;
            InverseActions{endState}(k)=action;
            length (reward{previousState,action});
            r=reward{previousState,action}(j);
            InverseReward{endState}(k)=reward{previousState,action}(j);
            InversePs{endState}(k)=ps{previousState,action}(j);
            %s(gr_idx)=previousState;
            %t(gr_idx)=endState;
            %w(gr_idx)=ps{previousState,action}(j);
            %nodeLab{gr_idx}=['a_' int2str(action) '_r_' int2str(reward{previousState,action}(j))];
            %gr_idx=gr_idx+1;
        end
        
    end
end

Environment.Num_States=Num_States;
Environment.Num_Actions=Num_Actions;
Environment.actionName=actionName;
Environment.nodenames=nodenames;
Environment.reward=reward;
Environment.ps=ps;
Environment.nextState=nextState;
Environment=createInverseTransitions(Environment);

Environment.drugStates=(environmentParameters.n_healthy_goals+environmentParameters.n_base_states)+(1:environmentParameters.n_drug_goals);
Environment.goalStates=1:environmentParameters.n_healthy_goals;
Environment.drugReachabeState=environmentParameters.n_healthy_goals+(1:environmentParameters.n_base_states);
Environment.toDrugActionIdx=a_getDrugs;

%G = graph(s,t,w)

end