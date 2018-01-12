function finalDS = merge2tdtxt(startDir)
% merge2tdtxt - read in 2 tab delimited text files and reformat into a single spreadsheet
% 
% The user will be asked to identify 2 tab delimited text files via open dialog boxes.
% The excel files should have first row with column/variable names. Common names
% in the 2 files will be merged. If a column name exists in one and not the other.
%
% If two rows are exactly the same then the duplicate is removed.
%
% The user will be asked where to save the new file.
%
% The formatted data is saved in the baseDir in a file named sepdata.txt or other name
% chosen by the user. 

% Author: Peggy Skelly
% 2013-09-24: created 

% request file 1
[fname1, pathname1] = uigetfile('*.txt', 'Pick tab delimited file #1');
if isequal(fname1,0) || isequal(pathname1,0)
	disp('User canceled. Exitting')
	return
end
% request file 2
[fname2, pathname2] = uigetfile('*.txt', 'Pick tab delimited file #2');
if isequal(fname2,0) || isequal(pathname2,0)
	disp('User canceled. Exitting.')
	return
end

% read in the files
disp('reading in the files...')
ds1 = dataset('file', fullfile(pathname1,fname1));
ds2 = dataset('file', fullfile(pathname2,fname2));


% merge them
disp('merging ...')
% check for all matching variable names in the 2 datasets
varNames1 = get(ds1, 'VarNames');
varNames2 = get(ds2, 'VarNames');

% check for date variables 
ds1_dateVarStr = varNames1(strcmpi(varNames1, 'date'));
ds1_hasDate = false;
if ~isempty(ds1_dateVarStr), 
	ds1_hasDate = true;
	ds1_dateVarStr = ds1_dateVarStr{:};
end
ds2_dateVarStr = varNames2(strcmpi(varNames2, 'date'));
ds2_hasDate = false;
if ~isempty(ds2_dateVarStr), 
	ds2_hasDate = true;
	ds2_dateVarStr = ds2_dateVarStr{:};
end
if ds1_hasDate && ds2_hasDate
	if isnumeric(ds1.(ds1_dateVarStr))
		ds1.(ds1_dateVarStr) = datenum(num2str(ds1.(ds1_dateVarStr)),'YYYYmmdd');
	end
	if isnumeric(ds2.(ds2_dateVarStr))
		ds2.(ds2_dateVarStr) = datenum(num2str(ds2.(ds2_dateVarStr)),'YYYYmmdd');
	end
	if iscell(ds1.(ds1_dateVarStr))
		ds1.(ds1_dateVarStr) = datenum(ds1.(ds1_dateVarStr));
	end
	if iscell(ds2.(ds2_dateVarStr))
		ds2.(ds2_dateVarStr) = datenum(ds2.(ds2_dateVarStr));
	end

end

% variables in ds1, but not in ds2
varIn1Not2 = setdiff(varNames1, varNames2);
if ~isempty(varIn1Not2),
	disp(['Columns in file 1, but not in file 2:'])
	for vn = 1:length(varIn1Not2)
		disp(varIn1Not2{vn})
	end
end
	
% and vice versa
varIn2Not1 = setdiff(varNames2, varNames1);
if ~isempty(varIn2Not1),
	disp(['Columns in file 2, but not in file 1:'])
	for vn = 1:length(varIn2Not1)
		disp(varIn2Not1{vn})
	end
end
% the actual merge 
newDS = join(ds1, ds2, 'type', 'outer', 'mergekeys', true);

% reformat date field
if ds1_hasDate && ds2_hasDate,
	newDS.(ds1_dateVarStr) = datestr(newDS.(ds1_dateVarStr));
	if ~strcmp(ds1_dateVarStr, ds2_dateVarStr)
		newDS.(ds2_dateVarStr) = datestr(newDS.(ds2_dateVarStr));
	end
end

% request save name
[fnameSave, pathnameSave] = uiputfile('*.txt', 'Save merged file as ...');

% save
if isequal(fnameSave,0) || isequal(pathnameSave,0)
   disp('User pressed cancel. Nothing will be saved.')
else
	disp(['saving ' fullfile(pathnameSave, fnameSave)])
	export(newDS, 'file', fullfile(pathnameSave, fnameSave), 'delimiter', '\t');
end

disp('done')