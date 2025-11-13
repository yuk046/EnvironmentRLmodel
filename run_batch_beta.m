% run_batch_beta.m
% Wrapper to run multiple episodes across MF/MB balance (beta) values and
% save results files results_beta_<v>.mat containing percentAddicted
%
% Usage:
%   Edit configuration below (betas, numAgents, numRuns). Then run:
%     run_batch_beta
%
% Notes:
% - This script calls `Episode_WithReset_And_Statistics(inputVals)` for each
%   agent simulation. That function comes from this project and expects an
%   `inputVals` struct similar to RunExperimentLearning96.
% - Addiction is defined here as "agent visited any drug-goal state at any
%   time during the episode". You can modify the criterion in
%   `isAgentAddicted` helper below.
% - Running many agents x runs can be slow. Consider reducing counts or
%   using parallel toolbox if available.

clearvars; close all;

% --- Configuration ---
betas = [0 0.2 0.4 0.6 0.8 1.0];
numAgents = 5;   % agents per run
numRuns = 15;     % independent runs per beta
maxsteps = 1050;   % steps per episode (EXACTLY matching RunExperimentLearning96)
startState = 4;    % initial state (EXACTLY matching RunExperimentLearning96)
initDrugStartSteps = 50;  % matching RunExperimentLearning96
therapyStartSteps = 1050;  % matching RunExperimentLearning96
therapyEndSteps = 1050;    % therapyStartSteps + 1000, matching RunExperimentLearning96
method = 'MF+MB';  % kept for filename consistency
experimentname = 'batch_beta_experiment';
% whether to print per-agent visit counts (drug vs healthy)
displayVisitCounts = true;
% If only a single state should be considered the "drug goal" for addiction
% (override). Set to [] to use Environment.drugStates (default range).
% The user requested that only state 8 be counted as the addiction goal.
specificDrugGoalState = 8;

% environment parameters (EXACTLY matching RunExperimentLearning96)
environmentParameters = struct(...
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

% Create environment once
Environment = CreateEnvironmentMultiStepDeterministic7(environmentParameters);

% Determine indices of drug-goal states in the environment (convention used in environment generator)
% According to CreateEnvironmentMultiStepSequentialPunishment, drug states are:
%   (n_healthy_goals + n_base_states) + (1:n_drug_goals)
n_healthy = environmentParameters.n_healthy_goals;
n_base = environmentParameters.n_base_states;
n_drug = environmentParameters.n_drug_goals;
drugStateStart = n_healthy + n_base + 1;
drugStates = drugStateStart:(drugStateStart + n_drug - 1);
% healthy states indices (used for visit-count based addiction criterion)
healthyStates = 1:n_healthy;

% parameter templates (EXACTLY matching RunExperimentLearning96)
gamma = 0.9;
lambda = 0.9;
epsilon = 0.1;
alphaMF = 0.1;
alphaMB = 0.2;
MFEF = 0.1;  % explorationFactor for MF
UCTK = 5;
MaxTotalSimSteps = 50;
mbsoftmaxft = 1;

% MF parameters (matching RunExperimentLearning96 line 162-176)
MFTemplate = struct('alpha',alphaMF,...
    'gamma',gamma,...
    'lambda',lambda,...
    'explorationFactor',MFEF,...
    'SelectAction','DYNA',...
    'randExpl',true,...
    'softMax',false,...
    'softMax_t',1,...
    'changeLearningFactorWithCounts',false,...
    'updateQTablePerm',0,...
    'useKTD',false);

% MB parameters (matching RunExperimentLearning96 line 178-216)
MBTemplate = struct('alpha',alphaMB,...
    'gamma',gamma,...
    'lambda',lambda,...
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
    'mf_factor',0.5,...
    'mb_factor',0.5,...
    'noiceVar',0.000001,...
    'runInternalSimulation',1,...
    'updateModel',1,...
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
    'softMaxMix',false);

% MB replay template (matching RunExperimentLearning96 line 219-230)
balanceFac = 1;  % P_starting_point_high_R default value
MBReplayTemplate = struct(...
    'sigma_square_noise_external',0.000001,...
    'noiseVal',0.000001,...
    'P_starting_point_high_R',balanceFac,...
    'P_starting_point_Low_R',0.5,...
    'P_starting_point_recent_change',0.1,...
    'restart_sweep_Prob',0.3,...
    'sweeps',4,...
    'sweepsDepth',4,...
    'stepsTotal',8,...
    'P_update_After_Reward',2,...
    'internalReplay',0);

% Random seed base (so results are repeatable if desired)
rngBase = 0;

% Helper: decide whether an agent developed addiction based on Results
% New criterion: agent is 'addicted' when the number of visits to drug-goal
% states is greater than the number of visits to healthy goal states.
function addicted = isAgentAddicted(Results, drugStates, healthyStates)
    addicted = false;
    if ~isfield(Results,'last_states') || isempty(Results.last_states)
        return
    end
    states = Results.last_states;
    drugVisits = sum(ismember(states, drugStates));
    healthyVisits = sum(ismember(states, healthyStates));
    addicted = (drugVisits > healthyVisits);
end

% Main loop
for ib = 1:numel(betas)
    beta = betas(ib);
    fprintf('\n=== Beta = %.2f (%d/%d) ===\n', beta, ib, numel(betas));
    fprintf('Configuration: beta=%.2f, numAgents=%d, numRuns=%d, maxsteps=%d\n', beta, numAgents, numRuns, maxsteps);
    % prepare per-beta log file (also ensure data dir exists)
    dataFolder = fullfile(pwd,'data');
    if ~exist(dataFolder,'dir')
        mkdir(dataFolder);
    end
    bstr = strrep(num2str(beta),'.','_');
    logfname = fullfile(dataFolder, sprintf('log_beta_%s.txt', bstr));
    fidlog = fopen(logfname,'w');
    if fidlog>0
        fprintf(fidlog,'Run batch log\nStart time: %s\n', datestr(now));
        fprintf(fidlog,'beta=%g, numAgents=%d, numRuns=%d, maxsteps=%d\n\n', beta, numAgents, numRuns, maxsteps);
        fclose(fidlog);
    end

    % set factors
    mb_factor = beta;
    mf_factor = max(0,1-beta);

    % prepare storage for percent addicted per run
    percentAddictedPerRun = zeros(numRuns,1);

    for runIdx = 1:numRuns
        % Optionally seed RNG per run for reproducibility
        rng(rngBase + runIdx + ib*1e4);

        addictedCount = 0;
        for agentIdx = 1:numAgents
            % build inputVals for this agent (EXACTLY matching RunExperimentLearning96)
            inputVals.maxsteps = maxsteps;
            inputVals.initDrugStartSteps = initDrugStartSteps;
            inputVals.therapyStartSteps = therapyStartSteps;
            inputVals.therapyEndSteps = therapyEndSteps;
            inputVals.simulatedTherapy = false;
            inputVals.resetModelFactor = 0.99;
            inputVals.resetPolicyFactor = 0.99;
            inputVals.Environment = Environment;
            inputVals.start = startState;

            % MF and MB parameters: copy templates and set factors
            MFParameters = MFTemplate;
            MBParameters = MBTemplate;
            MBParameters.mb_factor = mb_factor;
            MBParameters.mf_factor = mf_factor;

            MBReplayParameters = MBReplayTemplate;

            inputVals.parametersMF = MFParameters;
            inputVals.parametersMBFW = MBParameters;
            inputVals.parametersMBBW = MBReplayParameters;
            inputVals.therapyModelLF = 2;
            inputVals.therapyMFLFF = 1;

            % Run episode (capture verbose output to keep console/log tidy)
            % Many functions in the codebase print to stdout; use evalc to capture that
            try
                outStr = evalc('Results = Episode_WithReset_And_Statistics(inputVals);'); %#ok<NASGU>
            catch ME
                % If the episode throws, rethrow but print a short context first
                fprintf('Error in Episode_WithReset_And_Statistics at beta=%.2f run=%d agent=%d\n', beta, runIdx, agentIdx);
                rethrow(ME);
            end

            % compute per-agent visit counts (drug vs healthy)
            drugVisits = 0; healthyVisits = 0;
            if isfield(Results,'last_states') && ~isempty(Results.last_states)
                states = Results.last_states;
                % prefer environment in Results or inputVals; fall back to outer drugStates
                % allow user override: specificDrugGoalState (scalar or vector)
                if exist('specificDrugGoalState','var') && ~isempty(specificDrugGoalState)
                    envDrugStates = specificDrugGoalState;
                elseif isfield(inputVals,'Environment') && isfield(inputVals.Environment,'drugStates')
                    envDrugStates = inputVals.Environment.drugStates;
                else
                    envDrugStates = drugStates;
                end
                drugVisits = sum(ismember(states, envDrugStates));
                healthyVisits = sum(ismember(states, healthyStates));
            end
            if displayVisitCounts
                fprintf('  agent %d: drugVisits=%d, healthyVisits=%d\n', agentIdx, drugVisits, healthyVisits);
            end
            % append per-agent counts to log file if present
            if exist('logfname','var')
                fidlog = fopen(logfname,'a');
                if fidlog>0
                    fprintf(fidlog,'run=%d agent=%d drugVisits=%d healthyVisits=%d\n', runIdx, agentIdx, drugVisits, healthyVisits);
                    fclose(fidlog);
                end
            end

            % evaluate addiction (visit-count based)
            if isAgentAddicted(Results, envDrugStates, healthyStates)
                addictedCount = addictedCount + 1;
            end
        end
        percentAddictedPerRun(runIdx) = 100 * addictedCount / numAgents;
        % concise console progress every run (timestamped) and append to log file
        fprintf('[%s] beta=%.2f run %d/%d: %%addicted=%.2f\n', datestr(now,'HH:MM:SS'), beta, runIdx, numRuns, percentAddictedPerRun(runIdx));
        % append to log
        if exist('logfname','var')
            fidlog = fopen(logfname,'a');
            if fidlog>0
                fprintf(fidlog,'run=%d, percentAddicted=%.4f\n', runIdx, percentAddictedPerRun(runIdx));
                fclose(fidlog);
            end
        end
    end

    % Save results for this beta
    bstr = strrep(num2str(beta),'.','_');
    outfname = fullfile(pwd, 'data', sprintf('results_beta_%s.mat', bstr));
    if ~exist(fullfile(pwd,'data'),'dir')
        mkdir(fullfile(pwd,'data'));
    end
    percentAddicted = percentAddictedPerRun; %#ok<NASGU>
    save(outfname, 'percentAddicted');
    fprintf('Saved %s (nRuns=%d)\n', outfname, numRuns);
end

fprintf('\nAll done. Generated %d files in %s\n', numel(betas), fullfile(pwd,'data'));
