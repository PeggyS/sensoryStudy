function dsOut = addtallerdiff(varargin)
% ADDTALLERDIFF - add pre-post diff (d_) variables to the taller format. 
%
% 'taller' format has columns for subject, measure, and ~20-44 separate columns
% for each combination of sessionType_pre_post_arm. 
% 
%
% inputs in the form of parameter-value pairs:
%	'file'-'c:\path\to\filename.txt' - optional - string with the full file and pathname to the 
%		clinical measures or sep data tab delimited text file. If it
%		is not specified, then the user will be asked to identify the file
%		in a dialog box.
% 
%	Note: 1st line in the text file contains the variable names. The names must be correct.
%
% The variables are saved in the order designated by S Pundik and the list
% is hard coded here, line 66.


% Author: Peggy Skelly
% 2014-06-25

% define input parser
p = inputParser;
p.addParamValue('file', 'none', @isstr);

% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none'),		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.txt', 'Pick taller format tab delimited file');
	if isequal(fname,0) || isequal(pathname,0)
		disp('User canceled. Exitting')
		return
	else
		filePathName = fullfile(pathname,fname);
	end
else
	filePathName = inputs.file;
end


ds = dataset('file', filePathName);

varNames = get(ds, 'VarNames');

sess_match_cell = regexp(varNames, '(Hs_g)|(Ha_g)|(L_g)|(BL)|(Hs)|(Ha)|(L)', 'match');
msk = ~cellfun('isempty',sess_match_cell);
sess_cell_list = sess_match_cell(msk);
sess_list = [sess_cell_list{:}];
sess_types = unique(sess_list);

% sess_types = {'BL' 'Hs' 'Ha' 'L' 'Hs_g' 'Ha_g' 'L_g'};

arm = {'inv','un'};

% add post minus pre variables to the dataset
for ss = 1:length(sess_types)
	for aa = 1:length(arm)
		varPre = [sess_types{ss} '_pre_' arm{aa}];
		varPost1 = [sess_types{ss} '_post1_' arm{aa}];
		varPost2 = [sess_types{ss} '_post2_' arm{aa}];
		diffVar1 = ['d_' varPost1];
		diffVar2 = ['d_' varPost2];
		ds.(diffVar1) = ds.(varPost1) - ds.(varPre);
		ds.(diffVar2) = ds.(varPost2) - ds.(varPre);
	end
end

newvarnames = get(ds,'VarNames');

% reorder the dataset variables
orderedVarNames = {
'Subj'       
'Measure'    
'BL_pre_inv' 
'BL_pre_un' 
'd_Hs_post1_inv'
'd_Ha_post1_inv'
'd_L_post1_inv'
'd_Hs_g_post1_inv'
'd_Ha_g_post1_inv'
'd_L_g_post1_inv'
'd_Hs_post2_inv'
'd_Ha_post2_inv'
'd_L_post2_inv'
'd_Hs_g_post2_inv'
'd_Ha_g_post2_inv'
'd_L_g_post2_inv'
'd_Hs_post1_un'
'd_Ha_post1_un'
'd_L_post1_un'
'd_Hs_g_post1_un'
'd_Ha_g_post1_un'
'd_L_g_post1_un'
'd_Hs_post2_un'
'd_Ha_post2_un'
'd_L_post2_un'
'd_Hs_g_post2_un'
'd_Ha_g_post2_un'
'd_L_g_post2_un'
'Hs_pre_inv' 
'Hs_post1_inv'
'Hs_post2_inv'
'Ha_pre_inv' 
'Ha_post1_inv'
'Ha_post2_inv'
'L_pre_inv' 
'L_post1_inv'
'L_post2_inv'
'Hs_pre_un'  
'Hs_post1_un'
'Hs_post2_un'
'Ha_pre_un'
'Ha_post1_un'
'Ha_post2_un'  
'L_pre_un' 
'L_post1_un'   
'L_post2_un'
'Hs_g_pre_inv' 
'Hs_g_post1_inv'
'Hs_g_post2_inv'
'Ha_g_pre_inv' 
'Ha_g_post1_inv'
'Ha_g_post2_inv'
'L_g_pre_inv' 
'L_g_post1_inv'
'L_g_post2_inv'
'Hs_g_pre_un'  
'Hs_g_post1_un'
'Hs_g_post2_un'
'Ha_g_pre_un'
'Ha_g_post1_un'
'Ha_g_post2_un'  
'L_g_pre_un' 
'L_g_post1_un'   
'L_g_post2_un'};

dsOut = ds(:, intersect(orderedVarNames,newvarnames,'stable'));

% request where to save 
[fName, pathName] = getsavenames(fullfile(pwd, 'data_taller_d.txt'), 'Save as');
if isequal(fName, 0) || isequal(pathName, 0),
	disp('Not saving. User canceled.');
	return;
end

% save
export(dsOut, 'File', fullfile(pathName, fName), 'delimiter', '\t')


