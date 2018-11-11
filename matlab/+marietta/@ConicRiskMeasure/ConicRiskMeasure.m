classdef ConicRiskMeasure < handle
    %CONICRISKMEASURE Conic risk measure
    %   Class definition of a conic risk measure described by
    %
    %    r(Z) = max{mu'*Z | E*mu + F*nu <=_K b},
    %
    %   where <=_K is a conic inequality
    %
    
    properties(Access=private)
        data;   % data of the conic risk measure (E, F, b, K)
    end
    
    methods (Access=private)
        function disp_one(obj, additional_str)
            fprintf('-----------------------------------\n');
            fprintf('Conic risk measure%s\n', additional_str);
            fprintf('-----------------------------------\n');
            if  ~isfield(obj.data, 'F') || isempty(obj.data.F)
                r = 0;
            else
                r = size(obj.data.F, 2);
            end
            fprintf('dim(mu)     : %d\ndim(nu)     : %d\nConstraints : %d\n', ...
                size(obj.data.E, 2), r, size(obj.data.E,1));
            fprintf('-----------------------------------\n\n\n');
        end
    end
    
    methods(Access=public)
        function obj = ConicRiskMeasure(varargin)
            %CONICRISKMEASURE construct
            %
            %Syntax
            %obj = ConicRiskMeasure(data)
            %obj = ConicRiskMeasure(E, F, b, cone)
            
            if nargin==1
                data = varargin{1};
                assert(isstruct(data), 'wrong input argument type')
                assert(isfield(data, 'E'), 'data.E is missing')
                assert(isfield(data, 'b'), 'data.b is missing')
                assert(isfield(data, 'cone'), 'data.cone is missing')
                assert(isa(data.cone, 'marietta.ConvexCone'), 'data.cone is not a structure')
                if isfield(data, 'F') && ~isempty(data.F)
                    assert(size(data.E,1)==size(data.F,1), ...
                        'data.E and data.F have incompatible row dimensions')
                end
                assert(size(data.E,1)==size(data.b,1), ...
                    'data.E and data.b have incompatible row dimensions')
                assert(size(data.b,2)==1, 'data.b must be a vector')
                obj.data = data;
                return
            elseif nargin==4
                data.E = varargin{1};
                data.F = varargin{2};
                data.b = varargin{3};
                data.cone = varargin{4};
                obj.data = data;
            end
        end %END of constructor method
        
        function [r, details] = risk(obj, Z, tol)
            %RISK returns the risk of a random variable
            %
            %Syntax:
            %[r, details] = riskObject.risk(Z)
            %[r, details] = riskObject.risk(Z, tol)
            %
            %Input arguments:
            % Z         random variable (vector)
            % tol       solver tolerance (optional, default: 1e-8)
            %
            %Output arguments:
            % r         risk value
            % details   a structure with details such as the minimizers mu
            %           and nu, residuals and other solver-related
            %           information
            Z = vec(Z);
            if nargin <3
                tolerance = 1e-6;
            else
                tolerance = tol;
            end
            n = size(obj.data.E,2);
            if isfield(obj.data, 'F') && ~isempty(obj.data.F)
                r = size(obj.data.F, 2);
                d.A = sparse([obj.data.E obj.data.F]);
            else
                r = 0;
                d.A = sparse(obj.data.E);
            end
            d.b = obj.data.b;
            d.c = -[Z; zeros(r, 1)];
            solver_ops = struct('eps', tolerance, 'verbose', 0, ...
                'direction', 150, 'memory', min(n+r+1, 5));
            [munu, ~, ~, details] = scs_indirect(d, ...
                obj.data.cone.asStruct(), solver_ops);
            r = -details.pobj;
            details.mu = munu(1:n);
            if r>0, details.nu = munu(n+1:end); end
        end
        
        function data = getData(obj)
            %GETDATA returns the data of the conic risk measure
            %
            %Syntax:
            %data = riskObject.getData()
            %
            %Output arguments:
            %data   A structure with the following fields:
            %           - E, F, b: matrices defining the risk measure as
            %             risk[X] = max {mu'*X | E*mu + F*nu <=K b }, where
            %             <=K is a conic inequality with the cone K
            %           - cone: the cone which defines the conic
            %             inequality (an SCS cone)
            %
            data = obj.data;
        end
        
        
        function disp(obj)
            numObj = length(obj);
            if numObj==1
                obj.disp_one('');
            else
                for i=1:numObj
                    str = [' #' num2str(i)];
                    disp_one(obj(i), str);
                end
            end
        end
        
        function compress(obj)
            %COMPRESS compresses the risk measure by removing reduntant
            %inequalities
            
            if 0==exist('Polyhedron','class')
                warning('MPT toolbox is not installed (`Polyhedron` class missing)')
                return
            end
            
            cone = obj.data.cone;
            % compression is supported only for polytopic risk measures
            if cone.isPositiveOrthant()
                if ~isfield(obj.data, 'F') || isempty(obj.data.F)
                    polyhedron = Polyhedron(obj.data.E, obj.data.b);
                    polyhedron = polyhedron.minHRep;
                    obj.data.E = polyhedron.A;
                    obj.data.b = polyhedron.b;
                    dimConeCompressed = size(obj.data.E, 1);
                    obj.data.cone = marietta.ConvexCone(struct('l', dimConeCompressed));
                else
                    % not implemented yet
                    warning('Not implemented yet; come back later');
                end
            end
        end
    end
    
end

