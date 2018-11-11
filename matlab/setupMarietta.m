clc
fprintf('----- Installing Marietta -----------------------------------\n');
mariettaDirectory = which('setupMarietta.m');
tokens = strsplit(mariettaDirectory, 'setupMarietta.m');
matlabDirectoryMarietta = tokens{1};
fprintf('Adding %s\nand its subfolders to MATLAB''s path.\n', ...
    matlabDirectoryMarietta);
addpath(genpath(matlabDirectoryMarietta));
fprintf('Saving path.\n')
savepath;
fprintf('Done - Marietta has been successfully installed.\n')
fprintf('-------------------------------------------------------------\n');