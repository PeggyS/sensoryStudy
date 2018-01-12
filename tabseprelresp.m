function tabseprelresp(varargin)
% tabseprelresp - create table of the relative reponse value for sep measures
%
% Creates a table of the post1 response relative to the pre response for the sep measures
% for both arms.
%
% inputs in the form of parameter-value pairs:
%	'file'-'c:\path\to\filename.txt' - optional - string with the full file and pathname to the 
%		clinical measures tab delimited text file. If it
%		is not specified, then the user will be asked to identify the file
%		in a dialog box.
% 
%	
%	'subjects'-{'s2601sens';'M01'} - optional - cell array of strings for the subjects to plot. 
%		Default = all subjects - probably not recommended. Several figures are created for each subject.
%		You may run out of memory.
%
%	Note: 1st line in the text file contains the variable names. The names must be correct.
%
% file created:
%	1 row for each subject
%	columns - involved & uninvolved
%

% Author: Peggy Skelly
% 2013-10-07: created (10:06 - 11:00  = 1 hr)
%	Started from a copy of tabclinicalrelresp
%	(1:15 - 3:00) Change to just being the post1/pre for each session type & all variables
%		The mean and std dev of the pre session data is also computed. When calculating
%		the latency variables, if the latency is zero, it is changed to nan and not used.
%		For amplitudes, the zeros are averaged in.
%

% define input parser
p = inputParser;
p.addParamValue('file', 'none', @isstr);
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
% make Subj and SessType nominal variables
ds.Subj = nominal(ds.Subj);
ds.SessType = nominal(ds.SessType);

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

% each average latency and amplitude; variables with name like _un_P25Ci_avg and un_N20Ci_P25Ci_avg
vNames = get(ds, 'VarNames');
% extract all '_avg' ones
matchCellArray = regexp(vNames,'_avg');
emptyMsk = cellfun(@isempty, matchCellArray);
matchList = vNames(~emptyMsk);
% remove 'pre_' 'post1_' and 'post2_'
npVnames = regexprep(matchList, '^(pre|post1|post2)_', '');
avgVnames = unique(npVnames);

measureList = sort(avgVnames);

% dataset with column 1 = each subject
dsAllSubj = dataset([]);
% loop through each subject
for subjCnt = 1:length(subjList),
	dsAllMeas = dataset({subjList(subjCnt), 'subject'});
	for measCnt = 1:length(measureList),

% 		if subjList(subjCnt)=='M07' && strcmp(measureList{measCnt}, 'inv_N20Ci_avg'),
% 			disp('debug')
% 		end
		% get the data
		[preHi, p1Hi, p2Hi] = extractPrePost(ds, subjList(subjCnt), 'Ha', measureList{measCnt});
		[preSham, p1Sham, p2Sham] = extractPrePost(ds, subjList(subjCnt), 'Hs', measureList{measCnt});
		[preL, p1L, p2L] = extractPrePost(ds, subjList(subjCnt), 'L', measureList{measCnt});
		
		% percent relative to pre
		Hp1 = (double(p1Hi))/double(preHi);
		Shamp1 = (double(p1Sham))/double(preSham);
		Lp1 = (double(p1L))/double(preL);
		
		% ignore zeros when computing mean and std for latency values only (not
		% amplitudes)
		amplVar = regexp(measureList{measCnt}, '(N|P)\d+C(c|i)_(N|P)\d+C(c|i)', 'once');
		if isempty(amplVar),
			preHiNoZ = replacedata(preHi, @(x) changeZero2nan(x));
			preShamNoZ = replacedata(preSham, @(x) changeZero2nan(x));
			preLNoZ =    replacedata(preL, @(x) changeZero2nan(x));
			mean_pre = nanmean([double(preHiNoZ) double(preShamNoZ) double(preLNoZ)]);
			std_pre = nanstd([double(preHiNoZ) double(preShamNoZ) double(preLNoZ)]);
		else
			mean_pre = nanmean([double(preHi) double(preSham) double(preL)]);
			std_pre = nanstd([double(preHi) double(preSham) double(preL)]);			
		end
		
		
		% put into dataset
		dsMeas = dataset({Hp1, ['Hi_' measureList{measCnt}]}, ...
			{Lp1, ['Low_' measureList{measCnt}]}, ...
			{Shamp1, ['Sham_' measureList{measCnt}]}, ...
			{mean_pre, ['mean_pre_' measureList{measCnt}]}, ...
			{std_pre, ['sd_pre_' measureList{measCnt}]});

		if isempty(dsAllMeas)
			dsAllMeas = dsMeas;
		else
			dsAllMeas = horzcat(dsAllMeas, dsMeas);
		end
	end % measureList

	if isempty(dsAllSubj)
		dsAllSubj = dsAllMeas;
	else
		dsAllSubj = vertcat(dsAllSubj, dsAllMeas);
	end
end % subjList

% request where to save 
[fName, pathName] = getsavenames(fullfile(pwd, 'rel_resp.txt'), 'Save as');
if isequal(fName, 0) || isequal(pathName, 0),
	disp('Not saving. User canceled.');
	return;
end

% save
export(dsAllSubj, 'File', fullfile(pathName, fName), 'delimiter', '\t')


% -----------------------------------
function out = changeZero2nan(in)
out = in;
mask = abs(in) < eps;
out(mask) = nan;

% -------------------------------------------------------------------------------------
function [pre, post1, post2] = extractPrePost(ds, subj, session, varName)
% get the baseline data for the subj (nominal variable), session ('Hs' | 'Ha' | 'L'), 
% varName (string like 'inv_N20Ci_P25Ci_avg')

% form the variable name
varNameFull = ['pre_' varName];
% get value
pre = getdsvalue(ds, subj, session, varNameFull);

% post1
varNameFull = ['post1_' varName];
post1 = getdsvalue(ds, subj, session, varNameFull);

% post2
varNameFull = ['post2_' varName];
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

