function tabclinicalrelresp(varargin)
% tabclinicalrelresp - create table of the relative reponse value for each measure
%
% Creates a table of the response relative to the sham response for each clinical measure
% for involved arms. It uses clinical data in the wide table format with variable names
% like  post2_inv_vibr_dig2_avg. 
%
% inputs in the form of parameter-value pairs:
%	'file'-'c:\path\to\filename.txt' - optional - string with the full file and pathname to the 
%		clinical measures tab delimited text file. If it is not specified, then the user will be 
%		asked to identify the file in a dialog box.
%
%		Note: Clinical data must be in the wide table format with variable names
%			like  post2_inv_vibr_dig2_avg. 1st line in the text file contains the variable names and
%			they must be correct.
%	
%	'subjects'-{'s2601sens';'M01'} - optional - cell array of strings for the subjects to plot. 
%		Default = all subjects - probably not recommended. Several figures are created for each subject.
%		You may run out of memory.
%
%
% file created:
%	1 row for each subject
%	columns - involved & uninvolved
%

% Author: Peggy Skelly
% 2013-09-30: created (12:50 -   = 1.5 hrs)
%	Started from a copy of plotclinmeas2
% 2013-10-08 (1:55 - 4:10 = 2.25 hrs) 
%	Add provision for dealing with proprioception data differently. All other measures are
%	scaled so that lower values are better. Proprioception (% correct) is opposite 100% is
%	best 50% worst. To accommodate, change proprioception values to 10^(1-value/100) before
%	normalizing and computing relative response. ** not sure this is the way to go ***
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

% each measure
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

% dataset with column 1 = each subject
dsAllSubj = dataset([]);
% loop through each subject
for subjCnt = 1:length(subjList),
	dsAllMeas = dataset({subjList(subjCnt), 'subject'});
	for measCnt = 1:length(measureList),
		% get the data
		[preHi, p1Hi, p2Hi] = extractPrePost(ds, subjList(subjCnt), 'Ha', 'inv', measureList{measCnt});
		[preSham, p1Sham, p2Sham] = extractPrePost(ds, subjList(subjCnt), 'Hs', 'inv', measureList{measCnt});
		[preL, p1L, p2L] = extractPrePost(ds, subjList(subjCnt), 'L', 'inv', measureList{measCnt});
		
		% handle proprioception data differently. All other measures are
		%	scaled so that lower values are better. Proprioception (% correct) is opposite: 100% is
		%	best, 50% worst. To accommodate, change proprioception values to % wrong (100-value) before
		%	normalizing and computing relative response.
		if strncmp(measureList{measCnt}, 'proprioc', 8),
% 			preHi = replacedata(preHi, @(x) 10^(1-x/100));
% 			p1Hi = replacedata(p1Hi, @(x) 10^(1-x/100));
% 			p2Hi = replacedata(p2Hi, @(x) 10^(1-x/100));
% 			preSham = replacedata(preSham, @(x) 10^(1-x/100));
% 			p1Sham = replacedata(p1Sham, @(x) 10^(1-x/100));
% 			p2Sham = replacedata(p2Sham, @(x) 10^(1-x/100));
% 			preL = replacedata(preL, @(x) 10^(1-x/100));
% 			p1L = replacedata(p1L, @(x) 10^(1-x/100));
% 			p2L = replacedata(p2L, @(x) 10^(1-x/100));
			preHi = replacedata(preHi, @(x) 100-x+100);
			p1Hi = replacedata(p1Hi, @(x) 100-x+100);
			p2Hi = replacedata(p2Hi, @(x) 100-x+100);
			preSham = replacedata(preSham, @(x) 100-x+100);
			p1Sham = replacedata(p1Sham, @(x) 100-x+100);
			p2Sham = replacedata(p2Sham, @(x) 100-x+100);
			preL = replacedata(preL, @(x) 100-x+100);
			p1L = replacedata(p1L, @(x) 100-x+100);
			p2L = replacedata(p2L, @(x) 100-x+100);
		end
		% percent relative to pre
		if abs(double(preHi)) > eps
			Hp1 = (double(p1Hi))/double(preHi);
		else
			Hp1 = (double(p1Hi));
		end
		if abs(double(preSham)) > eps
			Shamp1 = (double(p1Sham))/double(preSham);
		else
			Shamp1 = (double(p1Sham));
		end
		if abs(double(preL)) > eps
			Lp1 = (double(p1L))/double(preL);
		else
			Lp1 = (double(p1L));
		end
		% ratio of treatment to sham
		Hr = Hp1 / Shamp1;
		Lr = Lp1 / Shamp1;
		
		% put into dataset
		dsMeas = dataset({Hr, ['Hr_' measureList{measCnt}]}, {Lr, ['Lr_' measureList{measCnt}]});
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

