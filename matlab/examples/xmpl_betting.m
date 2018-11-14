%% FAIR COIN BET
clear; clc;

% Make RAO
rao = marietta.RiskAverseOptimalController();

%% Parametrize
cAlpha = 0.05;   % risk aversion against ruin
ruin = 800;      % amount that is considered to be ruin
alpha = 0.95;    % risk aversion in betting
p = 0.55;        % probability to win
N = 12;          % prediction horizon
%% Construct scenario tree;
prob_dist = [p, 1-p];
tree_options.horizonLength = N;
tree_options.branchingHorizon = tree_options.horizonLength;
tree = marietta.ScenarioTreeFactory.generateTreeFromIid(prob_dist, tree_options);
disp(tree); rao.setScenarioTree(tree);

%% Dynamics
% Define dynamical system
A = cell(2, 1); B = cell(2, 1);
A{1} = 1; A{2} = 1; B{1} = 1; B{2} = -1;
dynamics = marietta.functions.MarkovianLinearStateInputFunction(A,B);
rao.setDynamics(dynamics);

%% Cost functions
stage_cost = -0.1*log(marietta.functions.MarkovianLinearStateInputFunction({1, 1}, {0,0}));
terminal_cost = -100*log(marietta.functions.QuadTerminalFunction([], 1));
rao.setStageCost(stage_cost).setTerminalCost(terminal_cost);

%% Constraints
umin = 0; Fx = 1; Fu = -1; fmin = 0; xmin = 0;
rao.setInputBounds(umin).setStateBounds(xmin);
rao.setStateInputBounds(Fx, Fu, fmin, []);

%% Risk constraints
 stage_constraint =  marietta.functions.MarkovianLinearStateInputFunction(...
     {-1, -1}, [], {-ruin, -ruin});
 pAvarConstr = marietta.ParametricRiskFactory.createParametricAvarAlpha(cAlpha);
 rao.addStageWiseRiskConstraints(stage_constraint, pAvarConstr, 1:N-1);
 
%% Construct RAO
pAvar = marietta.ParametricRiskFactory.createParametricAvarAlpha(alpha);
rao.setParametricRiskCost(pAvar);

%% Solve problem
x0 = 1000;                   % initial bankroll
solution = rao.control(x0);  % determine risk-averse betting strategy
disp(solution);

%% Plot state and control actions
figure(1);
subplot(211); solution.plotInputCoordinate(1)
h = gca; set(h,'yscale','log')
subplot(212); solution.plotStateCoordinate(1)
h = gca; set(h,'yscale','log')
%%
figure(2);
fx = marietta.functions.MarkovianLinearStateInputFunction({1, 1}, {0,0}, {0,0});
solution.plotFunctionErrorBar(fx, 0.95)