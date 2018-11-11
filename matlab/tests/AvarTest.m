classdef AvarTest < matlab.unittest.TestCase
    
    %% Test Method Block
    methods (Test)
        
        function testAvar(testCase)
            Z = [rand 10^(0.6+rand) 10^(1+2*rand) 10^(1+3*rand)];
            p = rand(size(Z)); p = p/sum(p);
            
            for alpha = [0.01 0.5 0.95 1]
                avarObj = marietta.ConicRiskFactory.createAvar(p, alpha);
                r1 = avarConic(Z, p, alpha, 0);     % primal  (cvx)
                r2 = avarConic(Z, p, alpha, 1);     % dual    (cvx)
                r3 = avarConic(Z, p, alpha, 2);     % classic (cvx)
                r4 = avar(Z, p, alpha);             % classic (linprog)
                r5 = avarObj.risk(Z);
                
                testCase.verifyEqual(r1, r2, 'RelTol', 1e-3);
                testCase.verifyEqual(r1, r3, 'RelTol', 1e-3);
                testCase.verifyEqual(r1, r4, 'RelTol', 1e-3);
                testCase.verifyEqual(r1, r5, 'RelTol', 1e-3);
            end
        end
        
        function testAvarExtremeAlpha(testCase)
            n = 10;
            for i=1:5
                Z = logspace(-2,3,n)';
                p = exp(-0.5*(1:n))'; p = p / sum(p);
                expectZ = p'*Z; maxZ = max(Z);
                
                av_expect = avarConic(Z, p, 1);
                av_max = avarConic(Z, p, 0);
                
                testCase.verifyEqual(expectZ, av_expect, 'RelTol', 1e-4);
                testCase.verifyEqual(maxZ, av_max, 'RelTol', 1e-4);
                
                av_expect = avarConic(Z, p, 1, 1);
                av_max = avarConic(Z, p, 0, 1);
                
                testCase.verifyEqual(expectZ, av_expect, 'RelTol', 1e-4);
                testCase.verifyEqual(maxZ, av_max, 'RelTol', 1e-4);
            end
        end
    end
end