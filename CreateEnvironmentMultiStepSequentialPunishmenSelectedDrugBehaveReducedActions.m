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

function [Environment]  = CreateEnvironmentMultiStepSequentialPunishmenSelectedDrugBehaveReducedActions(environmentParameters)
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
            reward{st,action}=[0 r*ones(1,environmentParameters.n_base_states)];
            ps{st,action}(:)=[(1-environmentParameters.p_GetRewardGoals),environmentParameters.p_GetRewardGoals*ones(1,environmentParameters.n_base_states)/environmentParameters.n_base_states];
            nextState{st,action}(:)=[st, 1+(1:environmentParameters.n_base_states)];
            
        else
            reward{st,action}=[0 ];
            ps{st,action}=[1];
            nextState{st,action}=[st];
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
            reward{st,action}=[0,0];
            
            if(id==1)
                pid=environmentParameters.p_GetRewardGoals;
                
                
            else
                pid=0.001*environmentParameters.p_GetRewardGoals;
            end
            
            ps{st,action}=[pid,(1-pid)];
            
            nextState{st, action}=[action, st];
        elseif (action<=environmentParameters.n_healthy_goals+environmentParameters.n_base_states)
            actionName{action}=strcat('a-toState-',num2str(action));
            
            if abs(st-action)<=1
                p=0.9;
                reward{st,action}=[0 0];
            else
                p=0.0001;
                reward{st,action}=[0 -environmentParameters.punishmentOutsideLine];
            end
            %p=min(0.9(abs(st-action)/environmentParameters.n_base_states).^6,1);
            
            ps{st,action}=[1-p, p];
            nextState{st, action}=[st,action];
        elseif action==(a_stay)
            
            reward{st,action}=[0];
            ps{st,action}=[1];
            nextState{st, action}=[st];
            
        else if action==(a_getDrugs)%action_get_drugs
                if (st==(environmentParameters.n_healthy_goals+environmentParameters.n_base_states))
                    p=0.9;
                else
                    p=0.0001;
                    
                end
                id=st-environmentParameters.n_healthy_goals;
                Environment.baseRewardBaseState{id,1}=environmentParameters.rew_DG*...
                    [((ones(1,environmentParameters.n_drug_goals))./(((1/environmentParameters.escaLation_factor_DG)*ones(1,environmentParameters.n_drug_goals)).^(1:environmentParameters.n_drug_goals))),  0];
                
                Environment.therapyRewardBaseState{id,1}=Environment.baseRewardBaseState{id,1}*0;
                
                reward{st,action}=Environment.baseRewardBaseState{id,1};
                
                
                ps{st,action}(1:environmentParameters.n_drug_goals)=...
                    ones(1,environmentParameters.n_drug_goals)./...
                    (((1/environmentParameters.escaLation_factor_DG)*...
                    ones(1,environmentParameters.n_drug_goals)).^...
                    (1:environmentParameters.n_drug_goals));
                summa=sum(ps{st,action}(1:environmentParameters.n_drug_goals));
                ps{st,action}(1:environmentParameters.n_drug_goals)=ps{st,action}(1:environmentParameters.n_drug_goals)/summa*p;
                ps{st,action}(1+environmentParameters.n_drug_goals)=1-p;
                
                nextState{st, action}=[(environmentParameters.n_healthy_goals+environmentParameters.n_base_states+(1:environmentParameters.n_drug_goals)), st];
            end
        end
    end
end

%% set drug states
for st= (environmentParameters.n_healthy_goals+environmentParameters.n_base_states)+(1:environmentParameters.n_drug_goals)
    nodenames{st}=['drug-', int2str(st)];
    stpos=(st-environmentParameters.n_healthy_goals-environmentParameters.n_base_states);
    r1=environmentParameters.pun_DG*environmentParameters.escaLation_factor_DG^(environmentParameters.n_drug_goals-stpos);
    p1=environmentParameters.pDG*environmentParameters.escaLation_factor_DG^(environmentParameters.n_drug_goals-stpos);
    for action=1:Num_Actions
        if(action<=environmentParameters.n_healthy_goals+environmentParameters.n_base_states)
            Environment.baseReward{stpos,action}=[r1];
            Environment.therapyReward{stpos,action}=Environment.baseReward{stpos,action};
            reward{st,action}=[r1];
            ps{st,action}=[1];
            nextState{st, action}=[st];
        elseif(action==a_stay)
            Environment.baseReward{stpos,action}(:)=[r1,r1]
            reward{st,action}(:)=Environment.baseReward{stpos,action}(:)
            Environment.therapyReward{stpos,action}(:)=Environment.baseReward{stpos,action}(:)
            ps{st,action}=[p1,1-p1];
            nextState{st, action}=[st,(environmentParameters.n_healthy_goals+randi(environmentParameters.n_base_states))];
        elseif(action==a_getDrugs)
            if (environmentParameters.autoGen==1)
                onesvector=ones(1,environmentParameters.n_drug_goals-stpos+1);
                Environment.baseReward{stpos,action}(:)...
                    =[environmentParameters.rew_DG*...
                    ((onesvector)./(((1/environmentParameters.escaLation_factor_DG)*onesvector).^(stpos-1+(1:environmentParameters.n_drug_goals-stpos+1)))),...
                    r1];
                reward{st,action}(:)=Environment.baseReward{stpos,action}(:);
                Environment.therapyReward{stpos,action}(:)=r1*ones(size(Environment.baseReward{stpos,action}(:)));
                vint=onesvector./(((1/environmentParameters.escaLation_factor_DG)...
                    *onesvector).^(stpos-1+(1:environmentParameters.n_drug_goals-stpos+1)));
                ps{st,action}(:)=[...
                    vint,...
                    (1-p1)];
                
                sumpsaction=sum(ps{st,action}(:));
                
                ps{st,action}(:)=ps{st,action}(:)/sumpsaction;
            else
                reward{st,action}=environmentParameters.rew_DGV;
                ps{st,action}=environmentParameters.pDGV;
            end
            nextState{st, action}=[(environmentParameters.n_healthy_goals+environmentParameters.n_base_states)+(stpos:environmentParameters.n_drug_goals), st];
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
Environment.drugReachabeState=(environmentParameters.n_healthy_goals+1):(environmentParameters.n_healthy_goals+environmentParameters.n_base_states);
Environment.toDrugActionIdx=a_getDrugs;

%G = graph(s,t,w)

end