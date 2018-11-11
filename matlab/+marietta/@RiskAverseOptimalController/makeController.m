function makeController(obj)

% Make sure that it is possible to make an optimizer...
pRiskCost = obj.parametricRiskCost;
randomProb = rand(5,1); randomProb = randomProb./sum(randomProb);
riskCost = pRiskCost(randomProb);
riskCostCone = riskCost.getData().cone;
if riskCostCone.getPrimalExponentialConeDimension > 0
    warning('Cannot create parameteric optimizer with this risk measure');
    controller = [];
    return
end

swRisk = obj.stageWiseRiskConstraints;
for i = 1:numel(swRisk)
    swRisk_i = swRisk(i);
    risk_sw_i = swRisk_i.pRisk(randomProb);
    cone_risk_sw_i = risk_sw_i.getData().cone;
    if cone_risk_sw_i.getPrimalExponentialConeDimension > 0
        warning('Cannot create parameteric optimizer with this risk measure');
        controller = [];
        return
    end
end

nestRisk = obj.nestedRiskConstraints;
for i = 1:numel(nestRisk)
    nestRisk_i = nestRisk(i);
    risk_nest_i = nestRisk_i.pRisk(randomProb);
    cone_risk_nest_i = risk_nest_i.getData().cone;
    if cone_risk_nest_i.getPrimalExponentialConeDimension > 0
        warning('Cannot create parameteric optimizer with this risk measure');
        controller = [];
        return
    end
end

[constraints, optimalCost, U, X, stats] = obj.prepareOptimization();
obj.stats = stats;

ops = sdpsettings;
ops.solver = obj.solver;      % NOTE: Sedumi returns bad quality solutions
                              % and very easily fails to solve the problem
                              % MOSEK seems to perform very well

x_init = sdpvar(size(X, 1), 1);
constraints = [constraints;
    X(:, 1) == x_init];
obj.controller = optimizer(constraints, optimalCost, ops, x_init, {U, X, optimalCost});
