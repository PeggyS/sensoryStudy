function finalDS = addpostminuspre(varargin)
%ADDPOSTMINUSPRE - add columns for each variable with the post value minus pre value
%
% input in the form of parameter-value pairs:
%	'file'-'c:\path\to\filename.txt' - optional - string with the full file and pathname to the 
%		 tab delimited text file. If it is not specified, then the user will be asked to
%		 choose it in a dialog box.
%
%		The file must be in the tall format. Use formatSep2.m to generate it from the data
%		in the pre.xlsx, post1.xlsx, etc files in the subject/date/ directory hierarchy.

% Author: Peggy Skelly
% 2014-01-08 (5:00 - 6:00): 
% 2014-01-09 (10:00- 11:00):
%	created 
% 2014-06-25
%	modify to handle clinical data, not just sep data

% define input parser
p = inputParser;
p.addParamValue('file', 'none', @isstr);

% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none'),		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.txt', 'Pick tall format data tab delimited file');
	if isequal(fname,0) || isequal(pathname,0)
		disp('User canceled. Exitting')
		return
	else
		filePathName = fullfile(pathname,fname);
	end
else
	filePathName = inputs.file;
end

% read in the file
disp(['reading in ' filePathName '...'])
dsIn = dataset('file', filePathName);

varNames = get(dsIn, 'VarNames');

% make variables nominal
if sum(strcmp(varNames, 'CcCi')) > 0
	ciFlg = true;
	varCols = {'Subj' 'arm_stim' 'CcCi' 'pre_post' 'SessType'};
else
	ciFlg = false;
	varCols = {'Subj' 'arm_stim' 'pre_post' 'SessType'};
end
for v = 1:length(varCols)
	% make the variable nominal
	dsIn.(varCols{v}) = nominal(dsIn.(varCols{v}));
end
finalDs = dsIn;

dsIn.DateNum = datenum(dsIn.Date);

% get the variable names and add additional ones
if ciFlg			%% sep data
	numVarNames = regexp(varNames, 'N|P\d+');
	nonNumVarMsk = cellfun(@isempty, numVarNames);
	numVarList = varNames(~nonNumVarMsk);
else			%% clinical data
	nonMeasNam = regexp(varNames, '(Site)|(Subj)|(Date)|(SessType)|(DateNum)|(pre_post)|(arm_stim)');	% find Site, Subj, Date and SessType variable names
	mNamesIdx = cellfun(@(x) isempty(x), nonMeasNam);	% indices of empty cells
	allMeasureList = varNames(mNamesIdx);
	% remove pre_ post1_ post2_ inv_ and un_ from names
	remStr = {'pre_' 'post1_' 'post2_' 'inv_' 'un_'};
	for cnt = 1:length(remStr)
		allMeasureList = strrep(allMeasureList, remStr{cnt}, '');
	end
	numVarList = unique(allMeasureList);
end
	
% add a new variable for each existing numVarList
dumVar = nan(size(dsIn, 1), 1);
for nv = 1:length(numVarList)
	finalDs.(['d_' numVarList{nv}]) = dumVar;
end

% for each Subj, SessType
subjList = unique(dsIn.Subj);
for s = 1:length(subjList)
	stList = unique(dsIn.SessType);
	for st = 1:length(stList),
		% if there is pre data, compute the difference for 4 values of arm_stim X CcCi: inv-c inv-i un-c un-i
		preInd = find(dsIn.pre_post=='pre' & dsIn.Subj==subjList(s) & dsIn.SessType==stList(st));
		if(~isempty(preInd))
			for p = 1:length(preInd)
				% get the corresponding post1 and post2 row index
				if ciFlg
					% should these lines also include dateNum?? FIXME
					p1row = find(dsIn.pre_post=='post1' & dsIn.Subj==subjList(s) & dsIn.SessType==stList(st) & ...
						dsIn.arm_stim==dsIn.arm_stim(preInd(p)) & dsIn.CcCi==dsIn.CcCi(preInd(p)));
					p2row = find(dsIn.pre_post=='post2' & dsIn.Subj==subjList(s) & dsIn.SessType==stList(st) & ...
						dsIn.arm_stim==dsIn.arm_stim(preInd(p)) & dsIn.CcCi==dsIn.CcCi(preInd(p)));
				else
					p1row = find(dsIn.pre_post=='post1' & dsIn.Subj==subjList(s) & dsIn.SessType==stList(st) & ...
						dsIn.arm_stim==dsIn.arm_stim(preInd(p)) & dsIn.DateNum==dsIn.DateNum(preInd(p)));
					p2row = find(dsIn.pre_post=='post2' & dsIn.Subj==subjList(s) & dsIn.SessType==stList(st) & ...
						dsIn.arm_stim==dsIn.arm_stim(preInd(p)) & dsIn.DateNum==dsIn.DateNum(preInd(p)));
				end
				if ~isempty(p1row)
					for nv = 1:length(numVarList)
						finalDs.(['d_' numVarList{nv}])(preInd(p)) = 0;
						val = dsIn.(numVarList{nv})(p1row) - dsIn.(numVarList{nv})(preInd(p));
						finalDs.(['d_' numVarList{nv}])(p1row) = val;
						val = dsIn.(numVarList{nv})(p2row) - dsIn.(numVarList{nv})(preInd(p));
						finalDs.(['d_' numVarList{nv}])(p2row) = val;
					end
				end
			end
		end
		
	end % sessType list
end % subjList

% request save name
[fnameSave, pathnameSave] = uiputfile('*.txt', 'Save new file as ...');

% save
if isequal(fnameSave,0) || isequal(pathnameSave,0)
   disp('User pressed cancel. Nothing will be saved.')
else
	disp(['saving ' fullfile(pathnameSave, fnameSave)])
	export(finalDs, 'file', fullfile(pathnameSave, fnameSave), 'delimiter', '\t');
end

disp('done')
