function finalDS = addclinicalrelmeas(varargin)
%ADDCLINICALRELMEAS - add columns for pre-post relative variables
%
% input in the form of parameter-value pairs:
%	'file'-'c:\path\to\filename.txt' - optional - string with the full file and pathname to the 
%		 tab delimited text file. If it is not specified, then the user will be asked to
%		 choose it in a dialog box.
%
%		The file must be in the tall format. Use formatclincaldatatall.m to convert from
%		the wide format to the tall.

% Author: Peggy Skelly
% 2014-01-10 2:00 - 3:30 (1.5 hrs)
%	created from copy of addpostminuspre.m

% define input parser
p = inputParser;
p.addParamValue('file', 'none', @isstr);

% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none'),		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.txt', 'Pick clinical data tab delimited file (tall format)');
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

% make variables nominal
varCols = {'Subj' 'arm_stim' 'pre_post' 'SessType'};
for v = 1:length(varCols)
	% make the variable nominal
	dsIn.(varCols{v}) = nominal(dsIn.(varCols{v}));
end

finalDs = dsIn;

dsIn.DateNum = datenum(dsIn.Date);

% define the variable names/measures and add additional ones
% measureList = {'vibr_dig2_avg'; ...
% 	'vibr_elbw_avg'; ...
% 	'x2pt_thmb'; ...
% 	'x2pt_dig2'; ...
% 	'x2pt_dig4'; ...
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

% variable names
varNames = get(dsIn, 'VarNames');

nonMeasNam = regexp(varNames, '(Site)|(Subj)|(Date)|(SessType)|(DateNum)|(pre_post)|(arm_stim)');	% find Site, Subj, Date and SessType variable names
mNamesIdx = cellfun(@(x) isempty(x), nonMeasNam);	% indices of empty cells
allMeasureList = varNames(mNamesIdx);
% remove pre_ post1_ post2_ inv_ and un_ from names
remStr = {'pre_' 'post1_' 'post2_' 'inv_' 'un_'};
for cnt = 1:length(remStr)
	allMeasureList = strrep(allMeasureList, remStr{cnt}, '');
end
measureList = unique(allMeasureList);

% add a new variable for each existing numVarList
dumVar = nan(size(dsIn, 1), 1);
for nv = 1:length(measureList)
	finalDs.(['rel_' measureList{nv}]) = dumVar;
end
for nv = 1:length(measureList)
	finalDs.(['rel_sham_' measureList{nv}]) = dumVar;
end

% for each Subj, SessType
subjList = unique(dsIn.Subj);
for s = 1:length(subjList)
	armList = unique(dsIn.arm_stim);
	for a = 1:length(armList)
		
		stList = unique(dsIn.SessType);
		for st = 1:length(stList),
			% if there is pre data, compute the rel_ values 
			preInd = find(dsIn.pre_post=='pre' & dsIn.Subj==subjList(s) & dsIn.SessType==stList(st));
			if(~isempty(preInd))
				for p = 1:length(preInd)
					% get the corresponding post1 and post2 row index
					p1row = find(dsIn.pre_post=='post1' & dsIn.Subj==subjList(s) & dsIn.SessType==stList(st) & ...
						dsIn.arm_stim==dsIn.arm_stim(preInd(p)) & dsIn.DateNum==dsIn.DateNum(preInd(p)));
					p2row = find(dsIn.pre_post=='post2' & dsIn.Subj==subjList(s) & dsIn.SessType==stList(st) & ...
						dsIn.arm_stim==dsIn.arm_stim(preInd(p)) & dsIn.DateNum==dsIn.DateNum(preInd(p)));
					if ~isempty(p1row)
						for nv = 1:length(measureList)
							val = dsIn.(measureList{nv})(p1row) / dsIn.(measureList{nv})(preInd(p));
							finalDs.(['rel_' measureList{nv}])(p1row) = val;
							val = dsIn.(measureList{nv})(p2row) / dsIn.(measureList{nv})(preInd(p));
							finalDs.(['rel_' measureList{nv}])(p2row) = val;
						end
					end
				end
			end
		
	end % sessType list
		% extract the data for each session
		preShamInd = find(dsIn.pre_post=='pre' & dsIn.Subj==subjList(s) & dsIn.SessType=='Hs' & dsIn.arm_stim==armList(a));
		post1ShamInd = find(dsIn.pre_post=='post1' & dsIn.Subj==subjList(s) & dsIn.SessType=='Hs' & dsIn.arm_stim==armList(a));
		post2ShamInd = find(dsIn.pre_post=='post2' & dsIn.Subj==subjList(s) & dsIn.SessType=='Hs' & dsIn.arm_stim==armList(a));
		preHiInd = find(dsIn.pre_post=='pre' & dsIn.Subj==subjList(s) & dsIn.SessType=='Ha' & dsIn.arm_stim==armList(a));
		post1HiInd = find(dsIn.pre_post=='post1' & dsIn.Subj==subjList(s) & dsIn.SessType=='Ha' & dsIn.arm_stim==armList(a));
		post2HiInd = find(dsIn.pre_post=='post2' & dsIn.Subj==subjList(s) & dsIn.SessType=='Ha' & dsIn.arm_stim==armList(a));
		preLoInd = find(dsIn.pre_post=='pre' & dsIn.Subj==subjList(s) & dsIn.SessType=='L' & dsIn.arm_stim==armList(a));
		post1LoInd = find(dsIn.pre_post=='post1' & dsIn.Subj==subjList(s) & dsIn.SessType=='L' & dsIn.arm_stim==armList(a));
		post2LoInd = find(dsIn.pre_post=='post2' & dsIn.Subj==subjList(s) & dsIn.SessType=='L' & dsIn.arm_stim==armList(a));
		for nv = 1:length(measureList)
% 
% 			if  ~isempty(preShamInd) && ~isempty(post1ShamInd)
% 				valRelBot = dsIn.(measureList{nv})(post1ShamInd) / dsIn.(measureList{nv})(preShamInd);
% 				finalDs.(['rel_' measureList{nv}])(post1ShamInd) = valRelBot;
% 				if ~isempty(preHiInd) && ~isempty(post1HiInd)
% 					% compute the ratio relative values
% 					valRelTop = dsIn.(measureList{nv})(post1HiInd) / dsIn.(measureList{nv})(preHiInd);
% 					finalDs.(['rel_' measureList{nv}])(post1HiInd) = valRelTop;
% 					valRel = valRelTop / valRelBot;
% 					finalDs.(['rel_sham_' measureList{nv}])(post1HiInd) = valRel;
% 				end
% 				if ~isempty(preLoInd) && ~isempty(post1LoInd)
% 					% compute the ratio relative values
% 					valRelTop = dsIn.(measureList{nv})(post1LoInd) / dsIn.(measureList{nv})(preLoInd);
% 					finalDs.(['rel_' measureList{nv}])(post1LoInd) = valRelTop;
% 					valRel = valRelTop / valRelBot;
% 					finalDs.(['rel_sham_' measureList{nv}])(post1LoInd) = valRel;
% 				end
% 			end
% 			if  ~isempty(preShamInd) && ~isempty(post2ShamInd)
% 				valRelBot = dsIn.(measureList{nv})(post2ShamInd) / dsIn.(measureList{nv})(preShamInd);
% 				finalDs.(['rel_' measureList{nv}])(post2ShamInd) = valRelBot;
% 				if ~isempty(preHiInd) && ~isempty(post2HiInd)
% 					% compute the ratio relative values
% 					valRelTop = dsIn.(measureList{nv})(post2HiInd) / dsIn.(measureList{nv})(preHiInd);
% 					finalDs.(['rel_' measureList{nv}])(post2HiInd) = valRelTop;
% 					valRel = valRelTop / valRelBot;
% 					finalDs.(['rel_sham_' measureList{nv}])(post2HiInd) = valRel;
% 				end
% 				if ~isempty(preLoInd) && ~isempty(post2LoInd)
% 					% compute the ratio relative values
% 					valRelTop = dsIn.(measureList{nv})(post2LoInd) / dsIn.(measureList{nv})(preLoInd);
% 					finalDs.(['rel_' measureList{nv}])(post2LoInd) = valRelTop;
% 					valRel = valRelTop / valRelBot;
% 					finalDs.(['rel_sham_' measureList{nv}])(post2LoInd) = valRel;
% 				end
% 			end
			if ~isempty(post1LoInd) && ~isempty(post1ShamInd),
				for pp = 1:length(post1LoInd)
					val = finalDs.(['rel_' measureList{nv}])(post1LoInd(pp)) / mean(finalDs.(['rel_' measureList{nv}])(post1ShamInd));
					finalDs.(['rel_sham_' measureList{nv}])(post1LoInd(pp)) = val;
				end
			end
			if ~isempty(post2LoInd) && ~isempty(post2ShamInd),
				for pp = 1:length(post2LoInd)
					val = finalDs.(['rel_' measureList{nv}])(post2LoInd(pp)) / mean(finalDs.(['rel_' measureList{nv}])(post2ShamInd));
					finalDs.(['rel_sham_' measureList{nv}])(post2LoInd(pp)) = val;
				end
			end				
			if ~isempty(post1HiInd) && ~isempty(post1ShamInd),
				for pp = 1:length(post1HiInd)
					val = finalDs.(['rel_' measureList{nv}])(post1HiInd(pp)) / mean(finalDs.(['rel_' measureList{nv}])(post1ShamInd));
					finalDs.(['rel_sham_' measureList{nv}])(post1HiInd(pp)) = val;
				end
			end
			if ~isempty(post2HiInd) && ~isempty(post2ShamInd),
				for pp = 1:length(post2HiInd)
					val = finalDs.(['rel_' measureList{nv}])(post2HiInd(pp)) / mean(finalDs.(['rel_' measureList{nv}])(post2ShamInd));
					finalDs.(['rel_sham_' measureList{nv}])(post2HiInd(pp)) = val;
				end
			end
		end	
	end % each arm

end % subjList

disp('Done')

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
