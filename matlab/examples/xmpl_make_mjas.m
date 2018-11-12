clear; clc;

A{1} = [1 2; 3 4];
A{2} = [3 1; 5 0];
A{3} = [1 1; 0 1];

B{1} = [1; 1];
B{2} = [0; 1];
B{3} = [1; 0];

p{1} = [3; 2];
p{2} = [3; 1];
p{3} = [1; 2];

mjas = marietta.functions.MarkovianLinearStateInputFunction(A, B, p);