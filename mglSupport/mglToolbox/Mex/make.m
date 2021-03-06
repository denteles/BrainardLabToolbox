function make
% make
%
% Description:
% Iterates over all .c files in the directory and compiles them into mex
% files.

cfiles = dir('*.c');

for i = 1:length(cfiles)
	eval(sprintf('mex -f clang_maci64.xml %s', cfiles(i).name));
end
