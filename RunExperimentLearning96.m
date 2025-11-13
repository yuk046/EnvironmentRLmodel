function  RunExperimentLearning96( maxepisodes,experimentname,varargin)
%RunExperiments, the main function of the experiment
%maxepisodes: maximum number of episodes to run the experiment

parser = inputParser;
defaultMethod='QLearning';
expectedMethods= {'QLearning','DP','KTD','MF+MB','FWBW_NoLearning','FW_NoLearning','Q_FW','random','optimal'};


addRequired(parser,'maxepisodes',@isnumeric);
addRequired(parser,'experimentname',@isstr);
addOptional(parser,'method',defaultMethod,...
    @(x) any(validatestring(x,expectedMethods)));

addOptional(parser,'Display',false);
addOptional(parser,'useBayesianValueFunction',false);

addOptional(parser,'fileId',0,@isnumeric);

parse(parser,maxepisodes,experimentname,varargin{:});

method=parser.Results.method;

fileId=parser.Results.fileId;
if(strcmp(method,'MF+MB'))
    [balanceFac, alphaMF, alphaMB, therapymethod]=ind2sub([4,2,2,3],(mod(fileId,4*4*3)+1));
    %balanceFac=balanceFac
    alphaMF=0.1;
    alphaMB=0.2;
    mfFactor=0.5;
    mbFactor=0.5;
    % Create a genotype string for MF+MB experiments
    GenotypeStr=strcat('MFMB_mf',num2str(mfFactor),'_mb',num2str(mbFactor),'_AMF',num2str(alphaMF),'_AMB',num2str(alphaMB));
elseif (strcmp(method,'QLearning'))
    [alphaMF1, temp1]=ind2sub([10,3],(mod(fileId,30)+1));
    mfFactor=1;
    mbFactor=0;
    alphaMF=power(0.5,alphaMF1/2);
    softmaxft=2/(2+temp1);
    alphaMB=0.2;
    GenotypeStr=strcat('MF_T',num2str(softmaxft),'_AMF',num2str(alphaMF));
    balanceFac=1;
    therapymethod=1;
else
    %UCTKs=[0.001 0.01];
    %UCTKs=[0.1 1 5 10];
    MBFs=[0 0.05 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.95 1.0];
    alphaMFs=[0.01 0.05 0.1];
    MTSSS=[ 50 75];
    %[genotype1,UCTKidx]=ind2sub([length(MBFs),length(alphaMFs)],(mod(fileId,length(MBFs)*length(UCTKs))+1));
    %[mbFactorF,alphaMFF,therapymethod]=ind2sub([4,3,3],(mod(fileId,4*3*3)+1));
    [mbFactorIDX,alphaMFIDX,therapymethod]=ind2sub([length(MBFs),length(alphaMFs),3],(mod(fileId,length(MBFs)*length(alphaMFs)*3)+1));
    
    
    balanceFac=1;
    softmaxft=0.5;
    MFEF=0.1;
    alphaMB=0.1;
    UCTK=5;%UCTKs(UCTKidx);
    %alphaMFIDX=4;
    MaxTotalSimSteps=50;%MTSSS(alphaMFIDX);%500+250*maxsteps;
    mbsoftmaxft=1;%* (temp1*temp1)/9;
    
    
    mbFactor=MBFs(mbFactorIDX);
    alphaMF=alphaMFs(alphaMFIDX);
    

    mfFactor=min(max(1-mbFactor,0),1);
    
    GenotypeStr=strcat('MBF',num2str(mbFactor),'_AMF',num2str(alphaMF));
    %     ?alphaMB=0;%1/10;
end

if therapymethod == 1
    resetModelFactor=0.99;
    resetPolicyFactor=0.99;
    therapyModeLF=2;
    therapyMFLFF=1;
        
    tpy='TPY-BAL';
elseif therapymethod==2
    resetModelFactor=0.99;
    resetPolicyFactor=0.99*0.8;
    therapyModeLF=2;
    therapyMFLFF=0.01;
    
    tpy='TPY-Cog';
elseif therapymethod==3
    resetModelFactor=0.99*0.8;
    resetPolicyFactor=0.99;
    therapyModeLF=0.1;
    therapyMFLFF=1;
    
    tpy='TPY-Bhv';
end



useBayesianValueFunction=parser.Results.useBayesianValueFunction;

parser.Results

clc
start       = 5;

environmentParameters=struct(...
    'punishmentOutsideLine',-0.3,...
    'sides',[4,4],...
    'n_healthy_goals',1,...
    'rew_Goals',[1],...
    'p_GetRewardGoals',0.5,...
    'p_GetRewardDrug',0.5,...
    'n_drug_goals',15,...
    'rew_DG',10,...
    'rew_DGV',[1,0.5],...
    'pun_DG',-4,...
    'pun_DGV',[-0.5,-0.75],...
    'pDG',[0.75],...
    'pDGV',[0.5,0.25],...
    'escaLation_factor_DG',0.5,...
    'n_base_states',6,...
    'deterministic',false,...
    'autoGen',1,...
    'reducedPunishmentF',0.3,...
    'minFactor',0.001); %#ok<NBRAK>

Environment=CreateEnvironmentMultiStepDeterministic7(environmentParameters);

displayEnvironment(Environment);






%Model       = BuildModel(Environments ); % the Qtable


maxsteps    = 2600;  % maximum number of steps per episode

initDrugStartSteps=50;%maxsteps/200;
therapyStartSteps=1000;ceil(maxsteps/2);
therapyEndSteps=therapyStartSteps+1000;%ceil(6*maxsteps/10);
simulatedTherapy=false;


%alpha       = 0.1;   % learning rate
gamma       = 0.9;  % discount factor
lambda=.9;
epsilon     = 0.1;   % probability of a random action selection

maxInternalNoise=parser.Results.maxepisodes;
plot_graphs=true;

%追加した
if ~exist('mbsoftmaxft','var'), mbsoftmaxft = 1; end
if ~exist('MFEF','var'),         MFEF = 0.1; end
if ~exist('UCTK','var'),         UCTK = 5; end
if ~exist('MaxTotalSimSteps','var'), MaxTotalSimSteps = 50; end


MFParameters=struct(...
    'alpha',alphaMF,...
    'gamma',gamma,...%gamma,...
    'lambda',lambda,...
    'explorationFactor',MFEF,...
    'SelectAction','DYNA',...
    'randExpl',true,...
    'softMax',false,...
    'softMax_t',1,...
    'changeLearningFactorWithCounts',false,...
    'updateQTablePerm',0,...
    'useKTD',useBayesianValueFunction);

MBParameters=struct('alpha',alphaMB,...
    'StoppingPathThreshMB',1e-6,...
    'computePolicyWithDP',0,...
    'stoppingThreshMB',20,...
    'StoppingPathLengthMB',12,...
    'useTrace',false,...
    'MaxItrMB',200,...
    'softMax_t',mbsoftmaxft,...
    'MaxTotalSimSteps',MaxTotalSimSteps,...
    'StopSimMB',5,...
    'knownTransitions',0,...
    'pStopPath',0.05,...
    'stopOnUncertaintyVal',1,...
    'sigma_square_noise_external',0.000001,...
    'noiseVal',0.000001,...
    'mixMFMBPolicies',true,...
    'UseMFToBoothMBFinalVAl',false,...
    'mf_factor',mfFactor,...
    'mb_factor',mbFactor,...
    'noiceVar',0.000001,...
    'runInternalSimulation',0,...
    'updateModel',0,...
    'useMFToDriveMB',false,...
    'computeStatistics',false,...
    'modelLearningFactor',1,...
    'periodToComputeStatistics',50,...
    'SelectAction','UCT',...
    'statisticsStepsPerState',50, ...
    'MBMethod','DPBound',...
    'modelDecay',0.01,...
    'UCTK',UCTK, ...
    'greedy',false, ...
    'mixmode','+',...
    'softMaxMix',false ...
    );
%%

MBReplayParameters = struct(...
    'sigma_square_noise_external',MBParameters.sigma_square_noise_external,...
    'noiseVal',MBParameters.noiseVal,...
    'P_starting_point_high_R',balanceFac,...
    'P_starting_point_Low_R',0.5,...
    'P_starting_point_recent_change',0.1,...
    'restart_sweep_Prob',0.3,... %'frequency',2,...
    'sweeps',4,...
    'sweepsDepth',4,...
    'stepsTotal',8,...
    'P_update_After_Reward',2,....
    'internalReplay',0);

if strcmp(method,'QLearning')
    MFParameters.updateQTablePerm=1;
elseif strcmp(method,'MF+MB')
    MFParameters.updateQTablePerm=1;
    MBParameters.runInternalSimulation=1;
    MBParameters.updateModel=1;
    MBReplayParameters.internalReplay=1;
elseif strcmp(method,'Q_FW')
    MFParameters.updateQTablePerm=1;
    MBParameters.runInternalSimulation=1;
    MBParameters.updateModel=1;
    MBReplayParameters.internalReplay=0;
elseif strcmp(method,'FWBW_NoLearning')
    MBParameters.runInternalSimulation=1;
    MBParameters.updateModel=0;
    MFParameters.updateQTablePerm=0;
    MBReplayParameters.internalReplay=1;
elseif strcmp(method,'FW_NoLearning')
    MBParameters.runInternalSimulation=1;
    MBParameters.updateModel=0;
    MFParameters.updateQTablePerm=0;
    MBReplayParameters.internalReplay=0;
elseif strcmp(method,'random')
    MBParameters.runInternalSimulation=0;
    MBParameters.updateModel=0;
    MFParameters.updateQTablePerm=0;
    MBReplayParameters.internalReplay=0;
elseif strcmp(method,'optimal')
    MBParameters.runInternalSimulation=0;
    MBParameters.updateModel=0;
    MFParameters.updateQTablePerm=0;
    MBReplayParameters.internalReplay=0;
    MBParameters.computePolicyWithDP=1;
    MFParameters.softmax=false;
    MFParameters.explorationFactor=0;
    MFParameters.randExpl=true;
end



MBParameters=setstructfields(MFParameters,MBParameters);

MBReplayParameters=setstructfields(MBParameters,MBReplayParameters);


display('MFparameters')
display(MFParameters)

display('MBFWparameters')
display(MBParameters)

display('MBBWparameters')
display(MBReplayParameters)




for internalNoiseIdx=1:maxInternalNoise
    
    %% init random generator
    currentTime=rem(now,1) %#ok<NOPRT>
    seed=(currentTime*3000000+fileId)%#ok<NOPRT> %679
    rng(seed,'twister')
    randomGeNstruct=rng(seed)  %#ok<NOPRT>
    x = rand(1,5) %#ok<NASGU,NOPRT>
    
    %% run simulation
    display('start')
    
    %     [total_reward,steps,Q,Model,last_actions,last_states,last_reward,last_Q,lastK,lastVar,lastDreward,lastMA_noise_n,last_maxD,last_meanD  ] = ...
    %         Episode_Dim_UCT_UCRL_with_reset( maxsteps, Environment,start,MBReplayParameters);
    %
    
    if  strcmp(method,'DP')
        
        %Environment=changeToTherapyReward(Environment);
        
        [~,~,~,Model,last_actions,last_states,last_reward,last_Q,~,~,~,~,~,~  ] = ...
            Episode_DP( maxsteps,Environment,start,MBParameters);
        arguments=[];
        displayQValueMean(squeeze(last_Q(maxsteps,:,:)),Environment);
        displayEnvironment(Environment);
    else
        
        inputVals.maxsteps=maxsteps;
        inputVals.initDrugStartSteps=initDrugStartSteps;
        inputVals.therapyStartSteps=therapyStartSteps;
        inputVals.therapyEndSteps=therapyEndSteps;
        inputVals.simulatedTherapy=simulatedTherapy;
        inputVals.resetModelFactor=resetModelFactor;
        inputVals.resetPolicyFactor=resetPolicyFactor;
        inputVals.Environment=Environment;
        inputVals.start=start;
        inputVals.parametersMF=MFParameters;
        inputVals.parametersMBFW=MBParameters;
        inputVals.parametersMBBW=MBReplayParameters;
        inputVals.therapyModelLF=therapyModeLF;
        inputVals.therapyMFLFF=therapyMFLFF;
        
        Results=...
            Episode_WithReset_And_Statistics(inputVals);
        last_reward=Results.last_reward;
        last_Q=Results.last_Q;
        last_states=Results.last_states;
        last_actions=Results.last_actions;
        arguments=parser.Results;
        Model=Results.Model;
        displayQValueMean(squeeze(last_Q(maxsteps,:,:)),Environment);
%         displayEnvironment(Environment);
        
    end
    
    
    display('end')
    
    
    %% store and plot results
    if (plot_graphs)
        %                 figure; plot(1:maxsteps,smooth(lastK,50));title('Max Kalman Gain');
        %                 figure;plot(1:maxsteps,smooth(lastVar,50));title('Max Q.var');
        %                 figure;plot(1:maxsteps,smooth(abs(lastDreward),50));title('Max lastDreward');
        %                 figure;plot(1:maxsteps,smooth(abs(lastMA_noise_n),50));title('Max lastMA_noise_n');
        %figure;plot(1:maxsteps,smooth(abs(last_maxD),50),'LineWidth',2);title('Max Q up');
        %figure;plot(1:maxsteps,smooth(abs(last_meanD),50),'LineWidth',2);title('Mean Q up');
        formatOut = 'yy-mm-dd-HH-MM-SS-FFF';
        if (strcmp(method,'MF+MB'))
            dirname=strcat(experimentname,'/data/',GenotypeStr,'-',tpy,'-Met-',method,'-balFac-',num2str(MBReplayParameters.P_starting_point_high_R),'-MFalpha-',num2str(MFParameters.alpha),'-MBalpha-',num2str(MBParameters.alpha),'-tpy-',num2str(therapymethod),'-drg-',num2str(environmentParameters.n_drug_goals),'/',method,'-',datestr(now,formatOut),'-',num2str(fileId));
        else
            dirname=strcat(experimentname,'/data/',GenotypeStr,'-',tpy,'-Met-',method,'-MFfactor-',num2str(MBParameters.mf_factor),'-MBfactor-',num2str(MBParameters.mb_factor),'-MFalpha-',num2str(MFParameters.alpha),'-MBalpha-',num2str(MBParameters.alpha),'-tpy-',num2str(therapymethod),'-drg-',num2str(environmentParameters.n_drug_goals),'/',method,'-',datestr(now,formatOut),'-',num2str(fileId));
        end
        
        d=pwd;
        mkdir(dirname);
        cd(dirname);
        
        % plotUpdates(maxsteps,last_maxD,last_meanD,MFParameters,internalNoiseIdx,maxInternalNoise,noise);
        save 'lastreward.mat' last_reward
        %plotReward(maxsteps,last_reward,MFParameters,internalNoiseIdx,maxInternalNoise,noise);
        save 'lastQ.mat' last_Q
        %PlotQEvolution(maxsteps,MFParameters,Environment,last_Q,internalNoiseIdx,maxInternalNoise,noise);
        save 'last_states.mat' last_states
        %plotVisits(maxsteps,last_states,Environment,MFParameters,internalNoiseIdx,maxInternalNoise,noise);
        save 'lastActions.mat' last_actions
        %plotActionSelection(MFParameters,Environment,maxsteps,last_states,last_actions,internalNoiseIdx,maxInternalNoise,noise);
        save 'Model.mat' Model
        
        save 'Environment.mat' Environment
        save 'timing.mat' maxsteps initDrugStartSteps therapyStartSteps therapyEndSteps
        
        
        qt(:,:)=last_Q(maxsteps,:,:);
        
        save 'q_final.mat' qt
        save 'arguments.mat' arguments
        save 'EnvPar.mat' environmentParameters
        save 'MBBWparameters.mat' MBReplayParameters
        save 'MBFWparameters.mat' MBParameters
        save 'MFparameters.mat' MFParameters
        save 'randomGeNstruct.mat' randomGeNstruct
        cd(d);
        
    end
    
end



end
