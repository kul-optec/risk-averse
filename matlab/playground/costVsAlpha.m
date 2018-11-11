%COSTVSALPHA solves several risk-averse optimal control problems and
%records how the optimal cost changes for different values of alpha
%

clc; clear;
rng(1);
alpha = 0.5;                    % alpha
num_modes = 6;                  % number of modes of Markov chain
lambda_poisson = 2;             % Poisson parameter
zeros_trans_matr_per_line = 3;  % Number of zeros in P (Markov trans. mat.)
horizon_length = 12;            % prediction horizon
branching_horizon = 3;          % branching horizon
umin = -10; umax = 10;          % input bounds
QN = 70*eye(2);                 % terminal cost

% Construction of the scenario tree...
[tree, dynamics, stageCost] = exampleConstructor(num_modes, lambda_poisson, ...
    zeros_trans_matr_per_line, horizon_length, branching_horizon);

disp(tree);

% Terminal cost function...
terminalCost = marietta.functions.QuadTerminalFunction(QN);

% Stage constraint g(x, u, w) = ell(x, u, w) - c,
c = 0.5;
stageConstraint = stageCost - c; % using operator overloading


x0 = [-1; -0.5];

nCtrl = 11;
controllers = repmat(struct(), nCtrl, 1);
Jopt_vs_alpha = zeros(nCtrl, 3);
i = 1;
for alpha = linspace(0, 1, nCtrl)
    
    % --- AVaR Controller
    fprintf('Building controller for alpha = %.2f ..... ', alpha);
    rao_avar = marietta.RiskAverseOptimalController();
    pAvar = marietta.ParametricRiskFactory.createParametricAvarAlpha(alpha);
    
    rao_avar...
        .setInputBounds(umin,umax)...
        .setScenarioTree(tree)...
        .setDynamics(dynamics)...
        .setStageCost(stageCost)...
        .setParametricRiskCost(pAvar)...
        .setTerminalCost(terminalCost)...
        .addStageWiseRiskConstraints(stageConstraint, ...
        pAvar, horizon_length-6:horizon_length-1);
    rao_avar.makeController();
    fprintf('DONE!\n')
    
    fprintf('Building controller for alpha = %.2f ..... ', alpha);
    if alpha==0 || alpha==1
        rao_evar = rao_avar;
    else
        rao_evar = marietta.RiskAverseOptimalController();
        pEvar = marietta.ParametricRiskFactory.createParametricEvarAlpha(alpha);
        rao_evar...
            .setInputBounds(umin,umax)...
            .setScenarioTree(tree)...
            .setDynamics(dynamics)...
            .setStageCost(stageCost)...
            .setParametricRiskCost(pEvar)...
            .setTerminalCost(terminalCost)...
            .addStageWiseRiskConstraints(stageConstraint, ...
            pAvar, horizon_length-6:horizon_length-1);
    end
    fprintf('DONE!\n');
    controllers(i).alpha = alpha;
    controllers(i).ctrl_avar = rao_avar;
    controllers(i).ctrl_evar = rao_evar;
    
    fprintf('Solving AVaR ..... ');
    solution_avar = rao_avar.control(x0);    
    fprintf('DONE!\n');
    disp(solution_avar);
    fprintf('Solving EVaR ..... ');
    solution_evar = rao_evar.control(x0);
    fprintf('DONE!\n');
    disp(solution_evar);
    
    Jopt_vs_alpha(i, :) = [alpha ...
        solution_avar.getOptimalValue() ...
        solution_evar.getOptimalValue()];
    Jopt_vs_alpha(i, :)
    i = i + 1;
end
disp(Jopt_vs_alpha);
%%
figure(192);
hold on;
plot(Jopt_vs_alpha(:,1), Jopt_vs_alpha(:,3), 'r-x', 'linewidth', 2);
plot(Jopt_vs_alpha(:,1), Jopt_vs_alpha(:,2), 'k-+', 'linewidth', 2);
grid on;
xlabel('alpha');
ylabel('optimal value');
legend('Average Value-at-Risk','Entropic Value-at-Risk')