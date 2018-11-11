classdef ConicRiskFactory
    %CONICRISKFACTORY Factory of conic risks
    %   This class can be used to create a risk measure
    %
    
    
    methods(Static)
        
        function obj = createAvar(p, alpha)
            %CREATEAVAR creates an AVaR risk
            %
            %Syntax:
            %avar = risk.ConicRiskFactory.createAvar(p, alpha)
            %
            import marietta.*
            data = ConicRiskFactory.avarData(vec(p), alpha);
            obj = ConicRiskMeasure(data);
        end
        
        function obj = createEvar(p, alpha)
            %CREATEEVAR creates an EVaR risk
            %
            %Syntax:
            %evar = risk.ConicRiskFactory.createEvar(p, alpha)
            %
            %Input arguments:
            % p         probability vector which defines the probability
            %           space
            % alpha     level of risk aversion (see below)
            %
            %Output arguments:
            % evar      an object of type ConicRiskMeasure
            %
            %EVAR is defined as
            %
            % EVAR_alpha[X] = max {mu'*X | E*mu + F*nu <=K b },
            %
            %where E, F and b are matrices and <=K is a conic inequality.
            %All these data can be retrieved as follows:
            %
            % evar = risk.ConicRiskFactory.createEvar(p, alpha);
            % data = evar.getData();
            %
            import marietta.*
            data = ConicRiskFactory.evarData(vec(p), alpha);
            obj = ConicRiskMeasure(data);
        end
        
        function obj = createMax(n)
            %CREATEMAX creates a max risk
            %
            %Syntax:
            %maxRisk = risk.ConicRiskFactory.createMax(p, alpha)
            %
            import marietta.*
            data = ConicRiskFactory.maxData(n);
            obj = ConicRiskMeasure(data);
        end
        
    end
    
    methods (Static, Access=private)
        data = avarData(p, alpha);
        data = evarData(p, alpha);
        data = maxData(p);
    end
end