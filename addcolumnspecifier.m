function finalDs = addcolumnspecifier(varargin)
%ADDCOLUMNSPECIFIER - add a column with a unique value corresponding to several column values
%
% 	ds = ADDCOLUMNSPECIFIER(parameter-value pairs) reads in a tab delimited text file, adds an
%	additional column and saves the output as a tab delimited file. The additional column is a number
% 	corresponding to values in the columns/variables specified in varlist. 
%
%	The first row of the input and output tab delimited text files contain the variable
%	names.
%
% Input to the function is in the form of parameter-value pairs which are all optional:
%
%	'varlist' - cell array of strings of the variables to use for the code. If not
%		specifed, then the variable list is {'arm_stim' 'CcCi' 'pre_post' 'SessType'}.
%		(This function was originally designed for use with the sensory Study. Those were
%		the first variables we used.)
%
%	'infile'-'c:\path\to\filename.txt' - string with the input file name. If it is not 
%		specified, then the user will be asked to identify the file in a dialog box.
%
%	'outfile'-'c:\path\to\filename.txt' - string with the output file name. If it is not
%		specified, then the user will be asked to identify the file in a dialog box.
% 
% Output of the function is a dataset of the file saved.
%
% The compostion of the code number will be displayed in the matlab command window.
%
% Examples:
%	ds = addcolumnspecifier('infile', 'clinicaldata_20140109_rel_resp.txt', ...
%		'varlist', {'arm_stim' 'pre_post' 'SessType'}, 'outfile', 'data_plus_codes.txt');
%		
%	ds = addcolumnspecifier('varlist', {'sessionType' 'prePost' 'arm'});
%

% Author: Peggy Skelly
% 2014-01-08 (3:45 - 5:00): created 
% 2014-01-10 (1:10 - 1:20)
%		add 2nd input parameter, varList
% 2014-01-16
%	[x] add output file name as an input parameter
%	[x] test with other than sensory study files for more general use
%	[x] update info at top for more informative help
% 2014-01-22 
%	[x] if varlist is not specified, add option to request which variables (gui checklist)

% define input parser
p = inputParser;
p.addParamValue('infile', 'none', @isstr);
p.addParamValue('outfile', 'none', @isstr);
p.addParamValue('varlist', {});

% parse the input
p.parse(varargin{:});
inputs = p.Results;

% input file
if strcmp(inputs.infile, 'none'),		% no input file specified
	% request the data file
	[fname, pathname] = uigetfile('*.txt', 'Pick input tab delimited file');
	if isequal(fname,0) || isequal(pathname,0)
		disp('User canceled. Exitting')
		return
	else
		filePathName = fullfile(pathname,fname);
	end
else
	filePathName = inputs.infile;
end

% read in the file
disp(['reading in ' filePathName '...'])
dsIn = dataset('file', filePathName);

varNames = get(dsIn, 'VarNames');

% columns/variables that will form the unique code/specifier
if isempty(inputs.varlist)
	% request variables with this gui
	checkedVarList = getVarListGui(varNames);
	if isempty(checkedVarList)
		disp('No variables chosen. There is nothing to do. Exitting ...')
		return
	end
	varCols = varNames(checkedVarList);
	%varCols = {'arm_stim' 'CcCi' 'pre_post' 'SessType'};
else
	varCols = inputs.varlist;
end

finalDs = dsIn;
finalDs.code_num = zeros(length(dsIn),1);

disp('processing codes ...')
% each variable
for v = 1:length(varCols)
	% make the variable nominal
	dsIn.(varCols{v}) = nominal(dsIn.(varCols{v}));
	% the unique values of that variable
	varVals = unique(dsIn.(varCols{v}));
	varValsCas = cellstr(varVals);
	disp(['   digit ' num2str(v) ': ' varCols{v}])
	for w = 1:length(varVals)
		disp(['      ' num2str(w) ' = ' varValsCas{w}])
		% mask for the rows to update
		rowMsk = dsIn.(varCols{v})==varVals(w);
		
		finalDs.code_num(rowMsk) = finalDs.code_num(rowMsk) + w*10^(length(varCols)-v);
	end % each unique value of the variable
	
end % each variable

% output file
if strcmp(inputs.outfile, 'none'),		% no output file specified
	% request output name
	[fnameSave, pathnameSave] = uiputfile('*.txt', 'Save new file as ...');

	if isequal(fnameSave,0) || isequal(pathnameSave,0)
		disp('User pressed cancel. Nothing will be saved.')
		return
	end
	saveFileName = fullfile(pathnameSave, fnameSave);
else
	saveFileName = inputs.outfile;
end

disp(['saving ' saveFileName ' ...'])
export(finalDs, 'file', saveFileName, 'delimiter', '\t');

disp('done')
end

% --------------------------------------------------------------------------------
function checked = getVarListGui(varNames)
checked = [];

nVars = length(varNames);

% Create figure
h.f = figure('units','pixels','position',[200,200,150,22*nVars],...
             'toolbar','none','menu','none');
% Create checkbox for each varName
for varCnt = 1:nVars
	ypos = 30+20*(varCnt-1);
	h.c(varCnt) = uicontrol('style','checkbox','units','pixels',...
					'position',[10,ypos,130,15],'string',varNames{varCnt});    
end

% Static text
ypos = 30+20*(nVars);
h.st = uicontrol('style', 'text', 'units','pixels',...
					'position',[10,ypos,130,30],'string','Select variables to encode:');   
% Create OK pushbutton   
h.p = uicontrol('style','pushbutton','units','pixels',...
                'position',[40,5,70,20],'string','OK',...
                'callback',@p_call);
    % Pushbutton callback
    function p_call(varargin)
        vals = get(h.c,'Value');
        checked = find([vals{:}]);
        disp(checked)
		close(h.f)
	end
waitfor(h.f)
end
