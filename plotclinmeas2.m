function plotclinmeas2(varargin)
% plotclinmeas2 - plot clinical measures - format #2
% 
% inputs in the form of parameter-value pairs:
%	'file'-'c:\path\to\filename.txt' - optional - string with the full file and pathname to the 
%		clinical measures tab delimited text file. If it
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
%	Note: 1st line in the text file contains the variable names. The names must be correct.
%
% creates plots: 1 page/window for each measure
%	each row of axes = a treatment session
%	2 columns - involved & uninvolved
%

% Author: Peggy Skelly
% 2013-09-13: created (4:15 - 5:45  = 1.5 hrs)
%	Started from a copy of plotclinicalmeas1
%
% 2013-09-20: (11:10 - 11:30, 1:50 - 2:50 = 1.3 hrs)
%	edit input parameters to option-value pairs 
%	add option to normalize lines to the pre session
%
% 2013-09-25: add subject parameter
%
% 2014-01-27: add make ylims aggree

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
	[fname, pathname] = uigetfile('*.txt', 'Pick clinical measures tab delimited file');
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
ds.Site = nominal(ds.Site);
ds.Subj = nominal(ds.Subj);
ds.SessType = nominal(ds.SessType);

% make sure that all other variables are doubles, not strings
varNames = get(ds, 'VarNames');

% for 2pt data, if there is a value for Ncorct, but no value for 2pt_dig, then they wer
% above the largest value, 15. Change these absent values to 20 for display purposes
digNam = regexp(varNames, '2pt_(dig[24]|thmb)$');	% find the 2pt variable names
digNamesIdx = cellfun(@(x) ~isempty(x), digNam);	% indices of nonempty cells
digVarNames = varNames(digNamesIdx);	% list of variable names ( 'pre_inv_2pt_dig2', ...)
digNctVarNames = cellfun(@(x) [x '_Ncorct'], digVarNames, 'UniformOutput', false);	% ( 'pre_inv_2pt_dig2_Ncorct', ...)

for v = 1:length(digVarNames)
	% missing (nan) values
	valNanMsk = isnan(double(ds(:,digVarNames(v))));
	% present (not nan) counts
	cntNanMsk = ~isnan(double(ds(:,digNctVarNames(v))));
	% assign value of 20 to missing values, but present counts
	dsTmp = dataset({20*ones(sum(valNanMsk & cntNanMsk),1), 'tmp'});
	ds(valNanMsk & cntNanMsk, digVarNames(v)) = dsTmp;

	% for CCF data, check for 15 in the digVarNames and a number lower than 7 in
	% digNctVarNames
	val15Msk = double(ds(:,digVarNames(v))) == 15;
	cnt7Msk = double(ds(:,digNctVarNames(v))) < 7;
	dsTmp = dataset({20*ones(sum(val15Msk & cnt7Msk),1), 'tmp'});
	ds(val15Msk & cnt7Msk, digVarNames(v)) = dsTmp;
end

% subjects
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

% figure for each measure
measureList = {'vibr_dig2_avg'; ...
	'vibr_elbw_avg'; ...
	'2pt_thmb'; ...
	'2pt_dig2'; ...
	'2pt_dig4'; ...
	'monofil_dig2_nonlocal'; ...
	'monofil_dig2_local'; ...
	'monofil_dig4_nonlocal'; ...
	'monofil_dig4_local'; ...
	'proprioception_index_pct'; ...
	'proprioception_wrist_pct'; ...
	'temp'; ...
	'smobj'; ...
	'stkch'; ...
	'hcans'};

for s = 1:length(measureList),
	figure
	set(gcf, 'Position', [ 228   354   974   577])	% resize it
	orient landscape		% make sure it prints in landscape orientation
	% subject title
	h=uicontrol('Style', 'text',...
       'String', char(measureList(s)),... 
       'Units','normalized',...
	   'Fontsize', 12,...
       'Position', [0.25 0.97 0.5 0.035]); 
	
   % list of axis handles that will be set to have same y limits
	axList = ones(3,1);
	
	% axis for each session
	axList(1) = subplot(2,3,1);
	title('Sham')
	ylabel('Involved')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList, 'Hs', 'inv', measureList{s}, inputs.norm);
	
	axList(2) = subplot(2,3,2);
	title('High Freq')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList, 'Ha', 'inv', measureList{s}, inputs.norm);
	
	axList(3) = subplot(2,3,3);
	title('Low Freq')
	setXaxisLimsLabels(gca);
	hLines = drawLines(ds, subjList, 'L', 'inv', measureList{s}, inputs.norm);
	legend(hLines, char(subjList))
	
	makeYLimsAgree(axList)
	
	axList(1) = subplot(2,3,4);
	ylabel('Uninvolved')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList, 'Hs', 'un', measureList{s}, inputs.norm);

	axList(2) = subplot(2,3,5);
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList, 'Ha', 'un', measureList{s}, inputs.norm);
	
	axList(3) = subplot(2,3,6);
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList, 'L', 'un', measureList{s}, inputs.norm);

	makeYLimsAgree(axList)

end


% -------------------------------------------------------------------------------------
function hLines = drawLines(ds, subjList, session, arm, varName, norm2pre)
% draw the lines for all subjects in the subjList in the current axes for the arm and variable name specified
% return a list of the handles to the lines in hLines and a corresponding list of the subject numbers 

hLines = nan(1,length(subjList));

for s = 1:length(subjList),
	% baseline data point
	bl = extractBL(ds, subjList(s), arm, varName);
	bl = set(bl, 'VarNames', ['bl_' arm '_' varName]);
	% pre & post data
	[pre, p1, p2] = extractPrePost(ds, subjList(s), session, arm, varName);
	
	% if normalizing to the pre value
	if norm2pre && abs(double(pre))>eps,
% 		blPlot = (double(bl)-double(pre))/double(pre)* 100;
% 		prePlot = (double(pre)-double(pre))/double(pre) * 100;
% 		p1Plot = (double(p1)-double(pre))/double(pre) * 100;
% 		p2Plot = (double(p2)-double(pre))/double(pre) * 100;
		blPlot = double(bl)/double(pre)* 100;
		prePlot = double(pre)/double(pre) * 100;
		p1Plot = double(p1)/double(pre) * 100;
		p2Plot = double(p2)/double(pre) * 100;
	else
		blPlot = double(bl);
		prePlot = double(pre);
		p1Plot = double(p1);
		p2Plot = double(p2);
	end
	
	% draw the lines
	hBline(s) = line(0, blPlot);
	x = [1 2 3];
	hLines(s) = line(x, [prePlot p1Plot p2Plot]);
	
	if regexp(char(subjList(s)), '^s'), % subjects beginning with s are from the VA
		site = 'VA';
	else
		site = 'CCF';
	end
	setLineMark([hBline(s) hLines(s)], site, s)
end


% -------------------------------------------------------------------------------------
function setLineMark(hLine, site, subjCnt)

markerList = repmat({'o' '^' 's' 'd', 'v', '<', '>', 'p', 'h'}, [1 subjCnt]);
colorList =  repmat({'b' 'g' 'r' 'k'}, [1 subjCnt]);

switch site
	case 'VA'
		set(hLine, 'LineStyle', '-', 'MarkerFaceColor', colorList{subjCnt})
	case 'CCF'
		set(hLine, 'LineStyle', '--', 'MarkerFaceColor', 'none')
end

set(hLine, 'LineWidth', 2.0, 'Color', colorList{subjCnt}, ...
		'Marker', markerList{subjCnt}, 'MarkerSize', 12);

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
function makeYLimsAgree(axList)
% make the y limits of the axis handles sent agree

% get the limits of the first axes
ylims = get(axList(1), 'YLim');

ymin = ylims(1);
ymax = ylims(2);

% check the other axes
for axCnt = 2:length(axList)
	ylims = get(axList(axCnt), 'YLim');
	ymin = min(ymin, ylims(1));
	ymax = max(ymax, ylims(2));
end

% set the new limits
set(axList, 'YLim', [ymin ymax])
