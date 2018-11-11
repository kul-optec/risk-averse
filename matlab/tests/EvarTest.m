classdef EvarTest < matlab.unittest.TestCase
    
    %% Test Method Block
    methods (Test)
        
        function testEvar(testCase)
            import matlab.unittest.constraints.IsTrue;
            n = 7;
            Z = exp(linspace(0,2,n))';
            p = exp(-0.4*(1:n))'; p = p / sum(p);
            alpha = 0.5;
            evar = marietta.ConicRiskFactory.createEvar(p, alpha);
            avar = marietta.ConicRiskFactory.createAvar(p, alpha);
            evarZ = evar.risk(Z);
            avarZ = avar.risk(Z);
            testCase.verifyThat(evarZ>=p'*Z, IsTrue);
            testCase.verifyThat(evarZ<=max(Z), IsTrue);
            testCase.verifyThat(evarZ>=avarZ, IsTrue);
            
            f = @(t) ( t * ( log((p'*exp(Z/t))) - log(alpha)) );
            fminconOptions = optimoptions('fmincon');
            fminconOptions.OptimalityTolerance = 1e-4;
            fminconOptions.ConstraintTolerance = 1e-4;
            fminconOptions.Display = 'off';
            [~, evarFmincon] = fmincon(f, 1, [], [], [], [], 0, [], [], fminconOptions);
            testCase.verifyEqual(evarZ, evarFmincon, 'RelTol', 1e-3);
            
        end
        
    end
end