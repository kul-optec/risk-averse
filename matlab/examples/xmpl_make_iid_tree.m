clear;  clc;

probDist = [0.6 0.4];
ops.horizonLength = 15;
ops.branchingHorizon = 5;
tree = marietta.ScenarioTreeFactory.generateTreeFromIid(probDist, ops);
disp(tree);
plot(tree);