classdef MarkovianQuadStateInputFunction < marietta.functions.StageFunction
    %MARKOVIANQUADSTATEINPUTFUNCTION a Markovian quadratic function
    %involving the system states and inputs.
    %
    %It is a function of the form
    %
    % f(x,u,w) = x'*Q(w)*x + u'*R(w)*u + q(w)'*x + r(w)'*u + x'*S(w)*u + c;
    %
    %it is f: X x U x W --> R
    %
    
    properties (Access = protected)
        Q = [];
        R = [];
        S = [];
        q = [];
        r = [];
        c = [];
        nx = 0;
        nu = 0;
        nModes = 0;
    end
    
    methods (Access = public)
        
        function obj = MarkovianQuadStateInputFunction(Q, R, S, q, r, c)
            %MARKOVIANQUADSTATEINPUTFUNCTION constructor
            %
            %Syntax:
            %ell = marietta.functions.MarkovianQuadStateInputFunction(...,
            %      Q, R, S, q, r, c);
            %
            if nargin > 0
                obj.Q = Q;
                if ~isempty(Q)
                    obj.nModes = length(Q);
                    obj.nx = size(Q{1}, 1);
                end
                if nargin > 1
                    obj.R = R;
                    if ~isempty(R)
                        obj.nModes = length(R);
                        obj.nu = size(R{1}, 1);
                    end
                    if nargin > 2
                        obj.S = S;
                        if ~isempty(S)
                            obj.nModes = length(S);
                            obj.nx = size(S{1}, 1);
                            obj.nu = size(S{1}, 2);
                        end
                        if nargin > 3
                            obj.q = q;
                            if ~isempty(q)
                                obj.nModes = length(q);
                                obj.nx = length(q{1});
                            end
                            if nargin > 4
                                obj.r = r;
                                if ~isempty(r)
                                    obj.nModes = length(r);
                                    obj.nu = length(r{1});
                                end
                                if nargin > 5
                                    obj.c = c;                                    
                                    if ~isempty(c)
                                        obj.nModes = length(c);                                        
                                    end
                                end % -- nargin > 5
                            end % -- nargin > 4
                        end % -- nargin > 3
                    end % -- nargin > 2
                end % -- nargin > 1
            end % -- nargin > 0
        end % -- END OF Constructor
        
        function result = apply(obj, x, u, w)
            result = 0;
            if ~isempty(obj.Q), result = result + x'*obj.Q{w}*x; end
            if ~isempty(obj.R), result = result + u'*obj.R{w}*u; end
            if ~isempty(obj.S), result = result + x'*obj.S{w}*u; end
            if ~isempty(obj.q), result = result + obj.q{w}'*x; end
            if ~isempty(obj.r), result = result + obj.r{w}'*u; end
            if ~isempty(obj.c), result = result + obj.c{w}; end
        end
        
        function nx = getStateDimension(obj)
            nx = obj.nx;
        end
        
        function nu = getInputDimension(obj)
            nu = obj.nu;
        end
        
        function nModes = getNumberOfModes(obj)
            nModes = obj.nModes;
        end
    end
    
end

