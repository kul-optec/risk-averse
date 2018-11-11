%EXAMPLESPRESENTATION constructs a risk-averse optimal control and solves
%it. The results were used as a demonstration during a presentation.
%

close all; clear;

colors = [[0,0,0]; [0.7,0,0.2]; [0.5,0.8,0];[0,0,0.9]];
legendEntries = {}; 
h = [];
i=0;

% choose alpha
N = 10;                                         % choose horizon length
M = 4;
[tree, umin, umax, QN] = makeRiskExample(N, M); % make example tree and bounds
disp(tree);
figure(10); plot(tree);


for alpha = [0.01, 1]
    i = i + 1;
    %% Define the risk-averse optimal control problem
    pAvar = marietta.ParametricRiskFactory.createParametricAvarAlpha(alpha);
%     pEvar = marietta.ParametricRiskFactory.createParametricEvarAlpha(alpha);
    rao = marietta.RiskAverseOptimalController();
    nrmlim = 1;
    constraint = marietta.ConstraintNormState(nrmlim);
    
    umin = umin*10; umax = umax * 10;
    
    rao.setInputBounds(umin,umax)...
        .setScenarioTree(tree)...
        .setParametricRiskCost(pAvar)...
        .setTerminalCostMatrix(QN);
%         .addStageWiseRiskConstraints(constraint, pAvar, 4:N-1);
%         .addNestedRiskConstraints(constraint, pAvar, N-1);
    
    rao.makeController();
    
    %% Compute the solution for a particular x0
    x0 = [-3; 3];
    tic; solution = rao.control(x0); toc
    disp(solution);
    
    %% Proper plotting of state trajectories
    % figure(1);
    % subplot(211); solution.plotStateCoordinate(1);
    % subplot(212); solution.plotStateCoordinate(2);
    
    % %% Plot input trajectory
    % figure(2);
    % solution.plotInputCoordinate(1);
    
       
    
    figure(1+(i-1)*(2));
    solution.plotFunctionErrorBar(0.05, @colVecNorm)
    
    alphaPrint = sprintf('alpha = %1.2f', alpha);
    title(alphaPrint);
    ylabel('||x||');
    refline(0, nrmlim);
    plot([5 5],get(gca,'YLim'), 'k:');
    legend('||x||', 'max(||x||)', 'upper bound')
    xlabel('stage k');
    
    figure(2+(i-1)*2);
    subplot(211); title(alphaPrint); solution.plotStateCoordinate(1);
    subplot(212); solution.plotStateCoordinate(2);
    
    figure(11); 
    solution.plot2DPhaseProfile(1, 2, colors(i,:))
    xlabel('x_1');
    ylabel('x_2'); 
    h(i) = plot(NaN,NaN,'-', 'Color', colors(i,:));
    legendEntries{i} = alphaPrint;
    % %% Plot stage cost with error bars
    % figure(4);
% solution.plotCostErrorBar(0.5, tree.getHorizon,0)
end
figure(11); 
legend(h, legendEntries{:})