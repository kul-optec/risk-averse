alpha = 0.5;

rao = marietta.RiskAverseOptimalController();
pAvar = marietta.ParametricRiskFactory.createParametricAvar;
rao.setInputBounds(-5,5)...
    .setScenarioTree(tree)...
    .setParametricRiskCost(@(prob) pAvar(prob, alpha))...
    .setTeminalCost(QN);

rao.makeController();