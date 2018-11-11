classdef ScenarioTreeFactory
    %SCENARIOTREEFACTORY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Static, Access = public)
        scenarioTreeObject = generateTreeFromData(data, options);
        scenarioTreeObject = generateTreeFromIid(probDist, options);
        scenarioTreeObject = generateTreeFromMarkovChain(...
            chainProbTransMatrix, initialDistribution, options);
    end % -- END of public static methods
    
    methods (Static, Access = private)
        [tree, details] = treeFormation(data, options)
    end % -- END of private static methods
    
end

