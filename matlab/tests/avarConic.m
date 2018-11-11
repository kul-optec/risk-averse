function [r, details] = avarConic(Z, p, alpha, mode)

if ~isvector(p), error('p must be a vector'); end
if ~isvector(Z), error('Z must be a vector'); end
if ~isscalar(alpha), error('alpha must be a scalar'); end
if length(Z) ~= length(p), error('Z and p have incompatible lengths'); end
if abs(sum(p) - 1) > 1e-4, error(['sum(p) = ' num2str(sum(p)) ' != 1']); end
if any(p<0), error('p has negative elements'); end
if alpha<0 || alpha>1, error('alpha must be in [0,1]'); end


if size(p,1)==1, p = p'; end
if size(Z,1)==1, Z = Z'; end

mode_ = 0;
if nargin >= 4, mode_ = mode; end

if mode_ == 0
    [r, details] = avarConicPrimal(Z, p, alpha);
elseif mode_ == 1
    [r, details] = avarConicDual(Z, p, alpha);
elseif mode_ == 2
    [r, details] = avarClassic(Z, p, alpha);
end

function [cone, data] = riskProblemData(Z, p, alpha)
K = length(Z);
E = [ones(1,K); alpha * eye(K); -eye(K)     ];
b = [1;         p             ;  zeros(K,1) ];
cone.f = 1;
cone.l = 2*K;

data.A = sparse(E);
data.b = b;
data.c = -Z;

function [r, details] = avarClassic(Z, p, alpha)
n = length(Z);
details = [];

if alpha < 1e-5
    r = max(Z); 
    return;
end

cvx_begin quiet
    variable t(1,1)
    
    sum_ = 0;
    for i=1:n
        sum_ = sum_ + p(i) * max(0, Z(i) - t);
    end
    
    minimize(t + sum_/alpha);
    
cvx_end

r = t + sum_/alpha;


function [r, details] = avarConicDual(Z, p, alpha)
[~, data] = riskProblemData(Z, p, alpha);
cvx_begin quiet
 cvx_solver scs
 cvx_solver_settings('eps', 1e-8, ...
     'do_super_scs',1,...
     'direction', 100, ...
     'memory', 5, ...
     'verbose', 0)
 variable y(size(data.A,1))
 minimize(y'*data.b)
 subject to:
    data.A'*y == Z
    y(2:end) >= 0
cvx_end 
details.data = data;
r = y'*data.b; 
details.y = y;
details.status = cvx_status;
if ~strcmp(cvx_status, 'Solved')
    warning(['CVX status : ' cvx_status]);
end

function [r, details] = avarConicPrimal(Z, p, alpha)
[cone, data] = riskProblemData(Z, p, alpha);
[mu, y_dual, s_dual, info] = scs_direct(data, cone, struct('eps', 1e-5, ...
    'verbose', 0));
r = Z'*mu;
details.data = data;
details.cone = cone;
details.mu   = mu;
details.y_dual = y_dual;
details.s_dual = s_dual;
details.info = info;
if ~strcmp(info.status, 'Solved')
    warning(['Solver status ' info.status]);
end
