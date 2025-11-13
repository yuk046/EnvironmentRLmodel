function actionSim =selectActionSimUCT(currentStateSim,Model,MBParameters, Qtable_Integrated,stateActionVisitCounts)
%             w=squeeze(QTablePermMean(currentStateSim,:));
t=MBParameters.UCTK*(1+sum(stateActionVisitCounts(currentStateSim,:)));
c=sqrt(t./(1+stateActionVisitCounts(currentStateSim,:)));
%indexed=stateActionVisitCounts(currentStateSim,:)~=0;
%remaining=stateActionVisitCounts(currentStateSim,:)==0;
 w=Qtable_Integrated(currentStateSim,:)+c;
% 
% if(all(indexed==0))
%     w=zeros(size(w));
% else
%    
%     m=max(w(indexed))+1;
%     
% 
%     w(remaining)=m*ones(size(w(remaining)));
% end

[~,actionSim]=max(w+0.00000001*rand(size(w)));

end

