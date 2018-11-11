function [rao, buildTime] = cacheController(filename, alpha, cAlpha, num_modes, ... 
                         zeros_trans_matr_per_line, lambda_poisson, horizon_length, ...
                         branching_horizon, useSwConstr, useNestConstr, ...
                         constrainedStages)
% CACHECONTROLLER Builds a potentially large risk-averse controller and
% saves the optimizer to a mat-file, so it can easily be reused. 

rng(1);                         % using fixed seed for reproducibility
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

if exist('filename', 'var') && ~isempty(filename)
    rd = which('valueAtRisk.m');
    toks = strsplit(rd, 'valueAtRisk.m');
    folderplayground = fullfile(toks{1},'playground','controllers');
    
    alphaCost = alpha;
    alphaConstraint = cAlpha;

    subdirAndFile = strsplit(filename,'/'); 
    fullDir = fullfile(folderplayground, subdirAndFile{1:end-1}); 
    if ~exist(fullDir, 'dir')
        mkdir(fullDir);
    end
    
    fullPath = fullfile(folderplayground, [filename, '.mat']);

    disp(['saving controller and data to', fullPath]);
    save(fullPath, 'rao', ...
        'alphaCost', ...
        'alphaConstraint', ...
        'buildTime', ...
        'num_modes', ...
        'zeros_trans_matr_per_line', ...
        'lambda_poisson', ...
        'branching_horizon');
end