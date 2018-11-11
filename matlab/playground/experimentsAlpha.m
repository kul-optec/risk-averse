close all; clear variables; 

%% General settings (same for all experiments) 
num_modes = 6;                  % number of modes of Markov chain
lambda_poisson = 2;             % Poisson parameter
zeros_trans_matr_per_line = 3;  % Number of zeros in P (Markov trans. mat.)
branching_horizon = 3; 
horizon_length = 12;            % prediction horizon
constrainedStages = 2: horizon_length;

% Plot specifications 
plotSpec = struct('color', 'k', ... 
                  'linewidth', 2, ...
                  'linestyle', '-', ... 
                  'marker', '.', ... 
                  'markersize', 15);
colors = struct('mean', [0,    0,    0], ...
                'quantile', [0.63, 0.35, 0.22], ...
                'max', [0.56, 0.2,  0.18]);

BUILD = false; % true: Build the controller in this run.
              % false: Load the prebuilt controllers and plot/export results. 

quantileVal = 0.1;

%% Plot cost function w.r.t. time and alpha 

cAlpha = 0.3;
useStageWise = false; 
useNested = false;
optimalCosts = [];
              
if ~BUILD
    spatialCostFig = figure;       % 3d plot of stage costs 
    constrFig = figure;            % plot of stage constraints
    totalCostFig = figure;         % total cost fig. 
    costDistFig = figure;          % distribution of total cost
end

% alphaRange = [0, 0.5, 1];
alphaRange = linspace(0, 1, 5); 
for alpha = alphaRange
    filename = buildName(alpha, 'cost');
    if BUILD
        cacheController(filename, alpha, cAlpha, num_modes, ...
            zeros_trans_matr_per_line, ...
            lambda_poisson, horizon_length, ...
            branching_horizon, useStageWise, useNested, constrainedStages);
    else
        loaded = readFile(filename);
        
        % Solve problem
        x0 = [-1; -0.5];
        
        timesRepeated = [];
        solution = loaded.rao.control(x0);
        assert(solution.getStatusCode == 0, 'No feasible solution found');
        assert(loaded.alphaCost == alpha, '\alpha in the precomputed data is not what was expected.')
        plotData = solution.plotCostErrorBar(quantileVal, horizon_length-1);
        
        %% plot stage costs with quantiles 
        figure(spatialCostFig);
        
        plotSpec.color = colors.mean;
        alphavec = alpha * ones((plotData.N-plotData.n)+1,1);
        plot3(alphavec, ...
              plotData.n:plotData.N, ...
              plotData.average, ...
              plotSpec);
          
        plotSpec.color = colors.quantile;
%         plotSpec.linestyle = '--'; plotSpec.linewidth = 1;
        hold on;
        plot3(alphavec, ...
              plotData.n:plotData.N, ...
              plotData.quantile, ...
              plotSpec);
        plotSpec.color = colors.max; 
        
        plot3(alphavec, ...
            plotData.n:plotData.N, ...
            plotData.max, ...
            plotSpec);
        
        ylim([plotData.n-1, plotData.N+1]);
        
        optimalCosts = [optimalCosts, solution.getOptimalValue()];
        
        %% plot total cost distributions
        
        figure(costDistFig); hold on;
        distribution = solution.getDistributionTotalCost(); 
        cumulative = cumsum(distribution(:,1));
        plot(distribution(:,2), cumulative, 'linewidth', 2); %distribution(:,1));
        
    end
end % alpha

if ~BUILD
    figure(spatialCostFig);
    legend('Expected cost', ... 
           [num2str((1-quantileVal)) '-quantile'], ...
           'Worst-case cost',  ...
           'location', 'northeast');
    xlabel('\alpha');
    ylabel('stage t');
    zlabel('Stage cost');
    grid on;
    view(167,7)
    
    figure(totalCostFig);
    plot(alphaRange, optimalCosts, plotSpec);
    xlabel('\alpha');
    ylabel('Optimal cost');
    grid on;  
    
    figure(costDistFig);
    xlabel('Total cost');
    ylabel('Probability');
    grid on;
    legend(getLegendEntries(alphaRange, '\alpha'));
end

%% Plot constraint function w.r.t alpha and time 

alpha = 0.5;
useStageWise = true; 
useNested = false;

quantileVal = 0.1;

for cAlpha = linspace(0,1,5)
    filename = buildName(cAlpha, 'constraint');
    if BUILD
        cacheController(filename, alpha, cAlpha, num_modes, ...
            zeros_trans_matr_per_line, ...
            lambda_poisson, horizon_length, ...
            branching_horizon, useStageWise, useNested, constrainedStages);
    else
        loaded = readFile(filename);
        
        % Solve problem
        x0 = [0.3; 0.2];
        
        timesRepeated = [];
        solution = loaded.rao.control(x0);
        assert(solution.getStatusCode == 0, 'No feasible solution found');
        assert(loaded.alphaConstraint == cAlpha, '\alpha in the precomputed data is not what was expected.')
        
        if useStageWise
            fcn = loaded.rao.stageWiseRiskConstraints(1).constraintFcn;
            plotData = solution.plotFunctionErrorBar(fcn, quantileVal, horizon_length-1);
        elseif useNested
            fcn = loaded.rao.nestedRiskConstraints(1).constraintFcn;
            plotData = solution.plotFunctionErrorBar(fcn, quantileVal, horizon_length-1);
        end
        
        figure(constrFig);
        
        plotSpec.color = colors.mean;
        alphavec = cAlpha * ones((plotData.N-plotData.n)+1,1);
        plot3(alphavec, ...
              plotData.n:plotData.N, ...
              plotData.average, ...
              plotSpec);
          
        plotSpec.color = colors.quantile;
%         plotSpec.linestyle = '--'; plotSpec.linewidth = 1;
        hold on;
        plot3(alphavec, ...
              plotData.n:plotData.N, ...
              plotData.quantile, ...
              plotSpec);
        plotSpec.color = colors.max; 
        
        plot3(alphavec, ...
              plotData.n:plotData.N, ...
              plotData.max, ...
              plotSpec);
          
        ylim([plotData.n-1, plotData.N+1]);
    end
end % alpha

if ~BUILD
    figure(constrFig);
    legend('Expected', [num2str((1-quantileVal)) '-quantile'], 'worst-case', 'location', 'northeast');
    xlabel('\alpha');
    ylabel('stage t');
    zlabel('Constraint function');
    grid on;
    view(167,7)
end


%% HELPER FUNCTIONS 

function filename = buildName(alpha, quantity)
filename = fullfile([quantity,'VsAlpha'],['alpha', num2str(alpha*10)]);
end

function loaded = readFile(localPath)
rd = which('valueAtRisk.m');
toks = strsplit(rd, 'valueAtRisk.m');
folderplayground = fullfile(toks{1},'playground','controllers');
loaded = load([folderplayground, '/', localPath, '.mat']);
end 

function l = getLegendEntries(range, name)
l = {}; 
for i = 1:length(range)
    l = [l, {[name, '=', num2str(range(i))]}]; 
end
end 