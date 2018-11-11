classdef TerminalFunction < handle
    %TERMINALFUNCTION is a function F(x) defined at the terminal stage.
    %
    %A TerminalFunction object corresponds to a function F(x), which may
    %correspond either to a terminal cost function or a terminal constraint.
    %
    
    methods (Abstract)
        result = apply(obj, x);
    end
    
    methods (Access = public)
        function r = plus(f1, f2)
            r = marietta.functions.op.TerminalFunctionOp(f1, f2, @(s,z) (s + z));
        end
        
        function r = minus(f1, f2)
            r = marietta.functions.op.TerminalFunctionOp(f1, f2, @(s,z) (s - z));
        end
        
        function r = mtimes(f1, f2)
            r = marietta.functions.op.TerminalFunctionOp(f1, f2, @(s,z) (s * z));
        end
        
        function r = uminus(f)
            r = (-1.0)*f;
        end
        
        function r = uplus(f)
            r = f;
        end
        
        function r = mpower(f, p)
            r = marietta.functions.op.TerminalFunctionOp(f, p, @(s,z) (s^z));
        end
    end
end

