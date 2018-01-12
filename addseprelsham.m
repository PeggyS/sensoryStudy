function finalDS = addseprelsham(varargin)
%ADDSEPRELSHAM - add columns for each variable with the post/pre  and session/sham
% relative variables
%
% input in the form of parameter-value pairs:
%	'file'-'c:\path\to\filename.txt' - optional - string with the full file and pathname to the 
%		 tab delimited text file. If it is not specified, then the user will be asked to
%		 choose it in a dialog box.
%
%		The file must be in the tall format. Use formatSep2.m to generate it from the data
%		in the pre.xlsx, post1.xlsx, etc files in the subject/date/ directory hierarchy.

% Author: Peggy Skelly
% 2014-02-07 (1:00 - 6:00): 
%	created from copy of addpostminuspre.m

% define input parser
p = inputParser;
p.addParamValue('file', 'none', @isstr);

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

% read in the file
disp(['reading in ' filePathName '...'])
dsIn = dataset('file', filePathName);
% make variables nominal
varCols = {'Subj' 'arm_stim' 'CcCi' 'pre_post' 'SessType'};
for v = 1:length(varCols)
	% make the variable nominal
	dsIn.(varCols{v}) = nominal(dsIn.(varCols{v}));
end
finalDs = dsIn;

% get the variable names and add additional ones
varNames = get(dsIn, 'VarNames');
numVarNames = regexp(varNames, '^(N|P)\d+');
nonNumVarMsk = cellfun(@isempty, numVarNames);
numVarList = varNames(~nonNumVarMsk);
% add a new variable for each existing numVarList
dumVar = nan(size(dsIn, 1), 1);
for nv = 1:length(numVarList)
	finalDs.(['rel_' numVarList{nv}]) = dumVar;
end
for nv = 1:length(numVarList)
	finalDs.(['rel_sham_' numVarList{nv}]) = dumVar;
end

armList = unique(dsIn.arm_stim);
ciList = unique(dsIn.CcCi);

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
				p1row = find(dsIn.pre_post=='post1' & dsIn.Subj==subjList(s) & dsIn.SessType==stList(st) & ...
					dsIn.arm_stim==dsIn.arm_stim(preInd(p)) & dsIn.CcCi==dsIn.CcCi(preInd(p)));
				p2row = find(dsIn.pre_post=='post2' & dsIn.Subj==subjList(s) & dsIn.SessType==stList(st) & ...
					dsIn.arm_stim==dsIn.arm_stim(preInd(p)) & dsIn.CcCi==dsIn.CcCi(preInd(p)));
				if ~isempty(p1row)
					for nv = 1:length(numVarList)
						val = dsIn.(numVarList{nv})(p1row) / dsIn.(numVarList{nv})(preInd(p));
						finalDs.(['rel_' numVarList{nv}])(p1row) = val;
						val = dsIn.(numVarList{nv})(p2row) / dsIn.(numVarList{nv})(preInd(p));
						finalDs.(['rel_' numVarList{nv}])(p2row) = val;
					end
				end
			end
		end
		
	end % sessType list
	
	% if there is sham data, create rel_sham_ value
	for aa = 1:length(armList),
		for cc = 1:length(ciList),
			preShamInd = find(finalDs.Subj==subjList(s) & finalDs.arm_stim==armList(aa) & ...
							finalDs.CcCi==ciList(cc) & finalDs.SessType=='Hs' & finalDs.pre_post=='pre');
			post1ShamInd = find(finalDs.Subj==subjList(s) & finalDs.arm_stim==armList(aa) & ...
								finalDs.CcCi==ciList(cc) & finalDs.SessType=='Hs' & finalDs.pre_post=='post1');
			post2ShamInd = find(finalDs.Subj==subjList(s) & finalDs.arm_stim==armList(aa) & ...
								finalDs.CcCi==ciList(cc) & finalDs.SessType=='Hs' & finalDs.pre_post=='post2');
			preHiInd = find(finalDs.Subj==subjList(s) & finalDs.arm_stim==armList(aa) & ...
								finalDs.CcCi==ciList(cc) & finalDs.SessType=='Ha' & finalDs.pre_post=='pre');
			post1HiInd = find(finalDs.Subj==subjList(s) & finalDs.arm_stim==armList(aa) & ...
								finalDs.CcCi==ciList(cc) & finalDs.SessType=='Ha' & finalDs.pre_post=='post1');
			post2HiInd = find(finalDs.Subj==subjList(s) & finalDs.arm_stim==armList(aa) & ...
								finalDs.CcCi==ciList(cc) & finalDs.SessType=='Ha' & finalDs.pre_post=='post2');
			preLoInd = find(finalDs.Subj==subjList(s) & finalDs.arm_stim==armList(aa) & ...
								finalDs.CcCi==ciList(cc) & finalDs.SessType=='L' & finalDs.pre_post=='pre');
			post1LoInd = find(finalDs.Subj==subjList(s) & finalDs.arm_stim==armList(aa) & ...
								finalDs.CcCi==ciList(cc) & finalDs.SessType=='L' & finalDs.pre_post=='post1');
			post2LoInd = find(finalDs.Subj==subjList(s) & finalDs.arm_stim==armList(aa) & ...
								finalDs.CcCi==ciList(cc) & finalDs.SessType=='L' & finalDs.pre_post=='post2');
			for nv = 1:length(numVarList)
				if ~isempty(post1LoInd) && ~isempty(post1ShamInd),
					for pp = 1:length(post1LoInd)
						val = finalDs.(['rel_' numVarList{nv}])(post1LoInd(pp)) / mean(finalDs.(['rel_' numVarList{nv}])(post1ShamInd));
						finalDs.(['rel_sham_' numVarList{nv}])(post1LoInd(pp)) = val;
					end
				end
				if ~isempty(post2LoInd) && ~isempty(post2ShamInd),
					for pp = 1:length(post2LoInd)
						val = finalDs.(['rel_' numVarList{nv}])(post2LoInd(pp)) / mean(finalDs.(['rel_' numVarList{nv}])(post2ShamInd));
						finalDs.(['rel_sham_' numVarList{nv}])(post2LoInd(pp)) = val;
					end
				end				
				if ~isempty(post1HiInd) && ~isempty(post1ShamInd),
					for pp = 1:length(post1HiInd)
						val = finalDs.(['rel_' numVarList{nv}])(post1HiInd(pp)) / mean(finalDs.(['rel_' numVarList{nv}])(post1ShamInd));
						finalDs.(['rel_sham_' numVarList{nv}])(post1HiInd(pp)) = val;
					end
				end
				if ~isempty(post2HiInd) && ~isempty(post2ShamInd),
					for pp = 1:length(post2HiInd)
						val = finalDs.(['rel_' numVarList{nv}])(post2HiInd(pp)) / mean(finalDs.(['rel_' numVarList{nv}])(post2ShamInd));
						finalDs.(['rel_sham_' numVarList{nv}])(post2HiInd(pp)) = val;
					end
				end
			end
		end
	end
	
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
