clear
clc
alpha = 0.8;
p = 0.2;
q = 1 - p;
P = [p; q];
z = 100;

N = 4;
Z = cell(N+1,1);
Z{N+1} = [z;zeros(2^N-1,1)];
for i=1:N
    Z{N-i+1} = zeros(2^(N-i),1);
    for s=1:2:2^(N-i+1)
        Z{N-i+1}((s+1)/2) = avar(Z{N-i+2}(s:s+1), P, alpha);
    end   
end
nestedAvar = Z{1};

% 
repeatProb = @(j) kron(ones(2^(N-j-1),1),repelem(P,2^j));
probLastStage = ones(2^N,1);
for j=0:N-1
    probLastStage = probLastStage .* repeatProb(j);
end
avarLastStage = avar(Z{end}, probLastStage, alpha);

% Print results
fprintf('Nested risk: %g,\n Stage risk: %g\n', nestedAvar, avarLastStage);