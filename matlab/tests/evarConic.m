function [r, details] = evarConic(Z, p, alpha, mode)

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
    [r, details] = evarConicPrimal(Z, p, alpha);    
elseif mode_ == 1
    % dual
elseif mode_ == 2
    [r, details] = evarClassic(Z, p, alpha);
end






% ----- mode: 0 -----------------------------------------------------------
function [r, details] = evarConicPrimal(Z, p, alpha)
details = []; if alpha<1e-8, r = max(Z); return; end
r = 0;
details = [];
n = length(Z);
cvx_begin 
    cvx_solver scs
    cvx_solver_settings('eps', 1e-8) 
    variables mu_var(n,1) nu_var(n,1)
    
    maximize(mu_var'*Z)     % worst-case expectation
    
    subject to:
    % Constraints...
                      ones(1,n) * mu_var ==  1;           % 1  (dim=1)
                      mu_var             >=  0;           % 3  (dim=n)     
                      ones(1,n) * nu_var <= -log(alpha);  % 4  (dim=n)
        
        % ----- exponential conic constraints -----------------------------
        for i=1:n
            % Constraint: (-nu, mu, p) \in K_exp
            rel_entr(mu_var(i), p(i)) <= nu_var(i);   % 5  (dim=3n)
        end
cvx_end


r = mu_var'*Z;
details.mu = mu_var;
details.status = cvx_status;



% ----- mode: 2 ---- (verified) -------------------------------------------
function [r, details] = evarClassic(Z, p, alpha)
details = []; if alpha<1e-8, r = max(Z); return; end
n = length(Z);
cvx_begin 
    cvx_solver scs
    cvx_solver_settings('eps', 1e-9) 
    variable mu_var(n,1)    
    maximize(mu_var'*Z)    
    subject to:    
        ones(1,n) * mu_var == 1;
        mu_var >= 0;
        kl_divergence_ = 0;
        for i=1:n
            kl_divergence_ = kl_divergence_ +  rel_entr(mu_var(i), p(i));
        end
        kl_divergence_ <= -log(alpha);        
cvx_end

r = mu_var'*Z;
details.mu = mu_var;
details.status = cvx_status;
