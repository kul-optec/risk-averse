function makeScenarioIndex(treeObject)
ns = numel(treeObject.leaves);
scenario_index = cell(ns,1);
for s=1:ns
    scenario_index{s,1} = zeros(treeObject.stage(treeObject.leaves(s,1))+1,1);
    scenario_index{s,1}(end) = treeObject.leaves(s,1);
    for k=treeObject.stage(treeObject.leaves(s,1)):-1:1
        scenario_index{s,1}(k) = treeObject.ancestor(scenario_index{s,1}(k+1));
    end
end
treeObject.scenario_index = scenario_index;