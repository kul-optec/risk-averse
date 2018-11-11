close all; clear variables; 

%% General settings (same for all experiments) 
cAlpha = 0.1; 
alpha = 0.6;
num_modes = 3;                  % number of modes of Markov chain
lambda_poisson = 0.1;           % Poisson parameter
zeros_trans_matr_per_line = 0;  % Number of zeros in P (Markov trans. mat.)
branching_horizon = 4; 
horizon_length = 5;            % prediction horizon
constrainedStages = horizon_length;


colors = struct('mean', [0,    0,    0], ...
                'quantile', [0.63, 0.35, 0.22], ...
                'max', [0.56, 0.2,  0.18]);

%% Solve the OCP with the nominal tree 

% Also build a perturbed tree 
lambda_pert = 5; 

[treeMod, ~, ~] = makeExample(num_modes, lambda_pert, ...
    zeros_trans_matr_per_line, horizon_length, branching_horizon);

for useStageWise = [true, false]
    useNested = ~useStageWise;
    % filename = buildName(cAlpha, 'constraint');
    % if BUILD
    rao = constructProblem(alpha, cAlpha, num_modes, ...
        zeros_trans_matr_per_line, ...
        lambda_poisson, horizon_length, ...
        branching_horizon, useStageWise, useNested, constrainedStages);
%     
%         loaded = readFile(filename);
%         
     % Solve problem
     x0 = [1; 0];
     solution = rao.control(x0);
     % Assert feasibility
     assert(solution.getStatusCode() == 0, 'No feasible solution found');
     
     % Save the perturbed version;
     newRao = copy(rao);
     newRao.tree = treeMod;
     
     newSolution = marietta.Solution(newRao, solution.getStates, ...
         solution.getControlActions, ...
         solution.getOptimalValue, ...
         solution.getStatusCode, ...
         solution.getStatusMessage);
     
     solution.plotInputCoordinate(1);
     
     if useStageWise
         nominalControllers.stage = rao; 
         perturbedControllers.stage = newRao;
     
         nominalSolutions.stage = solution;
         perturbedSolutions.stage = newSolution;
     elseif useNested
         nominalControllers.nested = rao;
         perturbedControllers.nested = newRao;
         
         nominalSolutions.nested = solution;
         perturbedSolutions.nested = newSolution;
     end
end

plotHistogram(nominalSolutions, nominalControllers)
plotHistogram(perturbedSolutions, perturbedControllers)

% rao, X, U, J, status_code, status_msg
% nestedSolutionOnPerturbedTree = marietta.Solution(treeMod, nestedS)

function plotHistogram(solutions, controllers) 
% Plot specifications 
plotSpec = struct('linewidth', 1, ...
                  'linestyle', '-', ... 
                  'marker', '.', ... 
                  'markersize', 5);

% Nested
figure; hold on; 

types = {'nested', 'stage'}; 
for i = 1:numel(types)
    type = types{i};
    sol = solutions.(type);
    rao = controllers.(type);
    if strcmp(type, 'nested')
        constr = rao.nestedRiskConstraints();
    elseif strcmp(type, 'stage')
        constr = rao.stageWiseRiskConstraints(); 
    end 
    horizon = rao.tree.getHorizon();
    for i = 1:numel(constr)
        constraint = constr(i);
        if constraint.stages == horizon
            nestFun = constraint.constraintFcn;
            break;
        end
    end
    
    distribution = sol.getDistributionFunction(nestFun, horizon);
    cumulative = cumsum(distribution(:, 1));
    plot(distribution(:,2), cumulative, plotSpec);
end
xlabel('Constraint function');
ylabel('Cumulative probability');
legend('Nested risk constraints', 'stage-wise risk constraints');
axis tight;
end 


function rao=  constructProblem(alpha, cAlpha, num_modes, ... 
                         zeros_trans_matr_per_line, lambda_poisson, horizon_length, ...
                         branching_horizon, useSwConstr, useNestConstr, ...
                         constrainedStages)
                     
rng(1);                         % using fixed seed for reproducibility
umin = -20; umax = 20;          % input bounds
QN = 70*eye(2);                 % terminal cost

% Construction of the scenario tree...
[tree, dynamics, stageCost] = makeExample(num_modes, lambda_poisson, ...
    zeros_trans_matr_per_line, horizon_length, branching_horizon);

% Terminal cost function...
terminalCost = marietta.functions.QuadTerminalFunction(QN);

% Stage constraint g(x, u, w) = ell(x, u, w) - c,
c = 0.5;
stateNorm = marietta.functions.SimpleQuadStateInputFunction(eye(2), 0);
stageConstraint = stateNorm - c;

terminalStateNorm = marietta.functions.QuadTerminalFunction(eye(2));
terminalConstraint = terminalStateNorm - c;

% Print the tree...
disp(tree);
% Define the risk-averse optimal control problem
pAvar = marietta.ParametricRiskFactory.createParametricAvarAlpha(alpha);
pAvarConstr = marietta.ParametricRiskFactory.createParametricAvarAlpha(cAlpha);
rao = marietta.RiskAverseOptimalController();

rao.setInputBounds(umin,umax)...
    .setScenarioTree(tree)...
    .setDynamics(dynamics)...
    .setStageCost(stageCost)...
    .setParametricRiskCost(pAvar)...
    .setTerminalCost(terminalCost); 
if useSwConstr
    stages = constrainedStages(constrainedStages < tree.getHorizon());
    rao.addStageWiseRiskConstraints(stageConstraint, pAvarConstr, stages);
    if any(constrainedStages == tree.getHorizon())
        rao.addStageWiseRiskConstraints(terminalConstraint, pAvarConstr, tree.getHorizon());
    end
end
if useNestConstr
    stages = constrainedStages(constrainedStages < tree.getHorizon());
    rao.addNestedRiskConstraints(stageConstraint, pAvarConstr, stages);
    if any(constrainedStages == tree.getHorizon())
        rao.addNestedRiskConstraints(terminalConstraint, pAvarConstr, tree.getHorizon());
    end
end

disp('Building controller ... ');
tic; rao.makeController(); 
buildTime = toc;
fprintf('... done. Build time: %1.2f minutes.\n', buildTime / 60.0); 
end 

function  [tree,  dynamics, stageCost, probTransitionMatrix] = ...
    makeExample(num_modes, lambda_poisson, ...
    zeros_trans_matr_per_line, horizon_length, branching_horizon)


pmf_poisson = truncated_poisson_pmf(lambda_poisson, num_modes);

% Define the scenario tree
initialDistr = pmf_poisson;

% Make sparse transition matrix
probTransitionMatrix = kron(ones(num_modes, 1), pmf_poisson');
for i=1:num_modes
    idx_rand = randperm(num_modes);
    lines_to_rm = idx_rand(1:zeros_trans_matr_per_line);
    probTransitionMatrix(i,lines_to_rm) = 0;
    probTransitionMatrix(i, :) = probTransitionMatrix(i, :) / sum(probTransitionMatrix(i, :));
end

tree_options.horizonLength = horizon_length;
tree_options.branchingHorizon = branching_horizon;

tree = marietta.ScenarioTreeFactory.generateTreeFromMarkovChain(...
    probTransitionMatrix, initialDistr, tree_options);

% Define the data (system parameters and more)
w_map = (1:num_modes)';
A = cell(num_modes, 1);
B = cell(num_modes, 1);
Q = cell(num_modes, 1);
R = cell(num_modes, 1);
for i=1:num_modes
    damping = -0.3 + i*0.2;
    u = orth(randn(2));
    A{i} = [1 1; 0 0.7];
    B{i} = u*[1; 1+damping];
    Q{i} = 10*eye(2);
    R{i} = 0.1;
end

data_w_map = repmat(struct(), length(w_map), 1);
for i=1:num_modes
    data_w_map(i).Q = Q{i}; 
    data_w_map(i).R = R{i};
end
tree.mapValuesToData(w_map, data_w_map);
dynamics = marietta.functions.MarkovianLinearStateInputFunction(A, B);
stageCost = marietta.functions.MarkovianQuadStateInputFunction(Q, R);

end 


