function plotsepdata2(varargin)
% plotsepdata2 - plot sep measures - format #2 - per treatment type basis
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
%		Default = all subjects 
%
% creates plots: 1 page/window for each treatment type - lines for each subject
%	each row of axes = a variable
%	4 columns - involved & uninvolved X C_contraleral & C_ipsi
%

% Author: Peggy Skelly
% 2013-09-25: created (9:30 - 1:30 = 4 hrs)
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


% figure for each treatment type
treatType = {'Hs', 'Ha', 'L'};

for s = 1:length(treatType),
	varList = {'N20'; 'P25';  'N20_P25'};
	onePage(ds, treatType{s}, subjList, varList, inputs.norm);
	varList = {'P25'; 'N33';  'P25_N33'};
	onePage(ds, treatType{s}, subjList, varList, inputs.norm);
	varList = {'N33'; 'P45';  'N33_P45'};
	onePage(ds, treatType{s}, subjList, varList, inputs.norm);
end

% -----------------------------------------------------------------------------------
function onePage(ds, treatType, subjList, varList, norm2pre)
	figure
	set(gcf, 'Position', [85 222  1165 667])	% resize it
	orient tall		% make sure it prints in tall orientation
	% treatment type title
	switch treatType,
		case 'Ha'
			titleStr = 'High Frequency';
		case 'Hs'
			titleStr = 'Sham';
		case 'L'
			titleStr = 'Low Frequency';
	end
	h=uicontrol('Style', 'text',...
       'String', titleStr,... 
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
	drawLines(ds, treatType, subjList, 'inv', varNameCc, norm2pre);
	
	subplot(3,4,(row-1)*4+2)
	title('C_{ipsilateral}')
	uninvAx = gca;
	setXaxisLimsLabels(uninvAx);
	drawLines(ds, treatType, subjList, 'inv', varNameCi, norm2pre);
	
	subplot(3,4,(row-1)*4+3)
	title('C_{contrlateral}')
	setXaxisLimsLabels(gca);
	hLines = drawLines(ds, treatType, subjList, 'un', varNameCc, norm2pre);
	
	subplot(3,4,(row-1)*4+4)
	title('C_{ipsilateral}')
	setXaxisLimsLabels(gca);
	drawLines(ds, treatType, subjList, 'un', varNameCi, norm2pre);
end
legend(hLines, char(subjList))


% -------------------------------------------------------------------------------------
function hLines = drawLines(ds, session, subjList, arm, varName, norm2pre)
% draw the lines for all subjects in the current axes for the arm and variable name specified
% return a list of the handles to the lines in hLines and a corresponding list of the subject numbers 

hLines = nan(1,length(subjList));

for s = 1:length(subjList),
	% baseline data point
	bl = extractBL(ds, subjList(s), arm, varName);
	bl = set(bl, 'VarNames', ['bl_' arm '_' varName]);
	% pre & post data
	[pre, p1, p2] = extractPrePost(ds, subjList(s), session, arm, varName);
	
	if norm2pre
		% normalize bl, p1 and p2 values to the pre value -- excluding zero or nan
		if abs(double(pre)) < eps || isnan(double(pre)),	% or nan pre value
			% if pre was zero other values are set to zero, unless they were already nan, they stay nan
			% (0*nan = nan)
			% if pre was nan then other values become nan too (5*nan=nan)
			blPlot = double(pre)*double(bl);
			prePlot = double(pre);
			p1Plot = double(pre)*double(p1);
			p2Plot = double(pre)*double(p2);
		else
			% divide by pre & mult by 100 so it's a percent
			blPlot = double(bl)/double(pre) * 100;
			prePlot = double(pre)/double(pre) * 100;
			p1Plot = double(p1)/double(pre) * 100;
			p2Plot = double(p2)/double(pre) * 100;
		end
	else
		% not mormalizing
		blPlot = double(bl);
		prePlot = double(pre);
		p1Plot = double(p1);
		p2Plot = double(p2);
	end
	
	% draw the lines
	hBline(s) = line(0, blPlot);
	x = [1 2 3];
	hLines(s) = line(x, [prePlot p1Plot p2Plot]);
	
	if regexp(char(subjList(s)), '^(s|c)'), % subjects beginning with s or c are from the VA
		site = 'VA';
	else
		site = 'CCF';
	end
	setLineMark([hBline(s) hLines(s)], site, s)
end


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
set(hAx, 'XLim', [-0.5 3.5])
set(hAx, 'XTick', [0:3])
set(hAx, 'XTickLabel', {'BL' 'Pre' 'P1' 'P2'})

	
% -------------------------------------------------------------------------------------
function makeYLimsAgree(ax1, ax2)
% HERE ---
