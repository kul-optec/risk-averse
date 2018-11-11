%RISKAVERSEPLAYGROUND
%
%Experiment with risk-averse optimal control

close all; clear;
umin = -5;
umax = 5;
% STEP 1A -- Define the scenario tree
initialDistr = [0.2; 0.1; 0.0; 0.7];
probTransitionMatrix = [
    0.7  0.2  0.0  0.1;
    0.25 0.6  0.0  0.15;
    0.3  0.1  0.5  0.1;
    0.5  0.2  0.25 0.05];
ops.horizonLength = 3;
tree = marietta.ScenarioTree.generateTreeFromMarkovChain(...
    probTransitionMatrix, initialDistr, ops);
tree.setValueAtNode(1,1);
disp(tree);

% STEP 1B -- Define the data (system parameters and more)
w_map = [1 2 3 4];
A = {[1.1 0.5; -0.5 1.1], ...
     [1.0 0.9; -0.9 1.0], ...
     [0.9 0.6; -0.6 0.9], ...
     [0.6 0.5; -0.5 0.5]};
B = {[1; 0.05], ...
     [1; 0.00], ...
     [1;-0.04], ...
     [1; 0.00]};

q_final = 50; QN = q_final*eye(2);

Q = {eye(2), eye(2),eye(2),2*eye(2)};
R = {1, 2, 3, 4};
data_w_map = repmat(struct(), length(w_map), 1);
for i=1:numel(w_map)
    data_w_map(i).A = A{i}; data_w_map(i).B = B{i};
    data_w_map(i).Q = Q{i}; data_w_map(i).R = R{i};
end
tree.mapValuesToData(w_map, data_w_map);


% STEP 2A -- Define the (parametric) risk
pAvar = marietta.ParametricRiskFactory.createParametricAvar;


% Test various values of alpha
x0 = [-4;-4];
nCtrl = 5;
controllers = repmat(struct(), nCtrl, 1); 
Jopt_vs_alpha = zeros(nCtrl, 2); i = 1;

riskConstraint = marietta.ConstraintNormState(0.8); 
for alpha = linspace(0,1,nCtrl)
    fprintf('Building controller for alpha = %.2f ..... ', alpha);
    rao = marietta.RiskAverseOptimalController();
    rao.setInputBounds(umin,umax)...
        .setScenarioTree(tree)...
        .setParametricRiskCost(@(prob) pAvar(prob, alpha))...
        .setTerminalCostMatrix(QN)...
        .addConstraint(riskConstraint);    
    rao.makeController();
    fprintf('DONE!\n')
    controllers(i).alpha = alpha;
    controllers(i).ctrl = rao;    
    [~, ~, Jsol] = rao.control(x0);
    Jopt_vs_alpha(i, :) = [alpha Jsol];
    i = i + 1;
end
disp(Jopt_vs_alpha);
plot(Jopt_vs_alpha(:,1), Jopt_vs_alpha(:,2), 'k-o'); grid on

%% Compute the solution for a particular x0
x0 = [-4;-4];
rao_selected = controllers(2).ctrl;
[Usol, Xsol, Jsol] = rao_selected.control(x0);

%% Plot the predicted optimal trajectories
maxSampleSize = 500;
allIndices = randperm(tree.getNumberOfScenarios);
allIndices = allIndices(1:min(maxSampleSize, numel(allIndices)));
sampleSize = numel(allIndices);
time_axis = 0:tree.getHorizon;

figure;
subplot(121); hold on;
for i=1:sampleSize
    idx = allIndices(i);
    scen = tree.getScenarioWithID(i);
    plot(time_axis, Xsol(1,scen)', 'k');
end
xlim([0 tree.getHorizon])
ylabel('x1'); grid on;
subplot(122); hold on;
for i=1:sampleSize
    idx = allIndices(i);
    scen = tree.getScenarioWithID(i);
    plot(time_axis, Xsol(2,scen)', 'k');
end
ylabel('x2'); xlabel('k'); grid on;
xlim([0 tree.getHorizon])

%% Plot the optimal policy
figure;
hold on;
for i=1:sampleSize
    idx = allIndices(i);
    scen = tree.getScenarioWithID(i);
    plot(Usol(scen(1:end-1)), 'k');
end
ylabel('u'); xlabel('k'); grid on;

%% Phase profile
figure;
hold on;
for i=1:sampleSize
    idx = allIndices(i);
    scen = tree.getScenarioWithID(i);
    plot(Xsol(1,scen)',Xsol(2,scen)', 'b-o');
end
grid on
ylabel('x_2'); xlabel('x_1'); grid on;