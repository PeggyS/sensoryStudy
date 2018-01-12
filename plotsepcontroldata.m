function plotsepcontroldata(varargin)
% plotsepcontroldata - plot sep measures for controls to examine handedness differences
% 
% inputs in the form of parameter-value pairs:
%	'file'-'c:\path\to\filename.txt' - optional - string with the full file and pathname to the 
%		se data tab delimited text file. If it
%		is not specified, then the user will be asked to identify the file
%		in a dialog box.
% 
%	'norm'-true - optional - logical true or false indicating if the data should be
%		displayed normalized to the value from the Pre session. If not specified, then the
%		data will not be normalized (default = false).
%
%	'subjects'-{'s2601sens';'M01'} - optional - cell array of strings for the subjects to plot. 
%		Default = all control subjects 'c26' 
%
% creates plots: 1 page/window for each variable - axes for each subject
%	each row of axes = a variable
%	4 columns - involved & uninvolved X C_contraleral & C_ipsi
%

% Author: Peggy Skelly
% 2013-12-20: created (2:30 - 4:00 = 1.5 hrs)
%	Started from plotsepdata1.m


% define input parser
p = inputParser;
p.addParamValue('file', 'none', @isstr);
p.addParamValue('norm', false, @islogical);
p.addParamValue('subjects', {}, @iscell);

% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none'),		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.txt', 'Pick sep data tab delimited file');
	if isequal(fname,0) || isequal(pathname,0)
		disp('User canceled. Exitting')
		return
	else
		filePathName = fullfile(pathname,fname);
	end
else
	filePathName = inputs.file;
end


% read in the data
ds = dataset('file', filePathName);
% make Site, Subj and SessType nominal variables
ds.Subj = nominal(ds.Subj);
ds.SessType = nominal(ds.SessType);

if isempty(inputs.subjects)
	subjList = unique(ds.Subj);
else
	% allow for short names to refer to a group of subjects, i.e. 's26' are all VA stroke
	% subjects, 'c26' are all VA control subjects, 'M' are all CCF subjects
	subjList = {};
	for s = 1:length(inputs.subjects),
		% find matching subjects in the dataset
		matchCellArray = regexpi(cellstr(char(ds.Subj)), ['^' inputs.subjects{s}]);
		emptyMsk = cellfun(@isempty, matchCellArray);
		matchSubjList = cellstr(char(ds.Subj(~emptyMsk)));
		if isempty(subjList)
			subjList = matchSubjList;
		else
			subjList = [subjList; unique(matchSubjList)];
		end
	end
	subjList = unique(subjList);
end
subjList = nominal(subjList);


% figure for each subject
if isempty(inputs.subjects)
	% default = empty -> use all subjects
	subjList = unique(ds.Subj);
else
	% allow for short names to refer to a group of subjects, i.e. 's26' are all VA stroke
	% subjects, 'c26' are all VA control subjects, 'M' are all CCF subjects
	subjList = {};
	for s = 1:length(inputs.subjects),
		% find matching subjects in the dataset
		matchCellArray = regexpi(cellstr(char(ds.Subj)), ['^' inputs.subjects{s}]);
		emptyMsk = cellfun(@isempty, matchCellArray);
		matchSubjList = cellstr(char(ds.Subj(~emptyMsk)));
		if isempty(subjList)
			subjList = matchSubjList;
		else
			subjList = [subjList; unique(matchSubjList)];
		end
	end
	subjList = unique(subjList);
end
subjList = nominal(subjList);
for s = 1:length(subjList),
	varList = {'N20' 'P25'  'N20_P25'; 
				''  'N33'  'P25_N33'; 
				'' 'P45'  'N33_P45'};
	onePage(ds, subjList(s), varList);
	varList = {'P45' 'N60'  'P45_N60'; 
				''  'P100'  'N60_P100'; 
				'' 'N120'  'P100_N120'};
	onePage(ds, subjList(s), varList);
end


% -----------------------------------------------------------------------------------
function onePage(ds, subj, varList)
	figure
	set(gcf, 'Position', [85 222  1165 667])	% resize it
	orient tall		% make sure it prints in tall orientation
	% subject title
	h=uicontrol('Style', 'text',...
       'String', char(subj),... 
       'Units','normalized',...
       'Position', [0.5 0.98 0.1 0.02]); 
% 	% left 2 axes = involved side title
% 	h=uicontrol('Style', 'text',...
%        'String', 'Stim Involved MN',... 
%        'Units','normalized',...
%        'Position', [0.3 0.97 0.1 0.02]); 
% 	% right 2 axes = uninvolved side title
% 	h=uicontrol('Style', 'text',...
%        'String', 'Stim Uninvolved MN',... 
%        'Units','normalized',...
%        'Position', [0.7 0.96 0.1 0.02]); 
   
[numRows, numCols] = size(varList);
axCnt = 0;
for row = 1:numRows,
	for col = 1:numCols,
		axCnt = axCnt+1;
		% format ylabel depending on variable name
		if strfind(varList{row, col}, '_')
			% an amplitude peak-to-peak variable
			labStr = [strrep(varList{row, col}, '_', '\_') ' Ampl_{p-p} (\muV)'];
		else
			labStr = [varList{row, col} ' Latency (ms)'];
		end


		if length(varList{row, col}) > 0
			% axis for each measure
			subplot(numRows, numCols, axCnt)
			title(labStr) 
			invAx = gca;
			%setXaxisLimsLabels(invAx);
			drawLines(ds, subj, varList{row, col});
		end
		setXaxisLimsLabels(gca);
	end
end

% -------------------------------------------------------------------------------------
function hLines = drawLines(ds, subj, varName)
% draw the lines in the current axes for the arm and variable name specified
% return a list of the handles to the lines in hLines

hLines = nan(1,4);

% dominant contralateral variable names
varNameDc = regexprep(varName, '(\d{2,3})', '$1Cc');
varNameDc = ['pre_inv_' varNameDc '_avg'];
varNameDi = regexprep(varName, '(\d{2,3})', '$1Ci');
varNameDi = ['pre_inv_' varNameDi '_avg'];
varNameNc = regexprep(varName, '(\d{2,3})', '$1Cc');
varNameNc = ['pre_un_' varNameNc '_avg'];
varNameNi = regexprep(varName, '(\d{2,3})', '$1Ci');
varNameNi = ['pre_un_' varNameNi '_avg'];

% data
dc = getdsvalue(ds, subj, 'BL', varNameDc);
di = getdsvalue(ds, subj, 'BL', varNameDi);
nc = getdsvalue(ds, subj, 'BL', varNameNc);
ni = getdsvalue(ds, subj, 'BL', varNameNi);

% plot
x = [1 2 3 4];
hL = line(x, [dc di nc ni], 'Marker', '*', 'LineStyle', 'none', 'MarkerSize', 8, 'LineWidth', 2);



% -------------------------------------------------------------------------------------
function setLineMark(hLine, site, subjCnt)

markerList = repmat({'o' '^' 's' 'd' '*' '<' 'p' 'h'}, [1 subjCnt]);
colorList =  repmat({'b' 'g' 'r' 'k' 'c' 'm'}, [1 subjCnt]);

switch site
	case 'VA'
		set(hLine, 'LineStyle', '-', 'MarkerFaceColor', colorList{subjCnt})
	case 'CCF'
		set(hLine, 'LineStyle', '--', 'MarkerFaceColor', 'none')
end

set(hLine, 'LineWidth', 2.0, 'Color', colorList{subjCnt}, ...
		'Marker', markerList{subjCnt}, 'MarkerSize', 10);

% -------------------------------------------------------------------------------------
function val = extractBL(ds, subj, arm, varName)
% get the baseline data for the subj (nominal variable), arm ('inv' | 'un') and varName
% (string like 'vibr_dig2_avg')

% form the variable name
varName = ['pre_' arm '_' varName];
% get the data
val = getdsvalue(ds, subj, 'BL', varName);


% -------------------------------------------------------------------------------------
function [pre, post1, post2] = extractPrePost(ds, subj, session, arm, varName)
% get the baseline data for the subj (nominal variable), session ('Hs' | 'Ha' | 'L'), 
% arm ('inv' | 'un') and varName
% (string like 'vibr_dig2_avg')

% form the variable name
varNameFull = ['pre_' arm '_' varName];
% get value
pre = getdsvalue(ds, subj, session, varNameFull);

% post1
varNameFull = ['post1_' arm '_' varName];
post1 = getdsvalue(ds, subj, session, varNameFull);

% post2
varNameFull = ['post2_' arm '_' varName];
post2 = getdsvalue(ds, subj, session, varNameFull);

% -------------------------------------------------------------------------------------
function val = getdsvalue(ds, subj, session, varName)
% get data for the subj (nominal variable), session ('BL' | 'Hs' | 'Ha' | 'L') and 
% varName (string like post2_inv_vibr_dig2_avg)
% if there is no value, return NaN not empty matrix

% get value
val = ds(ds.Subj==subj & ds.SessType==session, varName);
% return nan if there is no value
if isempty(val), 
	val = dataset({nan, varName}); 
end

% -------------------------------------------------------------------------------------
function setXaxisLimsLabels(hAx)
set(hAx, 'XLim', [0.5 4.5])
set(hAx, 'XTick', [1:4])
set(hAx, 'XTickLabel', {'Dc' 'Di' 'Nc' 'Ni'})

	
% -------------------------------------------------------------------------------------
function makeYLimsAgree(ax1, ax2)
% HERE ---
