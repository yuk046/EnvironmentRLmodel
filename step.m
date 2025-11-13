function [reward,action, new_state,maxK,maxVar,dreward,MA_noise_n,maxdiffQp,...
    meanQp,QTablePermOut,stateActionVisitCountsRealOut,reset,...
    stateActionVisitCountsInternalSimulationsOut,ModelOut,...
    stateActionVisitCountsInternalReplayOut] =....
    step(...
    internalReplay,...
    runInternalSimulationflag,...
    updateModelFlag,...
    updateQTablePermFlag,...
    internalReplayFlag,...
    currentState,...
    ModelIn,...
    Environment,...
    QTablePermIn,...
    stateActionVisitCountsInternalSimulationsIn,...
    reset,...
    parametersMF,...
    parametersMBFW,...
    parametersMBBW,...                             % 追加: MBBW パラメータを受け取る
    stateActionVisitCountsRealIn,...
    stateActionVisitCountsInternalReplayIn)

% Defensive check: ensure caller provided exactly 16 input arguments
narginchk(16,16);

stateActionVisitCountsInternalSimulationsOut=stateActionVisitCountsInternalSimulationsIn;
stateActionVisitCountsRealOut=stateActionVisitCountsRealIn;
stateActionVisitCountsInternalReplayOut=stateActionVisitCountsInternalReplayIn;
maxdiffQp=0;
meanQp=0;
maxK=0;
maxVar=0;
dreward=0;
MA_noise_n=0;

ModelOut=ModelIn;
QTablePermOut=QTablePermIn;


if runInternalSimulationflag && (parametersMBFW.mb_factor>0)
    %          display('parametersMBFW.runInternalSimulation')
    if strcmp(parametersMBFW.MBMethod,'trace')
        %
        [QTablePermOutIntSim,~,stateActionVisitCountsInternalSimulationsOut]=...
            runInternalEleTraceSimulationInResetAndStatistics(QTablePermOut,currentState,ModelOut,parametersMBFW,stateActionVisitCountsInternalSimulationsOut);
    elseif strcmp(parametersMBFW.MBMethod,'DPBest')
        QTablePermOutIntSim=QTablePermOut;
        QTablePermOutIntSim.mean = DP(   parametersMBFW,ExtractCompleteModel(ModelOut));
        
    elseif strcmp(parametersMBFW.MBMethod,'DPBound')
        QTablePermOutIntSim=QTablePermOut;
        QTablePermOutIntSim.mean = DPBounded(   parametersMBFW,ExtractCompleteModel(ModelOut));
        
    else
        [QTablePermOutIntSim,~,stateActionVisitCountsInternalSimulationsOut]=...
            runInternalSimulationInResetAndStatistics(QTablePermOut,currentState,ModelOut,parametersMBFW,stateActionVisitCountsInternalSimulationsOut);
    end
    %         display('QTablePermOutIntSim')
    %         display(QTablePermOutIntSim.mean)
    %         display('QTablePermOut')
    %         display(QTablePermOut.mean)
    %         pause
    
    
    reset=0;
    if (parametersMBFW.mixMFMBPolicies )
        QtableSelect=QTablePermOut;
        %         maxsim(maxstep)=max(QTablePermOutIntSim.mean(currentState,:))
        %         maxMF(maxstep)=max(QTablePermOut.mean(currentState,:))
        %         mfwin=mfwin+ (maxsim(maxstep)<=maxMF(maxstep))
        mbf=parametersMBFW.mb_factor;
        simQ=QTablePermOutIntSim.mean;
        mff=parametersMBFW.mf_factor;
        QLQ=QTablePermOut.mean;
        dQ=simQ-QLQ;
        if (parametersMBFW.softMaxMix)
            action=actionSelectionSoftMaxMixing(currentState,parametersMBFW, simQ,QLQ,mbf,mff);
        else
            
            selQ=mbf*simQ+mff*QLQ;
            QtableSelect.mean=selQ;
            %         if(~any(simQ(:)~=0))
            %             mbfail=mbfail+1
            %         end
            action=actionSelection(currentState,ModelOut,parametersMF, QtableSelect,stateActionVisitCountsRealOut);
        end
        
    else
        QTablePermOut.mean=parametersMBFW.mb_factor*QTablePermOutIntSim.mean+parametersMBFW.mf_factor*QTablePermOut.mean;
        action=actionSelection(currentState,ModelOut,parametersMF, QTablePermOut,stateActionVisitCountsRealOut);
    end
else action=actionSelection(currentState,ModelOut,parametersMF, QTablePermOut,stateActionVisitCountsRealOut);
end




%Qtable_Integrated=QTablePerm;
%select action a




%Qtable_Integrated=QTablePerm;
%select action a
%action=actionSelection(currentState,ModelOut,parametersMF, QTablePermOut,stateActionVisitCountsRealOut);

stateActionVisitCountsRealOut(currentState,action)=stateActionVisitCountsRealOut(currentState,action)+1;

%do the selected action and get the next car state
[reward, new_state]  = DoAction( action , currentState, Environment );

%QTablePermOut=Qtable_Integrated;

if updateModelFlag
    %     display('parametersMBFW.updateModel')
    decay=0.999;
    ModelOut=updateModel(reward, new_state,action , currentState,ModelOut,parametersMBFW.modelDecay,parametersMBFW.knownTransitions,parametersMBFW.modelLearningFactor);
    
end
%display('actualInteraction')

if updateQTablePermFlag
    %     display('parametersMF.updateQTablePerm')
    [QTablePermOut,maxK,maxVar,dreward,MA_noise_n]=updateQTablePerm(QTablePermOut, reward, new_state, action , currentState, stateActionVisitCountsRealOut, parametersMF,reset);
    
    reset=0;
end

if internalReplayFlag
    %  display('parametersMBBW.internalReplay')
    % ----- [QTablePermOut,maxdiffQp,meanQp,stateActionVisitCountsInternalReplayOut]=internalReplay(QTablePermOut,ModelOut,parametersMBBW,stateActionVisitCountsInternalReplayOut,reset);
    try
        % internalReplay is also used as a variable name in this scope; use feval to ensure we call the function on path
        [QTablePermOut,maxdiffQp,meanQp]=feval('internalReplay',QTablePermOut,ModelOut,parametersMBBW,stateActionVisitCountsInternalReplayOut,reset);
    catch ME
        fprintf('--- Error while calling internalReplay ---\n');
        try
            fprintf('internalReplay resolved to: %s\n', which('internalReplay'));
        catch
            fprintf('which(internalReplay) failed\n');
        end
        try
            fprintf('nargout(''internalReplay'') = %d\n', nargout('internalReplay'));
        catch
            fprintf('nargout(internalReplay) failed\n');
        end
        try
            fprintf('Input variable classes: QTablePermOut=%s, ModelOut=%s, parametersMBBW=%s, stateActionVisitCountsInternalReplayOut=%s, reset=%s\n', ...
                class(QTablePermOut), class(ModelOut), class(parametersMBBW), class(stateActionVisitCountsInternalReplayOut), class(reset));
        catch
            fprintf('Failed to print input variable classes\n');
        end
        rethrow(ME);
    end
    reset=0;
end


end