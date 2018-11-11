clc; clear

% Counterexample motivating the use of nested risk measures in the
% formulation of risk constraints

% We have a binary tree with N=2. The basis probability is defined by the
% conditional probabilities P[A->A] = p, P[B->A] = q;
p = 0.1;
q = 0.5;


% Starting from mode A, the probability at stage k=2 is
P2 = @(p,q) [p^2; p*(1-p); (1-p)*q; (1-p)*(1-q)];

% At k=2, the distribution of costs is
Z2 = [1e5; 10; 0; 0];

% The level of risk aversion is taken to be 
alpha = 0.5;

% The average value at risk of the distribution of costs at stage k=2,
% using the nominal distribution defined via p_nominal and q_nominal, is
[avar2, mu_star] = avar(Z2, P2(p,q), alpha);


% Let us not compute the nested AV@R...
avar_loc1 = avar(Z2(1:2), [p; 1-p], alpha);
avar_loc2 = avar(Z2(3:4), [q; 1-q], alpha);
nested_avar = avar([avar_loc1; avar_loc2], [p; 1 - p], alpha);

fprintf('AV@R[%.2f](Z2)     = %3.5f\n', alpha, avar2);
fprintf('nestedAV@R         = %3.5f\n', nested_avar)



sdpvar p01 p02 p13 p14 p25 p26
F = [p01>=0, p02 >= 0, p13 >= 0, p14 >= 0, p25 >=0 , p26 >=0, ...
    p01 <=1, p02 <= 1, p13 <= 1, p14 <= 1, p25 <= 1 , p26 <= 1, ...
     p01 + p02 == 1, p13 + p14 == 1, p25 + p26 == 1, ...
     p01 <= (1/alpha) * p, ...
     p02 <= (1/alpha) * (1-p), ...
     p13 <= (1/alpha) * p, ...
     p14 <= (1/alpha) * (1-p), ...
     p01 * p13 <= (1/alpha) * p^2, ...
     p01 * p14 <= (1/alpha) * p*(1-p), ...
     p02 * p25 <= (1/alpha) * p*q, ...
     p02 * p26 <= (1/alpha) * (1-p) * (1-q), ...
     p01 * p13 * Z2(1) + p01 * p14 * Z2(2) + p02 * p25 * Z2(3) + p02 * p26 * Z2(4) >= avar2 + 0.1];

J = [];
ops = sdpsettings();
ops.fmincon.MaxIter = 6e4;
ops.fmincon.MaxFunEvals = 6e4;
ops.fmincon.TolCon = 1e-9;
sol = optimize(F, J, ops)
     

p01 = double(p01);
p02 = double(p02);
p13 = double(p13);
p14 = double(p14);
p25 = double(p25);
p26 = double(p26);

p01 = p01/(p01 + p02);
p02 = p02/(p01 + p02);

p13 = p13/(p13 + p14);
p14 = p14/(p13 + p14);

p25 = p25/(p25 + p26);
p26 = p26/(p25 + p26);


aver = p01 * p13 * Z2(1) + p01 * p14 * Z2(2) + p02 * p25 * Z2(3) + p02 * p26 * Z2(4)
check = [ p01 - (1/alpha) * p
     p02- (1/alpha) * (1-p)
     p13 - (1/alpha) * p
     p14 - (1/alpha) * (1-p)
     p01 * p13 - (1/alpha) * p^2
     p01 * p14 - (1/alpha) * p*(1-p)
     p02 * p25 - (1/alpha) * p*q
     p02 * p26 - (1/alpha) * (1-p) * (1-q)]