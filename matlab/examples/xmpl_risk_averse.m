clear; clc;

%%
alpha = 0.8;                    % alpha
cAlpha = 0;                     % alpha used for risk constraints 
lambda_poisson = 2;             % Poisson parameter
num_modes = 3;                  % number of modes of Markov chain
horizon_length = 12;            % prediction horizon
branching_horizon = 3;          % branching horizon
umin = -10; umax = 10;          % input bounds


pmf_poisson = truncated_poisson_pmf(lambda_poisson, num_modes);

% Define the scenario tree
initialDistr = pmf_poisson;

% Make sparse transition matrix
probTransitionMatrix = rand(num_modes, num_modes);
rowSumPTM = sum(probTransitionMatrix, 2)';
probTransitionMatrix = probTransitionMatrix ./ kron(ones(1, num_modes), rowSumPTM');


% Make the scenario tree
tree_options.horizonLength = horizon_length;
tree_options.branchingHorizon = branching_horizon;
tree = marietta.ScenarioTreeFactory.generateTreeFromMarkovChain(...
    probTransitionMatrix, initialDistr, tree_options);


% Define the data (system parameters and more)
A = cell(num_modes, 1);
B = cell(num_modes, 1);
Q = cell(num_modes, 1);
R = cell(num_modes, 1);
for i=1:num_modes
    re_ = 0.95 + 0.1 * randn;
    im_ = 0.3 + i * 0.05 * randn;
    u = orth(randn(2));
    A{i} = u*[re_ im_; -im_ re_]*u';
    B{i} = u*[1; 0.1*randn];
    Q{i} = (1+0.05*randn)*eye(2);
    R{i} = 1 + 0.01*randn;
end
Q{num_modes} = 10*Q{num_modes};

dynamics = marietta.functions.MarkovianLinearStateInputFunction(A, B);
stageCost = marietta.functions.MarkovianQuadStateInputFunction(Q, R);

QN = 70*eye(2);                 % terminal cost
terminalCost = marietta.functions.QuadTerminalFunction(QN);

c = 0.5;
stateNorm = marietta.functions.SimpleQuadStateInputFunction(eye(2), 0); 
stageConstraint = stateNorm - c; % using operator overloading
%%

pAvar = marietta.ParametricRiskFactory.createParametricAvarAlpha(alpha);
pAvarConstr = marietta.ParametricRiskFactory.createParametricAvarAlpha(cAlpha);
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