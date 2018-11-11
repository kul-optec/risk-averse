classdef ParametricRiskFactory
    %PARAMETRICRISKFACTORY is a factory class which generates parametric
    %risk measures
    %
    %A parametric risk measure is a function which follows the template:
    %@(p, alpha) parametricRisk(p, alpha),
    %where, `p` is a probabilit vector and `alpha` is a parameter (can be a
    %scalar, vector or anything)
    %
    
    methods(Static)
        function obj = createParametricAvar()
            %CREATEPARAMETRICAVAR creates a parametric average
            %value-at-risk
            obj = @(p, param) marietta.ConicRiskFactory.createAvar(vec(p), param);
        end
        
        function obj = createParametricEvar()
            %CREATEPARAMETRICEVAR creates a parametric entropic
            %value-at-risk
            obj = @(p, param) marietta.ConicRiskFactory.createEvar(vec(p), param);
        end
        
         function obj = createParametricAvarAlpha(alpha)
            %CREATEPARAMETRICAVAR creates a parametric average
            %value-at-risk with given alpha
            obj = @(p) marietta.ConicRiskFactory.createAvar(vec(p), alpha);
         end
         
         function obj = createParametricEvarAlpha(alpha)
            %CREATEPARAMETRICAVAR creates a parametric entropic
            %value-at-risk with given alpha
            obj = @(p) marietta.ConicRiskFactory.createEvar(vec(p), alpha);
         end
        
    end
end