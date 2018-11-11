close all; clear variables; 

alpha = 0.8;                    % alpha
cAlpha = 0;                     % alpha used for risk constraints 
num_modes = 3;                  % number of modes of Markov chain
lambda_poisson = 2;             % Poisson parameter
zeros_trans_matr_per_line = 1;  % Number of zeros in P (Markov trans. mat.)
horizon_length = 12;            % prediction horizon
constrainedStages = horizon_length-4: horizon_length;

n_repetitions = 4;             % Number of repetitions of the timing
%% Increasing the branching horizon and recording build and optimization time

plotSpec = struct('Marker', '.', 'MarkerSize', 5, 'LineWidth', 1, 'color', 'k');
linestyle = struct('nested', '--', ... 
                   'stage', '-'); 

BUILD = false; % true: Build the controller in this run.
              % false: Load the prebuilt controllers and plot/export results. 
              
if ~BUILD; buildFig = figure; optimFig = figure; end 

for useNested = [true, false]
    useStageWise = ~useNested; 
    
    optimTimes = [];
    optimTimesVar = []; 
    numScenarios = [];
    buildTimes = [];
    
    for branching_horizon = 1:8
        filename = buildName(branching_horizon, useNested);
        if BUILD
            cacheController(filename, alpha, cAlpha, num_modes, ...
                zeros_trans_matr_per_line, ... 
                lambda_poisson, horizon_length, ...
                branching_horizon, useStageWise, useNested, constrainedStages);
        else 
            loaded = readFile(filename);
            buildTimes = [buildTimes, loaded.buildTime]; 
            
            % Solve problem
            x0 = [-0.5; -0.1];
            
            timesRepeated = []; 
            fprintf('Timing OCP solution\nIteration ');
            for i = 1:n_repetitions
                fprintf('%i ...', i);
                tic;
                solution = loaded.rao.control(x0);
                optimTime = toc;
                assert(solution.getStatusCode == 0, 'No feasible solution found');
                timesRepeated = [timesRepeated, optimTime]; 
            end
            fprintf('\n');
            optimTimes = [optimTimes, mean(timesRepeated)];
            optimTimesVar = [optimTimesVar, std(timesRepeated)]; 
            numScenarios = [numScenarios, loaded.rao.tree.getNumberOfScenarios()];
        end 
    end % branching horizon
    
    if ~BUILD
        figure(buildFig);
        plot(numScenarios, buildTimes, plotSpec); hold on;
        
        figure(optimFig);
        
if useNested
    plotSpec.linestyle = linestyle.nested;
else
    plotSpec.linestyle = linestyle.stage;
end
%         p = errorbar(numScenarios, optimTimes, optimTimesVar);
%         fieldNames = fieldnames(plotSpec);
%         for fld = 1:numel(fieldNames)
%             p.(fieldNames{fld}) = plotSpec.(fieldNames{fld});
%         end 
%         hold on;
        loglog(numScenarios, optimTimes, plotSpec); hold on; grid on;
    end     
end % Use nested versus stagewise constraints
    
if ~BUILD
    figure(buildFig);
    legend('nested risk constraints', 'stage-wise risk constraints');
    xlabel('# scenarios');
    ylabel('time to build optimizer')
    
    figure(optimFig);
    legend('nested risk constraints', 'stage-wise risk constraints', 'Location', 'northwest');
    xlabel('# scenarios');
    ylabel('runtime [s]')
    axis tight
end 

%% HELPER FUNCTIONS 

function filename = buildName(hor, nested)
if nested
    suffix = 'nest';
else
    suffix = 'stage';
end
filename = fullfile('timeVsScenarios',['branchHor', num2str(hor), '_', suffix]);
end

function loaded = readFile(localPath)
rd = which('valueAtRisk.m');
toks = strsplit(rd, 'valueAtRisk.m');
folderplayground = fullfile(toks{1},'playground','controllers');
loaded = load([folderplayground, '/', localPath, '.mat']);
end 