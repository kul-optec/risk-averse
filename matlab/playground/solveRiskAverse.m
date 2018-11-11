%SOLVERISKAVERSE constructs a risk-averse optimal control, solves it and
%plots the generated optimal state and input trajectories
%

clc; clear; close all; 
%% Construction of scenario tree and parametrization
rng(1);                         % using fixed seed for reproducibility
alpha = 0.8;                    % alpha
cAlpha = 0;                     % alpha used for risk constraints 
num_modes = 5;                  % number of modes of Markov chain
lambda_poisson = 2;             % Poisson parameter
zeros_trans_matr_per_line = 3;  % Number of zeros in P (Markov trans. mat.)
horizon_length = 12;            % prediction horizon
branching_horizon = 3;          % branching horizon
umin = -10; umax = 10;          % input bounds
QN = 70*eye(2);                 % terminal cost

% Construction of the scenario tree...
[tree, dynamics, stageCost] = exampleConstructor(num_modes, lambda_poisson, ...
    zeros_trans_matr_per_line, horizon_length, branching_horizon);

% Terminal cost function...
terminalCost = marietta.functions.QuadTerminalFunction(QN);

% Stage constraint g(x, u, w) = ell(x, u, w) - c,
c = 0.5;
stateNorm = marietta.functions.SimpleQuadStateInputFunction(eye(2), 0); 
stageConstraint = stateNorm - c; % using operator overloading

% Print the tree...
disp(tree);
%% Define the risk-averse optimal control problem
pAvar = marietta.ParametricRiskFactory.createParametricAvarAlpha(alpha);
pAvarConstr = marietta.ParametricRiskFactory.createParametricAvarAlpha(cAlpha);
pEvar = marietta.ParametricRiskFactory.createParametricEvarAlpha(alpha);
rao = marietta.RiskAverseOptimalController();

rao.setInputBounds(umin,umax)...
    .setScenarioTree(tree)...
    .setDynamics(dynamics)...
    .setStageCost(stageCost)...
    .setParametricRiskCost(pAvar)...
    .setTerminalCost(terminalCost)...
    .addStageWiseRiskConstraints(stageConstraint, pAvarConstr, horizon_length-6:horizon_length-1)...
    .addNestedRiskConstraints(stageConstraint, pAvarConstr, horizon_length-1);

rao.makeController();

disp(rao);

%% Compute the solution for a particular x0
x0 = [-.5; -.5];
tic; solution = rao.control(x0); toc
disp(solution);


%% Proper plotting of state trajectories
figure(1);
subplot(211); solution.plotStateCoordinate(1);
subplot(212); solution.plotStateCoordinate(2);

% Plot input trajectory
figure(2);
solution.plotInputCoordinate(1);

% Plot stage cost with error bars
figure(3);
solution.plotCostErrorBar(1-alpha, tree.getHorizon)

% Plot phase profile
figure(4); 
solution.plot2DPhaseProfile(1,2)


%% Nicer plot of tree
num_modes = 5;
lambda_poisson = 4;
zeros_trans_matr_per_line = 0;
horizon_length = 3;
branching_horizon = 3;


my_tree = tree;

close;
figure(7);
hold on;
it_N = my_tree.getIteratorNodesAtStage(horizon_length);
i = 1;
position = [];
nodes  = [];
while it_N.hasNext()
    iNode = it_N.next();
    weight = my_tree.getProbabilityOfNode(iNode) / my_tree.getProbabilityOfNode(my_tree.getAncestorOfNode(iNode));
    if my_tree.getNumberOfChildren(my_tree.getAncestorOfNode(iNode)) > 1    
        plot(horizon_length, i, 'ko', 'markersize', 50*weight);
    end
    nodes = [nodes; iNode];
    position = [position; i];
    i = i - 1/(my_tree.getNumberOfNodesAtStage(horizon_length)-1);
end
%

position_previous = position;
nodes_previous = nodes;
position = []; nodes = [];
for t=horizon_length-1:-1:0
    iterator_stage_t = my_tree.getIteratorNodesAtStage(t);
    while iterator_stage_t.hasNext()
        iNode = iterator_stage_t.next();
        if t > 0 && my_tree.getNumberOfChildren(my_tree.getAncestorOfNode(iNode)) > 1  
        weight = my_tree.getProbabilityOfNode(iNode) ...
            / my_tree.getProbabilityOfNode(my_tree.getAncestorOfNode(iNode));
        else
            weight = 1e-2;
        end
        chNode = my_tree.getChildrenOfNode(iNode);
        pos1 = position_previous(nodes_previous==chNode(1));
        pos2 = position_previous(nodes_previous==chNode(end));
        pos_middle = (pos1+pos2)/2;
        plot(t, pos_middle, 'ko', 'markersize', 50*weight);
        for j=1:numel(chNode)
            plot([t, t+1], [pos_middle, position_previous(nodes_previous==chNode(j))], 'k');
        end
        position = [position; pos_middle];
        nodes = [nodes; iNode];
    end
    position_previous = position;
    nodes_previous = nodes;
end
