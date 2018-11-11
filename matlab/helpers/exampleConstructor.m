function  [tree,  dynamics, stageCost, probTransitionMatrix] = ...
    exampleConstructor(num_modes, lambda_poisson, ...
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