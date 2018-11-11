classdef StageFunction < handle
    %STAGEFUNCTION is a function of x, u and w; this is an abstract class.
    %
    %A StageFunction object corresponds to a function F(x,u,w), which may
    %correspond either to a stage cost function or a stage constraint.
    %
    
    methods (Abstract)
        result = apply(obj, x, u, w);
        nx = getStateDimension(obj);
        nu = getInputDimension(obj);
        nModes = getNumberOfModes(obj);
    end
    
    methods (Access = public)
        function r = plus(f1, f2)
            r = marietta.functions.op.StageFunctionOp(f1, f2, @(s,z) (s + z));
        end
        
        function r = minus(f1, f2)
            r = marietta.functions.op.StageFunctionOp(f1, f2, @(s,z) (s - z));
        end
        
        function r = mtimes(f1, f2)
            r = marietta.functions.op.StageFunctionOp(f1, f2, @(s,z) (s * z));
        end
        
        function r = uminus(f)
            r = (-1.0)*f;
        end
        
        function r = uplus(f)
            r = f;
        end
        
        function r = mpower(f, p)
            r = marietta.functions.op.StageFunctionOp(f, p, @(s,z) (s^z));
        end
    end
    
end

