function out = singleStageRiskMinimization(alpha, ops)

default_options = struct('nx', 4, 'nu', 2, 'lam_poisson', 5, ...
    'leaf_nodes', 10, 'plot', 0);
if nargin < 2
    temp_options = default_options;
else
    temp_options = ops;
end

rng(1)
p_poisson = @(lambda, kmax)...
    (lambda.^(0:kmax)  ./ factorial(0:kmax)) * exp(-lambda);
p_poisson_trunc = @(lambda, kmax) ...
    p_poisson(lambda, kmax) / sum(p_poisson(lambda, kmax));

lambda_poisson = temp_options.lam_poisson;
leaf_nodes     = temp_options.leaf_nodes;
nx = temp_options.nx;
nu = temp_options.nu;
x0 = randn(nx, 1);

p = p_poisson_trunc(lambda_poisson,leaf_nodes-1)';


A = cell(leaf_nodes, 1);
B = cell(leaf_nodes, 1);
c = cell(leaf_nodes, 1);

for i=1:leaf_nodes
    A{i} = diag(linspace(0.1,i/(nx/10),nx));
    U = orth(randn(nx,nx));
    A{i} = U'*A{i}*U;
    B{i} = randn(nx, nu);
    c{i} = randn(nx, 1)/10;
end


cvx_begin

    
    cvx_solver_settings('dumpfile', 'cvx_solver_data')
    
    % Variables
    variable s(leaf_nodes, 1)
    variable y1(2*leaf_nodes, 1)
    variable y0(1,1)
    variable u(nu, 1)
    variable x(nx, leaf_nodes)

    J = 1e-3*u'*u + y0 + y1' * [zeros(leaf_nodes,1); p];
    
    minimize( J )

    subject to

            u >= 0;

            % System dynamics
            for i=1:leaf_nodes
                x(:,i) == A{i} * x0 + B{i} * u + c{i}; % Eq. (22b)
            end

            % Constraints
            for i=1:leaf_nodes
                x(:,i)'*x(:,i) <= s(i); % Eq. (22e)
            end

            y0 + [-eye(leaf_nodes) alpha*eye(leaf_nodes)] * y1 == s;
            y1 >= 0;
cvx_end


cost = zeros(leaf_nodes, 1);
for i=1:leaf_nodes
    cost(i) = 1e-3*u'*u + x(:,i)'*x(:,i);
end

if isfield(temp_options, 'plot') && temp_options.plot
    [cost, idx] = sort(cost);
    plot(cost, cumsum(p(idx)), 'linewidth', 2); hold on
    xlabel('cost')
    ylabel('Cumulative probability')
    grid on
end
info = [];
load('cvx_solver_data.mat')
out.cost = cost;
out.J = J;
out.p = p;
out.u = u;
out.x = x;
out.s = s;
out.status = cvx_status;
out.info = info;
delete('cvx_solver_data.mat')
