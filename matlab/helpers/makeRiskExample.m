function [tree, umin, umax, QN] = makeRiskExample(N, M)
% User-defined parameters
umin = -5; umax = 5;

if nargin<2, M = N; end

% Define the scenario tree
initialDistr = [0.3; 0.0; 0.0; 0.7];
probTransitionMatrix = [
    0.7  0.2  0.0  0.1;
    0.25 0.6  0.0  0.15;
    0.3  0.1  0.5  0.1;
    0.5  0.0  0.45 0.05];
ops.horizonLength = N;
ops.branchingHorizon = M;
tree = marietta.ScenarioTreeFactory.generateTreeFromMarkovChain(...
    probTransitionMatrix, initialDistr, ops);

% Define the data (system parameters and more)
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
R = {4, 3, 2, 1};
data_w_map = repmat(struct(), length(w_map), 1);
for i=1:numel(w_map)
    data_w_map(i).A = A{i}; data_w_map(i).B = B{i};
    data_w_map(i).Q = Q{i}; data_w_map(i).R = R{i};
end
tree.mapValuesToData(w_map, data_w_map);