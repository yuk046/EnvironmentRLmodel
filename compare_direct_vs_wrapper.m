% ...existing code...
function compare_direct_vs_wrapper()
    % adjust if needed
    seed = 1234;
    maxsteps = 500;
    startState = 5;
    experimentname = 'tmp_compare';
    fileId = 9999;

    % --- Use same environmentParameters as run_batch_beta ---
    envParams = struct(...
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
        'minFactor',0.001);

    Environment = CreateEnvironmentMultiStepDeterministic7(envParams);

    % --- add parameter templates required by Episode_WithReset_And_Statistics ---
    MFTemplate = struct('alpha',0.1,'gamma',0.9,'lambda',0.9,'explorationFactor',0.1,...
        'SelectAction','DYNA','randExpl',true,'softMax',false,'softMax_t',1,'changeLearningFactorWithCounts',false,'updateQTablePerm',0,'useKTD',false);

    MBTemplate = struct('alpha',0.1,'StoppingPathThreshMB',1e-6,'computePolicyWithDP',0,'stoppingThreshMB',20,'StoppingPathLengthMB',12,'useTrace',false,'MaxItrMB',200,'softMax_t',1,'MaxTotalSimSteps',50,'StopSimMB',5,'knownTransitions',0,'pStopPath',0.05,'stopOnUncertaintyVal',1,'sigma_square_noise_external',1e-6,'noiseVal',1e-6,'mixMFMBPolicies',true,'UseMFToBoothMBFinalVAl',false,'mf_factor',0.5,'mb_factor',0.5,'noiceVar',1e-6,'runInternalSimulation',0,'updateModel',0,'useMFToDriveMB',false,'computeStatistics',false,'modelLearningFactor',1,'periodToComputeStatistics',50,'SelectAction','UCT','statisticsStepsPerState',50,'MBMethod','DPBound','modelDecay',0.01,'UCTK',5,'greedy',false,'mixmode','+','softMaxMix',false);

    MBReplayTemplate = struct('sigma_square_noise_external',1e-6,'noiseVal',1e-6,'P_starting_point_high_R',1,'P_starting_point_Low_R',0.5,'P_starting_point_recent_change',0.1,'restart_sweep_Prob',0.3,'sweeps',4,'sweepsDepth',4,'stepsTotal',8,'P_update_After_Reward',2,'internalReplay',0);

    % minimal inputVals fields expected by Episode_WithReset_And_Statistics
    % populate inputVals with the common fields used by RunExperimentLearning96
    % (copied from run_batch_beta to match defaults)
    inputVals.maxsteps = maxsteps;
    inputVals.initDrugStartSteps = 50;
    inputVals.therapyStartSteps = 1000;
    inputVals.therapyEndSteps = inputVals.therapyStartSteps + 1000;
    inputVals.simulatedTherapy = false;
    inputVals.resetModelFactor = 0.99;
    inputVals.resetPolicyFactor = 0.99;
    inputVals.Environment = Environment;
    inputVals.start = startState;

    % MF / MB parameters for direct episode call
    MFParameters = MFTemplate;
    MBParameters = MBTemplate; MBParameters.mb_factor = 0.5; MBParameters.mf_factor = 0.5;
    MBReplayParameters = MBReplayTemplate; MBReplayParameters.internalReplay = 0;

    inputVals.parametersMF = MFParameters;
    inputVals.parametersMBFW = MBParameters;    % forward/MB planning params
    inputVals.parametersMBBW = MBReplayParameters; % internal replay params expected by Episode
    inputVals.mf_factor = MBParameters.mf_factor;
    inputVals.mb_factor = MBParameters.mb_factor;
    inputVals.therapyModelLF = 2;   % small defaults used in run_batch_beta
    inputVals.therapyMFLFF = 1;
    inputVals.experimentname = experimentname;
    inputVals.method = 'MF+MB';

    % Direct call
    rng(seed);
    try
        R_direct = Episode_WithReset_And_Statistics(inputVals);
    catch ME
        error('Direct Episode call failed: %s', ME.message);
    end

    % Wrapper call (RunExperimentLearning96) -- run in a clean tmp experiment folder
    baseDataDir = fullfile(pwd, experimentname, 'data');
    if ~exist(baseDataDir,'dir')
        mkdir(baseDataDir);
    end

    rng(seed);
    try
        evalc('RunExperimentLearning96(maxsteps, experimentname, ''MF+MB'', ''Display'', false, ''fileId'', fileId);');
    catch ME
        error('RunExperimentLearning96 failed: %s', ME.message);
    end

    % find produced last_states.mat under tmp folder (recursive search)
    files = dir(fullfile(baseDataDir, '**', 'last_states.mat'));
    if isempty(files)
        error('no last_states.mat found under %s', baseDataDir);
    end
    % pick the newest
    [~, idx] = max([files.datenum]);
    S = load(fullfile(files(idx).folder, files(idx).name));
    if isfield(S,'last_states')
        R_wrap.last_states = S.last_states;
    else
        error('loaded file has no last_states variable');
    end

    % compare
    same = isequaln(R_direct.last_states, R_wrap.last_states);
    fprintf('Direct vs wrapper identical last_states: %d\n', same);
    if ~same
        a = R_direct.last_states(:);
        b = R_wrap.last_states(:);
        n = min(numel(a), numel(b));
        k = find(a(1:n) ~= b(1:n),1);
        if isempty(k)
            fprintf('Lengths differ: direct=%d wrapper=%d\n', numel(a), numel(b));
        else
            fprintf('First mismatch at index %d: direct=%d wrapper=%d\n', k, a(k), b(k));
        end
    end

    % cleanup optional: remove tmp folders if desired
    % rmdir(fullfile(pwd,experimentname),'s');
end
% ...existing code...