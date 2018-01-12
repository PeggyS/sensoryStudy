function plotsepdata1(varargin)
% plotsepdata1 - plot sep measures - format #1 - per subject basis
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
%		Default = all subjects - probably not recommended. Several figures are created for each subject.
%		You may run out of memory.
%
% creates plots: 1 page/window for each subject
%	each row of axes = a variable
%	4 columns - involved & uninvolved X C_contraleral & C_ipsi
%

% Author: Peggy Skelly
% 2013-09-24: created (12:00 - 12:30, 2:30 - 5:30 = 3.5 hrs)
%	Started from plotclinmeas1.m
% 2013-09-25: 
%		added better ylabels

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

% make sure that all other variables are doubles, not strings
varNames = get(ds, 'VarNames');

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
	varList = {'N20'; 'P25';  'N20_P25'};
	onePage(ds, subjList(s), varList);
	varList = {'P25'; 'N33';  'P25_N33'};
	onePage(ds, subjList(s), varList);
	varList = {'N33'; 'P45';  'N33_P45'};
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
	% left 2 axes = involved side title
	h=uicontrol('Style', 'text',...
       'String', 'Stim Involved MN',... 
       'Units','normalized',...
       'Position', [0.3 0.97 0.1 0.02]); 
	% right 2 axes = uninvolved side title
	h=uicontrol('Style', 'text',...
       'String', 'Stim Uninvolved MN',... 
       'Units','normalized',...
       'Position', [0.7 0.96 0.1 0.02]); 
	
for row = 1:length(varList)
	varNameCc = regexprep(varList{row}, '(\d{2,3})', '$1Cc');
	varNameCc = [varNameCc '_avg'];
	varNameCi = regexprep(varList{row}, '(\d{2,3})', '$1Ci');
	varNameCi = [varNameCi '_avg'];
	
	% axis for each measure
	subplot(3,4,(row-1)*4+1)
	title('C_{contrlateral}')
	% format ylabel depending on variable name
	if strfind(varList{row}, '_')
		% an amplitude peak-to-peak variable
		labStr = [strrep(varList{row}, '_', '\_') ' Ampl_{p-p} (\muV)'];
	else
		labStr = [varList{row} ' Latency (ms)'];
	end
	ylabel(labStr) 
	invAx = gca;
	setXaxisLimsLabels(invAx);
	drawLines(ds, subj, 'inv', varNameCc);
	
	subplot(3,4,(row-1)*4+2)
	title('C_{ipsilateral}')
	uninvAx = gca;
	setXaxisLimsLabels(uninvAx);
	drawLines(ds, subj, 'inv', varNameCi);
	
	subplot(3,4,(row-1)*4+3)
	title('C_{contrlateral}')
	setXaxisLimsLabels(gca);
	hLines = drawLines(ds, subj, 'un', varNameCc);
	
	subplot(3,4,(row-1)*4+4)
	title('C_{ipsilateral}')
	setXaxisLimsLabels(gca);
	drawLines(ds, subj, 'un', varNameCi);
end
legend(hLines, {'BL' 'Sham' 'High' 'Low'})


% -------------------------------------------------------------------------------------
function hLines = drawLines(ds, subj, arm, varName)
% draw the lines in the current axes for the arm and variable name specified
% return a list of the handles to the lines in hLines

hLines = nan(1,4);

% baseline data point
bl = extractBL(ds, subj, arm, varName);
hL = line(0, bl, 'Marker', '*', 'LineStyle', 'none', 'MarkerSize', 8, 'LineWidth', 2);
hLines(1) = hL(1);
% line for each sessType
x = [1 2 3];
[pre, p1, p2] = extractPrePost(ds, subj, 'Hs', arm, varName);
hL = line(x, [pre p1 p2], 'Marker', 'o', 'LineWidth', 2.5, 'MarkerSize', 8);
hLines(2) = hL(1);
[pre, p1, p2] = extractPrePost(ds, subj, 'Ha', arm, varName);
hL = line(x, [pre p1 p2], 'Marker', '^', 'Color', [0 0.8 0], 'LineStyle', '--', ...
	'LineWidth', 2.5, 'MarkerFaceColor', [0 0.8 0]);
hLines(3) = hL(1);
[pre, p1, p2] = extractPrePost(ds, subj, 'L', arm, varName);
hL = line(x, [pre p1 p2], 'Marker', 's', 'Color', 'r', 'LineStyle', ':', ...
	'LineWidth', 2.5, 'MarkerFaceColor', 'r');
hLines(4) = hL(1);

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
	val=nan; 
end

% -------------------------------------------------------------------------------------
function setXaxisLimsLabels(hAx)
set(hAx, 'XLim', [-0.5 3.5])
set(hAx, 'XTick', [0:3])
set(hAx, 'XTickLabel', {'BL' 'Pre' 'P1' 'P2'})

	
% -------------------------------------------------------------------------------------
function makeYLimsAgree(ax1, ax2)
% HERE ---
