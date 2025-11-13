% plot_addiction_vs_beta.m
% Create a plot of percentage of agents developing addiction vs MF/MB balance beta
% Usage:
% 1) If you have precomputed .mat files with addiction fractions per run, place them in a folder
%    `./data/` with names `results_beta_0.mat`, `results_beta_0_2.mat`, etc. Each file should
%    contain a vector named `percentAddicted` with length = number of runs (values in 0..100).
% 2) Alternatively, set mode='demo' below to generate a demo plot with synthetic data.
%
% The script computes mean and SEM across runs and plots mean +/- SEM as a shaded band.

clearvars; close all;

% --- Configuration ---
betas = [0 0.2 0.4 0.6 0.8 1.0];
mode = 'fromFiles'; % 'fromFiles' or 'demo'
dataDir = fullfile(pwd,'data'); % folder where results files are stored
numAgents = 25; % used for title/label only
numRunsExpected = 75; % used for guidance only

% Pre-allocate results matrix: rows=runs, cols=betas (we will allow different run counts per beta)
allPerc = cell(1,numel(betas));

if strcmp(mode,'fromFiles')
    fprintf('Loading data from %s ...\n', dataDir);
    for i=1:numel(betas)
        b = betas(i);
        % try multiple filename styles: e.g. results_beta_0.mat, results_beta_0_2.mat
        fname1 = fullfile(dataDir, sprintf('results_beta_%g.mat', b));
        % replace decimal point with underscore for filenames like 0_2
        bstr = strrep(num2str(b),'.','_');
        fname2 = fullfile(dataDir, sprintf('results_beta_%s.mat', bstr));
        loaded = false;
        for fname = {fname1, fname2}
            fname = fname{1};
            if exist(fname,'file')
                try
                    S = load(fname);
                catch
                    warning('Failed to load %s', fname); continue;
                end
                % Expecting variable 'percentAddicted' (vector in 0..100)
                if isfield(S,'percentAddicted')
                    v = S.percentAddicted;
                elseif isfield(S,'percent_addicted')
                    v = S.percent_addicted;
                elseif isfield(S,'results') && isfield(S.results,'percentAddicted')
                    v = S.results.percentAddicted;
                else
                    % try to infer from common variables: e.g. last_reward, last_states
                    warning('File %s did not contain `percentAddicted` variable. Skipping.', fname);
                    continue;
                end
                allPerc{i} = v(:);
                fprintf('Loaded %s (n=%d)\n', fname, numel(v));
                loaded = true;
                break;
            end
        end
        if ~loaded
            warning('No data file found for beta=%g. Set mode=''demo'' or provide files named results_beta_<v>.mat in %s', b, dataDir);
        end
    end
elseif strcmp(mode,'demo')
    rng(0);
    for i=1:numel(betas)
        % synthetic shape: higher MB (beta=1) reduces addiction in some curve
        b = betas(i);
        % craft mean roughly like the example figure: U-shape with minimum near 0.4
        mu = 45 - 25*exp(-((b-0.4)/0.25).^2); % peak at left, min near 0.4
        sigma = 4 + 6*(1-abs(b-0.4));
        n = numRunsExpected;
        v = mu + sigma.*randn(n,1);
        v = max(0,min(100,v));
        allPerc{i} = v;
    end
else
    error('Unknown mode: %s', mode);
end

% Filter out empty entries and compute statistics
means = zeros(1,numel(betas));
sems = zeros(1,numel(betas));
ns = zeros(1,numel(betas));
for i=1:numel(betas)
    v = allPerc{i};
    if isempty(v)
        means(i) = NaN; sems(i) = NaN; ns(i)=0; continue;
    end
    ns(i) = numel(v);
    means(i) = mean(v);
    sems(i) = std(v)./sqrt(ns(i));
end

% Plot
figure('Color','w','Position',[200 200 520 480]); hold on;
% shaded area
x = betas;
y = means;
ci_upper = means + sems;
ci_lower = means - sems;
% remove NaNs for patch
valid = ~isnan(ci_upper) & ~isnan(ci_lower);
if any(valid)
    xv = [x(valid), fliplr(x(valid))];
    yv = [ci_upper(valid), fliplr(ci_lower(valid))];
    hp = patch(xv,yv, [0.2 0.7 0.3], 'FaceAlpha',0.15,'EdgeColor','none');
end
% mean line
hline = plot(x,y,'-','Color',[0 0.6 0.2],'LineWidth',2.5);
% markers
plot(x,y,'o','MarkerFaceColor',[0 0.7 0.3],'MarkerEdgeColor','k','MarkerSize',7);

% Formatting
xlabel('Phenotype dominance: model-free (left) – model-based (right)');
ylabel(sprintf('Percentage of agents developing addiction (%%)\n(%d agents, %d runs)', numAgents, max(ns)));
xticks = betas;
set(gca,'XTick',xticks);
xlim([min(betas)-0.05 max(betas)+0.05]);
ylim([0 60]);
grid on;
box on;
set(gca,'FontSize',12);

% Add asterisks at left-most and right-most points like example
if ~isnan(y(1))
    text(x(1), y(1)-8, '*','FontSize',18,'HorizontalAlignment','center');
end
if ~isnan(y(end))
    text(x(end), y(end)-8, '*','FontSize',18,'HorizontalAlignment','center');
end

title('Addiction prevalence vs MF/MB balance');

% Save figure (optional)
% saveas(gcf, 'addiction_vs_beta.png');

fprintf('\nDone. To use real data, set mode = ''fromFiles'' and place files named results_beta_<value>.mat in %s.\n', dataDir);

% End of script
