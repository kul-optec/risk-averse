function pmf_poisson = truncated_poisson_pmf(lambda, n)
k = 0:n-1;
pmf_poisson = exp(-lambda) * (lambda.^k ./ factorial(k));
pmf_poisson = pmf_poisson ./ sum(pmf_poisson);
pmf_poisson = pmf_poisson(:);