function outDS = compare2tdtxt(varargin)
% COMPARE2TDTXT - compare 2 tab delimited text files
% 
% 	ds = COMPARE2TDTXT(parameter-value pairs) reads in a tab delimited text file, 
%	creates a difference dataset and saves the output as a tab delimited file. 
%
%	The first row of the input and output tab delimited text files contain the variable
%	names.
%
% Input to the function is in the form of parameter-value pairs which are all optional:
%
%	'infiles'-'c:\path\to\filename.txt' - string with the input file name. If it is not 
%		specified, then the user will be asked to identify the file in a dialog box.
%
%	'varlist' - cell array of strings of the variables to use for the code. If not
%		specifed, then the variable list is {'arm_stim' 'CcCi' 'pre_post' 'SessType'}.
%		(This function was originally designed for use with the sensory Study. Those were
%		the first variables we used.)
%
%	'outfile'-'c:\path\to\filename.txt' - string with the output file name. If it is not
%		specified, then the user will be asked to identify the file in a dialog box.
% 
% Output of the function is a dataset of the file saved.
% If 2 files are not specified, the user will be asked to identify 2 tab delimited 
% text files via open dialog boxes. The first row of the file should contain 
% column/variable names. 
%
% The user will be asked where to save the new file.
%
% Example
%

% Author: Peggy Skelly
% 2014-05-07 (8:30 -9:30): initial skeleton and main comparison guts

% if nargin < 2,
% 	% request file 1
% 	[fname1, pathname1] = uigetfile('*.txt', 'Pick tab delimited file #1');
% 	if isequal(fname1,0) || isequal(pathname1,0)
% 		disp('User canceled. Exitting')
% 		return
% 	end
% 	% request file 2
% 	[fname2, pathname2] = uigetfile('*.txt', 'Pick tab delimited file #2');
% 	if isequal(fname2,0) || isequal(pathname2,0)
% 		disp('User canceled. Exitting.')
% 		return
% 	end
% else
	% check the input parameters 
	pathname1 = '/Users/peggy/Documents/MATLAB/sensoryStudy';
	pathname2 = '/Users/peggy/Documents/MATLAB/sensoryStudy';
	fname1 = 'old_sepdata_rel_sham_codes.txt';
	fname2 = 'new_sepdata_rel_sham_code.txt';
	
% end

% read in the files
disp('reading in the files...')
ds1 = dataset('file', fullfile(pathname1,fname1));
ds2 = dataset('file', fullfile(pathname2,fname2));

% compareds

% dsOld = dataset('file','old_sepdata_rel_sham_codes.txt');

% dsNew = dataset('file','new_sepdata_rel_sham_code.txt');
dsOld = ds1;
dsNew = ds2;

oldvnames = get(dsOld, 'VarNames');
newvnames = get(dsNew, 'VarNames');

oldKeys = nominal(cellstr(dsOld(:,1:7)));
newKeys = nominal(cellstr(dsNew(:,1:7)));

% items in new, but not in old
[c,ind]=setdiff(newKeys,oldKeys,'rows');
[cv,indv]=setdiff(oldvnames,newvnames);


dsNew(ind,:)=[];

dsOld2 = dsOld(:,newvnames);
matOld = double(dsOld2(:,9:end));
% sort both ds 

% extract numbers
%oldNumericVnames = ;
%matOld = double(dsOld(:,9:end));
matNew = double(dsNew(:,9:end));

matDiff = matOld - matNew;

dsDiff = mat2dataset(matDiff, 'VarNames', newvnames(9:end));
dsDiff2=horzcat(dsOld2(:,1:8), dsDiff);
export(dsDiff2,'file','old_minus_new_sep.txt')
