% EXAMPLESTAGEWISERISKCONSTRAINT constructs an example of a risk-averse
% optimal control problem with stage-wise risk constraints. 

clc; clear; close all; 
loaded = load('384scenarios_alpha0_1.mat');
rao = loaded.rao;
tree = rao.tree; 
alpha = loaded.alphaCost; 
cAlpha = loaded.alphaConstraint; 
stageConstraints = rao.stageWiseRiskConstraints;

disp(rao);

% Compute the solution for a particular x0
x0 = [-0.5; -0.1];
tic; solution = rao.control(x0); toc
disp(solution);

% % Proper plotting of state trajectories
figure;
subplot(211); solution.plotStateCoordinate(1);
subplot(212); solution.plotStateCoordinate(2);

% % Plot input trajectory
figure;
solution.plotInputCoordinate(1);

% Plot stage cost with error bars
figure;
solution.plotCostErrorBar(1-alpha, tree.getHorizon)

% Plot stage-wise risk constraints 
for i = 1:numel(stageConstraints)
    constraint = stageConstraints(i); 
    if isa(constraint.constraintFcn, 'marietta.functions.StageFunction')
        figure;
        solution.plotFunctionErrorBar(constraint.constraintFcn, cAlpha, tree.getHorizon);
        for state = constraint.stages
            plot(state*[1 1],get(gca,'YLim'), 'k:');
        end
        ylabel('constraint function');
        legend('Expected', [num2str(100*(1-cAlpha)) '-percentile'], 'Worst case');
    else 
        figure;
        solution.plotFunctionErrorBar(constraint.constraintFcn, cAlpha, tree.getHorizon);
        ylabel('terminal constraint function');
        legend('Expected', [num2str(100*(1-cAlpha)) '-percentile'], 'Worst case');
    end
end
% % Plot phase profile
figure;
solution.plot2DPhaseProfile(1,2);


