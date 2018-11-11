%% Single stage formulation using the dual representation
avar_cost = [];
options = struct('nx', 50, 'nu', 5, 'lam_poisson', 5, ...
    'leaf_nodes', 20, 'plot', 1);
for alp = [0:0.001:0.01 0.02:0.01:0.12 0.2:0.1:1]
    out = singleStageRiskMinimization(alp, options);
    avar_cost = [ avar_cost; [alp out.J] ];
    out.u
end
figure;
plot(avar_cost(:,1),avar_cost(:,2), '-x','linewidth', 2)
xlabel('alpha')
ylabel('optimal cost')
grid

%% Plot VaR-vs-AVaR-vs-EVaR and compare values fora given random variable
cvx_clear
n = 10;
Z = exp(linspace(0,5,n))';
p = exp(-0.5*(1:n))'; p = p / sum(p);

xd = [];
for alpha = [0.001:0.01:0.1 0.2:0.1:0.9 0.94:0.02:1.0]
    avar = marietta.ConicRiskFactory.createAvar(p, alpha);
    evar = marietta.ConicRiskFactory.createEvar(p, alpha);
    avarZ = avar.risk(Z);
    evarZ = evar.risk(Z);
    xd = [xd; alpha avarZ evarZ];
end

close all;
figure;
plot(xd(:,1), xd(:,2),'-o','linewidth', 2); hold on;
plot(xd(:,1), xd(:,3),'-x','linewidth', 2);
legend('AVaR', 'EVaR'); grid on;
xlabel('alpha'); ylabel('risk')

%% CVX cone example
clc
cvx_begin
variables x(3);
minimize 1
subject to
{x(1), x(2), x(3)} == exponential
cvx_end

%% Constructing a scenario tree out of an IID distribution
clc; clear ops;
probDist = [0.6 0.4];
ops.horizonLength = 4;
ops.branchingHorizon = ops.horizonLength - 1;
tree = marietta.ScenarioTree.generateTreeFromIid(probDist, ops);
disp(tree);
plot(tree); grid on;
%% Constructing a scenario tree out of a Markov chain
clc; clear ops;
initialDistr = [0.2; 0.1; 0.0; 0.7];
probTransitionMatrix = [
    0.7  0.2  0.0  0.1;
    0.25 0.6  0.05 0.1;
    0.4  0.1  0.5  0.0;
    0.0  0.0  0.3  0.7];
ops.horizonLength = 3;
ops.branchingHorizon = 3;
tree = marietta.ScenarioTree.generateTreeFromMarkovChain(...
    probTransitionMatrix, initialDistr, ops);
disp(tree);
treeplot(tree.getAncestors()','bs','r--'); grid on;

%% Generate tree from data
clear;
rng(1)

% data generation
nSamples = 1e5;
nHorizon = 20;
data = zeros(nSamples, 1, nHorizon);
for i = 1:nSamples
    for t = 1:nHorizon
        data(i,1,t) = t * (2*randi(2) - 3) *  (1 + 0.001*randn);
    end
end

% tree generation
options.ni = [4 3 2 1];
options.Wscaling = 0;
tree = marietta.ScenarioTree.generateTreeFromData(data, options);
close;
plot(tree);
 



%%
alpha = 0.5;
parametricRisk = marietta.ParametricRiskFactory.createParametricAvar();
risk = parametricRisk(tree.getConditionalProbabilityOfChildren(13), alpha)
