function norm = colVecNorm(X)
%COLVECNORM replacement for the function `vecnorm`, which is not supported
% in MATLAB <2018b. 
norm = sqrt(sum(X.*X, 1));
end 