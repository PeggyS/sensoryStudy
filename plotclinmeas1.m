function plotclinmeas1(varargin)
% plotclinmeas1 - plot clinical measures - format #1
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
% creates plots: 1 page/window for each subject
%	each row of axes = a measure
%	2 columns - involved & uninvolved
%

% Author: Peggy Skelly
% 2013-09-11: created (3:30 - 6:30 = 3 hrs)
%	2013-09-12 3:15-6:15 = 3 hrs: switched from reading in the excel file to reading in
%	a tab-delimited text file. Several columns were being read in as strings even though
%	they were numbers. It was taking too long to figure out how to detect and convert the strings to
%	numbers. So save the excel spreadsheet as a tab-delimited file, check that there are no extra 
%	rows of tabs in the text file, then read it in.
%	2013-09-13: 1 hr adding more variables and editting linestyles and markers
%	2013-09-25: 0.5 hr add input parameters 

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

% for 2pt data, if there is a value for Ncorct, but no value for 2pt_dig, then they were
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
	figure
	set(gcf, 'Position', [571 81 602 850])	% resize it
	orient tall		% make sure it prints in tall orientation
	% subject title
	h=uicontrol('Style', 'text',...
       'String', char(subjList(s)),... 
       'Units','normalized',...
	   'Fontsize', 12, ...
       'Position', [0.43 0.95 0.1 0.03]); 
	
	% axis for each measure
	subplot(5,2,1)
	title('Involved')
	ylabel('Vib 2ndigit')
	invAx = gca;
	setXaxisLimsLabels(invAx);
	drawLines(ds, subjList(s), 'inv', 'vibr_dig2_avg');
	
	subplot(5,2,2)
	title('Uninvolved')
	uninvAx = gca;
	setXaxisLimsLabels(uninvAx);
	hLines = drawLines(ds, subjList(s), 'un', 'vibr_dig2_avg');
	legend(hLines, {'BL' 'Sham' 'High' 'Low'})
	
	subplot(5,2,3)
	ylabel('Vib Elbow')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'inv', 'vibr_elbw_avg');
	
	subplot(5,2,4)
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'un', 'vibr_elbw_avg');

	subplot(5,2,5)
	ylabel('2pt Dig 1')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'inv', '2pt_thmb');
	
	subplot(5,2,6)
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'un', '2pt_thmb');

	subplot(5,2,7)
	ylabel('2pt Dig 2')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'inv', '2pt_dig2');
	
	subplot(5,2,8)
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'un', '2pt_dig2');

	subplot(5,2,9)
	ylabel('2pt Dig 4')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'inv', '2pt_dig4');
	
	subplot(5,2,10)
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'un', '2pt_dig4');

	figure
	set(gcf, 'Position', [571 81 602 850])	% resize it
	orient tall		% make sure it prints in tall orientation
	% subject title
	h=uicontrol('Style', 'text',...
       'String', char(subjList(s)),... 
       'Units','normalized',...
	   'Fontsize', 12, ...
       'Position', [0.43 0.95 0.1 0.035]); 
	
	% axis for each measure
	subplot(4,2,1)
	title('Involved')
	ylabel('mono Dig2 non')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'inv', 'monofil_dig2_nonlocal');
	
	subplot(4,2,2)
	title('Uninvolved')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'un', 'monofil_dig2_nonlocal');
	
	subplot(4,2,3)
	ylabel('mono Dig2 local')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'inv', 'monofil_dig2_local');
	
	subplot(4,2,4)
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'un', 'monofil_dig2_local');

	subplot(4,2,5)
	ylabel('mono Dig4 non')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'inv', 'monofil_dig4_nonlocal');
	
	subplot(4,2,6)
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'un', 'monofil_dig4_nonlocal');

	subplot(4,2,7)
	ylabel('mono Dig4 local')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'inv', 'monofil_dig4_local');
	
	subplot(4,2,8)
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'un', 'monofil_dig4_local');
	

	figure
	set(gcf, 'Position', [571 81 602 850])	% resize it
	orient tall		% make sure it prints in tall orientation
	% subject title
	h=uicontrol('Style', 'text',...
       'String', char(subjList(s)),... 
       'Units','normalized',...
	   'Fontsize', 12, ...
       'Position', [0.43 0.95 0.1 0.035]); 

	subplot(4,2,1)
	title('Involved')
	ylabel('Prop Dig2')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'inv', 'proprioception_index_pct');

	subplot(4,2,2)
	title('Uninvolved')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'un', 'proprioception_index_pct');
	
	subplot(4,2,3)
	ylabel('Prop Wrist')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'inv', 'proprioception_wrist_pct');
	
	subplot(4,2,4)
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'un', 'proprioception_wrist_pct');
	
	subplot(4,2,5)
	ylabel('Temp (C)')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'inv', 'temp');
	
	subplot(4,2,6)
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'un', 'temp');
	
	% Jebsen-Taylor
	figure
	set(gcf, 'Position', [571 81 602 850])	% resize it
	orient tall		% make sure it prints in tall orientation
	% subject title
	h=uicontrol('Style', 'text',...
       'String', char(subjList(s)),... 
       'Units','normalized',...
	   'Fontsize', 12, ...
       'Position', [0.43 0.95 0.1 0.035]); 
	subplot(4,2,1)
	title('Involved')
	ylabel('Small Objects')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'inv', 'smobj');

	subplot(4,2,2)
	title('Uninvolved')
	setXaxisLimsLabels(gca);
	hLines = drawLines(ds, subjList(s), 'un', 'smobj');
	legend(hLines, {'BL' 'Sham' 'High' 'Low'})
	
	subplot(4,2,3)
	ylabel('Stack Checkers')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'inv', 'stkch');
	
	
	subplot(4,2,4)
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'un', 'stkch');
	
	subplot(4,2,5)
	ylabel('Heavy Cans')
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'inv', 'hcans');
	
	subplot(4,2,6)
	setXaxisLimsLabels(gca);
	drawLines(ds, subjList(s), 'un', 'hcans');
	

end


% -------------------------------------------------------------------------------------
function hLines = drawLines(ds, subj, arm, varName)
% draw the lines in the current axes for the arm and variable name specified
% return a list of the handles to the lines in hLines

hLines = nan(1,4);

% baseline data point
bl = extractBL(ds, subj, arm, varName);
hL = line(0, bl, 'Marker', '*', 'LineStyle', 'none', 'MarkerSize', 12, 'LineWidth', 2);
hLines(1) = hL(1);
% line for each sessType
x = [1 2 3];
[pre, p1, p2] = extractPrePost(ds, subj, 'Hs', arm, varName);
hL = line(x, [pre p1 p2], 'Marker', 'o', 'LineWidth', 2.0, 'MarkerSize', 10);
hLines(2) = hL(1);
[pre, p1, p2] = extractPrePost(ds, subj, 'Ha', arm, varName);
hL = line(x, [pre p1 p2], 'Marker', '^', 'Color', [0 0.8 0], 'LineStyle', '--', ...
	'LineWidth', 2.0, 'MarkerFaceColor', [0 0.8 0], 'MarkerSize', 10);
hLines(3) = hL(1);
[pre, p1, p2] = extractPrePost(ds, subj, 'L', arm, varName);
hL = line(x, [pre p1 p2], 'Marker', 's', 'Color', 'r', 'LineStyle', ':', ...
	'LineWidth', 2.0, 'MarkerFaceColor', 'r', 'MarkerSize', 10);
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
