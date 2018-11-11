function [X, U, optimalCost, diagnostic] = solveNoOptimizer(obj, x)
%SOLVENOOPTIMIZER solves a risk averse optimal control problem when an
%optimizer cannot be constructed
%
%

if isempty(obj.constraints_var)
    [constraints, optimalCost, U, X, stats] = obj.prepareOptimization();
    obj.constraints_var = constraints;
    obj.optimalCost_var = optimalCost;
    obj.U_var = U;
    obj.X_var = X;
    obj.stats = stats;
else
    constraints = obj.constraints_var;
    optimalCost = obj.optimalCost_var;
    X = obj.X_var;
    U = obj.U_var;
end



ops = sdpsettings;
ops.solver = 'scs'; % MOSEK v8 does not support exponential constraints
                    % This is supported in MOSEK v9, though. We
                    % have to use SuperSCS to solve problems with
                    % EVaR constraints (exponential cones)
ops.scs.max_iters = 2e4;
ops.scs.eps = 5e-4;
ops.scs.memory = 30;
ops.verbose = 0;

constraints = [constraints; X(:, 1) == x];
diagnostic = optimize(constraints, optimalCost, ops);
X = double(X);
U = double(U);
optimalCost = double(optimalCost);

end
