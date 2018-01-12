function newDs = formatclinicaldatatall(varargin)
% FORMATCLINICALDATATALL - reformat the clinical data from wide to tall spreadsheet format
%
% Takes the clincal data spreadsheet in wide (complex column/variable names) and reformats
%	in a tall format. Variable prefixes of pre-post and inv-un are transfered to columns/variables. 
%
% inputs in the form of parameter-value pairs:
%	'file'-'c:\path\to\filename.txt' - optional - string with the full file and pathname to the 
%		clinical measures tab delimited text file. If it
%		is not specified, then the user will be asked to identify the file
%		in a dialog box.
% 
%
%	Note: 1st line in the text file contains the variable names. The names must be correct.
%
% file created:
%	- 2-pt discrimination above threshold data is made consistent between the 2 sites. If
%	the threshold is above 15, then the value is replaced with '20'.
%	- all other data  is copied from the original file
%	- new variables for pre_post and inv_un

% Author: Peggy Skelly
% 2014-01-10 (10:30 - 1:00 = 2.5 hr):
%	created - Started from a copy of tabclinicalpost1norm2pre.m


% define input parser
p = inputParser;
p.addParamValue('file', 'none', @isstr);

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

% since this takes a while, display a waitbar
hwb = waitbar(0, {'Reformatting data.'});

% read in the data
ds = dataset('file', filePathName);
% make Site, Subj and SessType nominal variables
ds.Site = nominal(ds.Site);
ds.Subj = nominal(ds.Subj);
ds.SessType = nominal(ds.SessType);

% add a dateNum variable
ds.DateNum = datenum(ds.Date);

% variable names
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
	% assign value of 16 to missing values, but present counts
	dsTmp = dataset({16*ones(sum(valNanMsk & cntNanMsk),1), 'tmp'});
	ds(valNanMsk & cntNanMsk, digVarNames(v)) = dsTmp;

	% for CCF data, check for 15 in the digVarNames and a number lower than 7 in
	% digNctVarNames
	val15Msk = double(ds(:,digVarNames(v))) == 15;
	cnt7Msk = double(ds(:,digNctVarNames(v))) < 7;
	dsTmp = dataset({16*ones(sum(val15Msk & cnt7Msk),1), 'tmp'});
	ds(val15Msk & cnt7Msk, digVarNames(v)) = dsTmp;
end

% each measure
% measureList = {'vibr_dig2_avg'; ...
% 	'vibr_elbw_avg'; ...
% 	'2pt_thmb'; ...
% 	'2pt_dig2'; ...
% 	'2pt_dig4'; ...
% 	'monofil_dig2_nonlocal'; ...
% 	'monofil_dig2_local'; ...
% 	'monofil_dig4_nonlocal'; ...
% 	'monofil_dig4_local'; ...
% 	'proprioception_index_pct'; ...
% 	'proprioception_wrist_pct'; ...
% 	'temp'; ... 
% 	'smobj'; ...
% 	'stkch'; ...
% 	'hcans'};
nonMeasNam = regexp(varNames, '(Site)|(Subj)|(Date)|(SessType)|(DateNum)');	% find Site, Subj, Date and SessType variable names
mNamesIdx = cellfun(@(x) isempty(x), nonMeasNam);	% indices of empty cells
allMeasureList = varNames(mNamesIdx);
% remove pre_ post1_ post2_ inv_ and un_ from names
remStr = {'pre_' 'post1_' 'post2_' 'inv_' 'un_'};
for cnt = 1:length(remStr)
	allMeasureList = strrep(allMeasureList, remStr{cnt}, '');
end
measureList = unique(allMeasureList);

% new dataset
newDs = dataset();
% loop through each row of ds
for row = 1:length(ds),
	waitbar(row/length(ds), hwb, {'Reformatting data.';
		['Processing ... ' ]} );
	
	% skip if session type is anything other than BL, Ha, Hs, L, Ha-g, Hs-g, L-g
	if ds.SessType(row) == 'BL' || ds.SessType(row) == 'Ha' ...
			|| ds.SessType(row) == 'Hs' || ds.SessType(row) == 'L' ...
			|| ds.SessType(row) == 'Ha-g' || ds.SessType(row) == 'Hs-g' ...
			|| ds.SessType(row) == 'L-g'
	
	
		dsAllMeas = dataset();
		for measCnt = 1:length(measureList),
			dsMeas = dataset();
			% get the data
	% 		[preInv, p1Inv, p2Inv] = extractPrePost(ds, ds.Subj(row), ds.SessType(row), 'inv', measureList{measCnt});
	% 		[preUn, p1Un, p2Un] = extractPrePost(ds, ds.Subj(row), ds.SessType(row), 'un', measureList{measCnt});
			[preInv, p1Inv, p2Inv] = extractPrePost(ds, ds.Subj(row), ds.DateNum(row), 'inv', measureList{measCnt});
			[preUn, p1Un, p2Un] = extractPrePost(ds, ds.Subj(row), ds.DateNum(row), 'un', measureList{measCnt});

			% put into dataset
			dsMeas = add2ds(dsMeas, ds.Site(row), ds.Subj(row), ds.Date(row), ds.SessType(row), ...
				{'pre'}, {'inv'}, measureList{measCnt}, double(preInv));
			dsMeas = add2ds(dsMeas, ds.Site(row), ds.Subj(row), ds.Date(row), ds.SessType(row), ...
				{'post1'}, {'inv'}, measureList{measCnt}, double(p1Inv));
			dsMeas = add2ds(dsMeas, ds.Site(row), ds.Subj(row), ds.Date(row), ds.SessType(row), ...
				{'post2'}, {'inv'}, measureList{measCnt}, double(p2Inv));
			dsMeas = add2ds(dsMeas, ds.Site(row), ds.Subj(row), ds.Date(row), ds.SessType(row), ...
				{'pre'}, {'un'}, measureList{measCnt}, double(preUn));
			dsMeas = add2ds(dsMeas, ds.Site(row), ds.Subj(row), ds.Date(row), ds.SessType(row), ...
				{'post1'}, {'un'}, measureList{measCnt}, double(p1Un));
			dsMeas = add2ds(dsMeas, ds.Site(row), ds.Subj(row), ds.Date(row), ds.SessType(row), ...
				{'post2'}, {'un'}, measureList{measCnt}, double(p2Un));

			if ~isempty(dsMeas),
				if ~isempty(dsAllMeas)
					dsAllMeas = join(dsAllMeas, dsMeas, 'type', 'outer', 'mergekeys', true);
				else
					dsAllMeas = dsMeas;
				end
			end	
		end % measureList
		% add dsMeas to the final dataset
		if ~isempty(newDs)
			newDs = join(newDs, dsAllMeas, 'type', 'outer', 'mergekeys', true);
		else
			newDs = dsAllMeas;
		end
	end
end % row of ds

% close waitbar
close(hwb)

% request where to save 
[fName, pathName] = getsavenames(fullfile(pwd, 'clinicaldata_tall.txt'), 'Save as');
if isequal(fName, 0) || isequal(pathName, 0),
	disp('Not saving. User canceled.');
	return;
end

% save
export(newDs, 'File', fullfile(pathName, fName), 'delimiter', '\t')

% ------------------------------------------------------------------------------------
function ds = add2ds(ds, site, subj, dateStr, sesstype, pre_post, arm_stim, varName, val)
if ~isnan(val)
	dsTmp = dataset({site,'Site'}, {subj,'Subj'}, {dateStr,'Date'}, {sesstype,'SessType'}, ...
			{pre_post, 'pre_post'}, {arm_stim, 'arm_stim'}, {val, varName});
	ds = vertcat(ds, dsTmp);
end

% -------------------------------------------------------------------------------------
function val = extractBL(ds, subj, arm, varName)
% get the baseline data for the subj (nominal variable), arm ('inv' | 'un') and varName
% (string like 'vibr_dig2_avg')

% form the variable name
varName = ['pre_' arm '_' varName];
% get the data
val = getdsvalue(ds, subj, 'BL', varName);

% -------------------------------------------------------------------------------------
function [pre, post1, post2] = extractPrePost(ds, subj, dateNum, arm, varName)
% get the data for the subj (nominal variable), dateNum (date number), 
% arm ('inv' | 'un') and varName
% (string like 'vibr_dig2_avg')

% form the variable name
varNameFull = ['pre_' arm '_' varName];
% get value
pre = getdsvalue(ds, subj, dateNum, varNameFull);

% post1
varNameFull = ['post1_' arm '_' varName];
post1 = getdsvalue(ds, subj, dateNum, varNameFull);

% post2
varNameFull = ['post2_' arm '_' varName];
post2 = getdsvalue(ds, subj, dateNum, varNameFull);

% -------------------------------------------------------------------------------------
function val = getdsvalue(ds, subj, dateNum, varName)
% get data for the subj (nominal variable), dateNum (date number) and 
% varName (string like post2_inv_vibr_dig2_avg)
% if there is no value, return NaN not empty matrix

% verify that the varName is in the data set
dsVarNames = get(ds, 'VarNames');
if  all(cellfun(@isempty,(strfind(dsVarNames,varName))))
	% matching varNames are all empty => no matching variable => return NaN
	val = nan;
	return
end

% get value
val = ds(ds.Subj==subj & ds.DateNum==dateNum, varName);
% return nan if there is no value
if isempty(val), 
	val=nan; 
end

