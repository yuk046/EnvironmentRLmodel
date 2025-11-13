%  MBReplayParameters = struct(...
%                             P_starting_point_high_R,VP_starting_point_high_R,...
%                             P_starting_point_Low_R,VP_starting_point_Low_R,...
%                             P_starting_point_recent_change,VP_starting_point_recent_change,...
%                             alpha_MF_MBRep,Valpha_MF_MBRep,...
%                             gamma_MF_MBRep,Vgamma_MF_MBRep,...
%                             lambda_MF_MBRep,Vlambda_MF_MBRep,...
%                             frequency,vfrequency,...
%                             sweeps,NSweeps,...
%                             P_update_After_Reward,VP_update_After_Reward,...
%                             sigma_square_noise_external,VSigma_square_noise_external,...
%                             noiseVal,VNoiseVal);


function goalState=selectEndState(QTablePerm,Model,BReplayParameters)
Vt=max(QTablePerm.mean,[],2);
meanV=mean(Vt);

% QTablePerm.GoalUpdateScore=...%(1-QTablePerm.time)*...
%     ((Vt>meanV).*(Vt-meanV)*BReplayParameters.P_starting_point_high_R+...
%     (Vt<=meanV).*(meanV-Vt)*BReplayParameters.P_starting_point_Low_R);
r=zeros(Model.Num_States,Model.Num_Actions);

rs=zeros(Model.Num_States,1);

d=rs;




for st=1:Model.Num_States
    
    for act = 1:Model.Num_Actions
       
        if ~(isempty(Model.ps{st,act})||isempty(Model.reward{st,act}))
            try
                r(st,act)=sum((Model.reward{st,act}).* (Model.ps{st,act}));
            catch excep
                Model.reward{st,act}
                Model.ps{st,act}
                rtst(:)=(Model.reward{st,act}(:))
                rps(:)=(Model.ps{st,act}(:))
                throw(excep)
                r(st,act)=0;
            end
        else
            r(st,act)=0;
        end
    end
end

rs=max(r,[],2);






%Maximumr=max(r{st,act});
%minimuR=min(r{st,act});

meanR=mean(rs);

d1(:)=(rs(:)-meanR);
d=((d1>0).*d1)*BReplayParameters.P_starting_point_high_R+...
    ((d1<0).*(-d1))*BReplayParameters.P_starting_point_Low_R;



%maxR=max(Model.rewards,
%QTablePerm.GoalUpdateScore=QTablePerm.GoalUpdateScore./sum(QTablePerm.GoalUpdateScore);
%W=QTablePerm.GoalUpdateScore./sum(QTablePerm.GoalUpdateScore);
%m=max(abs(W));
%if m== 0 || isnan(m)
goalState=randsample(Model.Num_States,1,true,d+1);
%else
%goalState=randsample(Model.Num_States,1,true,W);
%end
%    goalState=randsample(Model.Num_States,1);%,true,QTablePerm.GoalUpdateScore./sum(QTablePerm.GoalUpdateScore));
end
