function finalDS = formatSep2(startDir)
% formatSep2 - read in sep data (excel files in directory structure) and reformat into a single spreadsheet
% startDir - the starting directory string
%			directory structure: base/subjNum/date/sepExcelFiles.xlsx
%				subjNum = [s|c]26##sens, ex: s2601sens, c2602sens (for the VA only)
%						for the CCF subjects are M01, M12, etc.
%				date = date of data collection (yyyymmdd)
%				sepExcelFiles.xlsx = pre.xlsx, post1.xlsx, post2.xlsx 
%					Required format 
%				col 1= Trial = numbered trial string with L or R indicating the
%					stimulated arm, e.g. 'Trial4 - L'; trial numbers should be in
%					sequential order for each arm
%				cols 2-> = the peak latency or the peak-to-peak amplitude 
%					peak: N20C3; amplitude: N20C4_P25C4
%					value 999 indicates bad data
%					empty cells (read in as NaN) are valid data but no peak present
%
%			base/subjNum/involvedside.txt - should contain the word right or left
%			base/dates_sessTypes.txt - tab delimited text file with subject, date and
%			session type
%
% The formatted data is saved in the baseDir in a file named sepdata.txt or other name
% chosen by the user. 
%
% In this version, all zeros for latencies and p2p values are replaced with NaNs
%
% Note: the latency times for the VA are in milliSeconds. CCF data is in seconds. This
% function will convert CCF latencies to msec.

% Author: Peggy Skelly
% 2014-01-08 11:00 - 3:45 (4.75 hrs): create from copy of formatSep.m


finalDS = dataset();

% since this takes a while, display a waitbar
hwb = waitbar(0, {'Combining SEP data into a single table.'; 'Finding subjects'});

% if startDir is not specified, use the current working directory
if nargin < 1,
	startDir = pwd;
end

% begin at the baseDir and get all the subjects
%dirList = dir(baseDir);
subjList = findregexpdir(startDir, '([sc]26\d\dsens)|(^M\d+)'); %% matches subject number format
baseDir = startDir;

% if subjList is empty, check to see if the startDir contains the subject
if isempty(subjList)
    [subjList, ind] = regexpi(startDir, '([sc]26\d\dsens)', 'match', 'start'); %% matches subject number format
    if isempty(subjList)    % still empty - unknown subject - return
        disp(['could not detect a subject in the directory: ' startDir])
        return
    end
    baseDir = startDir(1:ind-1);
end

session = {'pre' 'post1' 'post2'};

% read in the file listing the sessions
fname = fullfile(baseDir,'dates_sessTypes.txt');
if exist(fname, 'file'),
	sessTypeDs = dataset('file', fname);
	sessTypeDs.Subj = nominal(sessTypeDs.Subj);
	sessTypeDs.Date = datestr(datenum(num2str(sessTypeDs.Date),'yyyymmdd'));
else
	error('the file dates_sessTypes.txt must be in: ', baseDir);
	return
end


% turn off a warning about renaming the variables when read into the dataset
if verLessThan('matlab', '7.10')
	sw=warning('off', 'stats:dataset:setvarnames:ModifiedVarnames');		% ML2007a
elseif verLessThan('matlab', '8.1')
	sw=warning('off','stats:dataset:genvalidnames:ModifiedVarnames');		% ML2010a - 7.10
else
	sw=warning('off','MATLAB:codetools:ModifiedVarnames');		% ML2013a - 8.1
end

% loop through each subject
for i = 1:length(subjList),
	
	% read in the file listing their involved side
	fname = fullfile(baseDir,subjList{i},'involvedside.txt');
	if exist(fname, 'file'),
		fid = fopen(fname);
		s = textscan(fid, '%s');
		side = char(lower(s{1}));
		fclose(fid);
		
		if ~(strcmp(side, 'left') || strcmp(side, 'right')),
			error('read in %s from %s - allowable file entries are left and right only', side, fname)
		end
    else
		error('the file involvedside.txt must be in the subject, %s, folder', subjList{i});
	end
%	if strcmp(subjList{i}, 's2604sens')
%		keyboard
%	end
	% look for the date in the startDir
	dateList = regexpi(startDir, '\d{8}$', 'match');
	if isempty(dateList)	% look within the directory structure
		% find subfolders with recording dates
		dateList = findregexpdir(fullfile(baseDir,subjList{i}), '^\d{8}$'); %% folder must be 8 digits only - the date in the format yyyymmdd
	end
	subjDs = dataset();

	% for each date
	for j = 1:length(dateList),
		oneDaysData = [];
		% update the waitbar
		waitbar(j/length(dateList), hwb, {'Combining SEP data into a single table.';
		['Processing subject ' subjList{i} ' ' num2str(i) '/' num2str(length(subjList))]} );
	
		sessTypeIndex = find(datenum(sessTypeDs.Date)==datenum(dateList{j},'yyyymmdd') & ...
				sessTypeDs.Subj==subjList{i});
		assert(~isempty(sessTypeIndex), 'Did not find a session type for %s on %s in file %s', ...
			subjList{i}, dateList{j}, fullfile(baseDir,'dates_sessTypes.txt'))
			
		sessType = sessTypeDs.SessType(sessTypeIndex);
		
		doNotUse = strfind(sessType,['don''t use']);
		if isempty(doNotUse{:})
			% for each session (pre, post1, post2)
			for k = 1:length(session), 
	%			disp(subjList{i})

				% read the excel file into a dataset
				fname = fullfile(baseDir,subjList{i},dateList{j},[session{k} '.xlsx']);
				if exist(fname, 'file'),
					disp(fname)

					% read in the data
					ds = dataset('xlsfile', fname);

					% enforce consistent variable naming
					vnames = get(ds, 'VarNames');
					strLatency = '(N|P)(\d{2,3})(_)C(3|4)';
					consistentVnames = regexprep(vnames, strLatency,'$1$2C$4');
					ds = set(ds, 'VarNames', consistentVnames);

					% replace all NaNs with -1, indicating no peak was present. Later we'll
					% change these to zeros, but we need to use this flag to make sure zero
					% values do not get averaged in with others
					trVar = regexpi(consistentVnames, 'trial');
					numVarMsk = cellfun(@isempty, trVar);
					numVarList = consistentVnames(numVarMsk);
					try
						ds = replacedata(ds, @(x) changeNan2negone(x), numVarList);
					catch ME
						throw(addCause(MException('formatSep2:replacedataFail','%s not read in properly.',fname),ME));
% 						error('Error with data in %s', fname);
					end
					

					% replace all values of 999 with NaN, indicating bad or missing data
					ds = replacedata(ds, @(x) replace999withnan(x), numVarList);

					% if a CCF subject, convert latencies from sec to msec
					if strncmp(subjList{i}, 'M', 1)
						% latency variable names
						latVars = regexpi(consistentVnames, '(_)|(Trial)');	% ones containing _ are not latencies
						latVarMsk = cellfun(@isempty, latVars);
						latVarList = consistentVnames(latVarMsk);

						% multiply values by 1000
						ds = replacedata(ds, @(x) x*1000, latVarList);
					end

					% add it to the day's struct
					oneDaysData.(session{k}) = ds;
				else
					ds = [];
				end
			end	%% session for loop

			% format data for one day and add to the complete dataset
			if ~isempty(oneDaysData),
				% put all data in 1 row and add computed average variables making sure to not
				% average the -1 (and -0.001) values
				oneDayDs = formatDStable(oneDaysData, side);

				% now replace all -1 (and -0.001) with zeros - ok data but
				% add the subject and session date to the row
				allVnames = get(oneDayDs, 'VarNames');
				numVar = regexpi(allVnames, '\d');
				nonNumVarMsk = cellfun(@isempty, numVar);
				numVarList = allVnames(~nonNumVarMsk);
				oneDayDs = replacedata(oneDayDs, @(x) changeNegOne2nan(x), numVarList);

				% add the sessType for that date
				oneDayDs = prependDs(oneDayDs, 'SessType', sessType);
				% add the date
				oneDayDs = prependDs(oneDayDs, 'Date', {datestr(datenum(dateList{j}, 'yyyymmdd'))});
			end
			subjDs = mergedatasets(subjDs, oneDayDs);
		end % if it's not marked to not use
	end	%% dateList

	% add the subject and their involved arm
	subjDs = prependDs(subjDs, 'inv_arm', {side} );
	subjDs = prependDs(subjDs, 'Subj', subjList(i));

	% add that row to the final dataset
	finalDS = mergedatasets(finalDS, subjDs);	

end %% subjList


% turn back on the warning about renaming the variables when read into the dataset
warning(sw);

% close waitbar
close(hwb)

% request where to save 
[fName, pathName] = getsavenames(fullfile(startDir, 'sepdata.txt'), 'Save as');
if isequal(fName, 0) || isequal(pathName, 0),
	disp('Not saving. User canceled.');
	return;
end

if verLessThan('matlab', '7.10')		% for versions older than ML 2010a
	writeDataset(finalDS, fullfile(pathName,fName), '\t')
else
	export(finalDS, 'File', fullfile(pathName, fName), 'delimiter', '\t');
end


% ------------------
function out = changeNan2zero(in)
out = in;
out(isnan(out)) = 0;

function out = replace999withnan(in)
out = in;
mask = in >= 999;
out(mask) = nan;

function out = changeNan2negone(in)
out = in;
mask = isnan(out);
out(mask) = -1;

function out = changeNegOne2zero(in)
out = in;
mask = in < 0;
out(mask) = 0;

function out = changeNegOne2nan(in)
out = in;
mask = in < 0;
out(mask) = nan;


% -------------------------------------------------------------------------
function writeDataset(ds, filePathName, delimiterStr)
% this is for running in ML 2007a. dataset/export does not exist, so need
% to write the file

% open the file
fid = fopen(filePathName, 'wt');
if fid < 0,
	disp('Error openning the file.')
	disp('Check that it is not open in another program.')
	disp('Try again. Maybe choose a different file name.')
	[fName, pathName] = getsavenames(filePathName, 'Save as');
	if isequal(fName, 0) || isequal(pathName, 0),
		disp('You canceled. Nothing will be saved!');
		return
	else
		fid = fopen(fullfile(pathName,fName), 'wt');
		if fid < 0,
			disp('Still can not open the file. Nothing will be saved!')
			return
		end
	end

end

% the variable names in the dataset
varnames = get(ds, 'VarNames');

% the first line with strings between the delimiter
for name = 1:length(varnames)
	fprintf(fid, ['%s' delimiterStr], varnames{name});
end
fprintf(fid, '\n');	% end of line

% each row/line
for row = 1:length(ds)
	% print each variable/column element, must be single string or number
	% (no arrays, please) Also, I'm sorry I can't handle single characters.
	% a single character will be written to the file as its ascii character
	% value
	for col = 1:length(varnames)
		numOrCharVals = double(ds(row, col));
		if length(numOrCharVals) > 1		% strings
			outStr = ds(row, col);
			fprintf(fid, ['%s' delimiterStr], outStr{1,:});
		else   % not a string treat as float
			if isnan(numOrCharVals)
				% don't print NaN, leave blank
				fprintf(fid, delimiterStr);
			else
				fprintf(fid, ['%g' delimiterStr], numOrCharVals);
			end
		end
	end
	fprintf(fid, '\n');	% end of line

end

% close the file
fclose(fid);

% -----------------------------------------------------------------------------------
function outList = findregexpdir(pathName, regexpstr)
% get the list of all directories/folders matching the regexp string
% outList - cell array of strings for matching directories
% pathName - the full path where to search
% regexpstr - the regexp string to match
% check each directory and file
dirList = dir(pathName);
outList = {};
for i = 1:length(dirList)
	if dirList(i).isdir,	%% it's a directory
		if regexp(dirList(i).name, regexpstr),		%% matches the regexp
			outList = {outList{:} dirList(i).name};			%% add it to the list
		end
	end
end

% -----------------------------------------------------------------------------------
function outDs = formatDStable(dayStruc, invSide);
% format data for one day (dayStruc) 
% dayStruc - structure with fields: pre, post1, post2
%				each field is a dataset with the variables for peaks and amplitudes (using
%				C3 and C4 which need to be translated into Cc and Ci
% invSide - string: either 'left' or 'right', indicating the involved arm side
outDs = dataset();

if exist('dayStruc.pre') 
	ss = strfind(cell(dayStruc.post1.Trial),'Dual');
	msk = cellfun(@isempty,ss);
	rr = dayStruc.post1.Trial(~msk);
	if ~isempty(rr)
		keyboard
	end
end
% loop through each field (data collection session)
sessions = fieldnames(dayStruc);
for i = 1:length(sessions),	
	% separate left from right trials (this is the arm that was stimulated)
	msk=~cellfun('isempty',(regexp(dayStruc.(sessions{i}).Trial,'R$'))); %% Right trials end in the string 'R'
    dsR = dayStruc.(sessions{i})(msk,:);
    % change Trial variable to single numbers, starting with 1
    
	msk=~cellfun('isempty',(regexp(dayStruc.(sessions{i}).Trial,'L$'))); %% Left trials end in the string 'L'
    dsL = dayStruc.(sessions{i})(msk,:);
    % change Trial variable to single numbers, starting with 1
    dsR.Trial = reNumber(dsR.Trial);
    dsL.Trial = reNumber(dsL.Trial);

    % rename variables for each side using Ci & Cc instead of C3 & C4
	% for right
	vnames = get(dsR, 'VarNames');
    vnames = reNameVars(vnames, 'R');
    dsR = set(dsR, 'VarNames', vnames);
    % for left
	vnames = get(dsL, 'VarNames');
    vnames = reNameVars(vnames, 'L');
    dsL = set(dsL, 'VarNames', vnames);

    % format left and right datasets into a single row dataset with new variables for trials
    newDsR = reformatTrials(dsR);
    newDsL = reformatTrials(dsL);
	
	% insert 'inv' or 'un' to L & R datasets
	switch lower(invSide),
		case 'left',
			% right side is 'un'
			newDsR = prependDs(newDsR, 'arm_stim', {'un'});
			% left side is 'inv'
			newDsL = prependDs(newDsL, 'arm_stim', {'inv'});
		case 'right',
			% right side is 'inv_'
			newDsR = prependDs(newDsR, 'arm_stim', {'inv'});
			% left side is 'un_'
			newDsL = prependDs(newDsL, 'arm_stim', {'un'});			
	end

	% combine left and right datasets together
	% unless one is empty
	if isempty(newDsR)
		sessDS = newDsL;
	elseif isempty(newDsL);
		sessDS = newDsR;
	else
		sessDS = vertcat(newDsR, newDsL);
	end
	% prepend the session name to the ds
	sessDS = prependDs(sessDS, 'pre_post', sessions(i));
	% add this to the output dataset 
	outDs = mergedatasets(outDs, sessDS);

end %% sessions

% -----------------------------------------------------------------------------------
function outDs = prependDs(inDs, colName, val)
% add the column with the indicated value to each row of the sent dataset

[nRows, nCols] = size(inDs);
dsTmp = dataset({repmat(val,nRows,1),colName});
outDs = horzcat(dsTmp, inDs);

% -----------------------------------------------------------------------------------
function numListTxt = reNumber(casList)
% take the cell array of strings and return a single column of numbers,
% starting at 1, but also look for 'TrialAvg - R' and 'TrialDualSub'

% find the numbers or 'avg' in the strings: 'Trial3 - R'
textNumList = regexpi(casList, '(\d*)|avg|dual', 'match');
% index of avg & dual
idxAvg = find(strcmpi([textNumList{:}], 'avg'));
idxDual = find(strcmpi([textNumList{:}], 'dual'));
% convert the list of string numbers into doubles
numList = cellfun(@(x)str2double(x), textNumList);	% 'avg' and 'dual' will be converted to nan
% make sure the smallest number is 1
minNum = min(numList);
if minNum > 1,
    numList = numList - minNum + 1;
end
% change numList back to a cell array of strings
numListTxt = arrayfun(@(x)num2str(x), numList, 'uniformoutput', false);
% replace 'NaN' with 'Avg' or 'Dual'
if ~isempty(idxAvg)
	numListTxt{idxAvg} = 'Avg';
end
if ~isempty(idxDual)
	numListTxt{idxDual} = 'Dual';
end

% -----------------------------------------------------------------------------------
function newList = reNameVars(varList, LorR)
% take the cell array of strings of variable names (varList) and return a new list 
% (newList) with Cc and Ci instead of C3 and C4, depending upon the arm/side being
% stimulated (LorR)

newList = varList;
% variable names ex: N20_C3, N33_C4_P40_C4
% find the matches to the named variables with regexp: ([NP]\d{2}_C[34])
switch LorR,
    case 'L',
        % change C3 to Ci & C4 to Cc
        newList = cellfun(@(x)(strrep(x,'C3','Ci')), newList, 'UniformOutput', false);
        newList = cellfun(@(x)(strrep(x,'C4','Cc')), newList, 'UniformOutput', false);
    case 'R',
        % change C3 to Cc & C4 to Ci
        newList = cellfun(@(x)(strrep(x,'C3','Cc')), newList, 'UniformOutput', false);
        newList = cellfun(@(x)(strrep(x,'C4','Ci')), newList, 'UniformOutput', false);
end

% remove all _Cc_ and _Ci_ strings
newList = cellfun(@(x)(strrep(x,'_Cc_','')), newList, 'UniformOutput', false);
newList = cellfun(@(x)(strrep(x,'_Ci_','')), newList, 'UniformOutput', false);

% -----------------------------------------------------------------------------------
function dsOut = reformatTrials(dsIn)
% take the dataset and reformat it 
% only include average variables (average of individual traces, not trAvg)

[mRows,nVars] = size(dsIn);
dataMat = double(dsIn(:,2:end));	%% all the data except column 1 (string with trial # or 'Avg') as a matrix 
varNames = get(dsIn, 'VarNames');	%% original variable names

% if dataMat is empty, just return dsIn
if isempty(dataMat)
	dsOut = dsIn;
	return
end
% new data and variable names
dataRow = zeros(1, (mRows+1)*(nVars-1));
newVarNames = cell(1, (mRows+1)*(nVars-1));

% mask for rows with numbered trial data, not the averaged trial's data
numberedTrialsMsk = ~isnan(str2double(dsIn.Trial));

dsCi = dataset({'i', 'CcCi'});
dsCc = dataset({'c', 'CcCi'});

cnt = 1;
% define the new info
for col = 2:nVars,		
	
	% Cc or Ci variable?
	cOri = regexpi(varNames{col}, '(cc)|(ci)', 'match');
	var = strrep(varNames{col}, cOri{1}, '');
	
	% average of the numbered trials 
	newVarNames{cnt} = [var];
	% mean ** excluding -1 values (& -0.001 for ccf sec converted to ms), 
	% the flag for good data but no peak assessed **
	dataTmpNegOnes = dataMat(numberedTrialsMsk, col-1);
	dataTmpNans = dataMat(numberedTrialsMsk, col-1);
	dataTmpNans(dataTmpNans<0) = nan;
	val = nanmean(dataTmpNans);
	
	% if all the values averaged were originally <0, then this is good data and the
	% average value is replaced with -1 instead of NaN
	if sum(dataTmpNegOnes<0) == length(dataTmpNegOnes),
		val = -1;
	end
	
	cnt = cnt + 1;
	
	switch lower(cOri{1})
		case 'cc'
			dsCc = horzcat(dsCc, dataset({val,var}));
		case 'ci'
			dsCi = horzcat(dsCi, dataset({val,var}));
	end

end

dsOut = mergedatasets(dsCc, dsCi);


% -----------------------------------------------------------------------------------
function dsOut = prependVarNames(dsIn, str)
% take the dataset and prepended to each variable the string str
% return the new dataset

vnames = get(dsIn, 'VarNames');
vnames = cellfun(@(x)([str x]), vnames, 'UniformOutput', false);
dsOut = set(dsIn, 'VarNames', vnames);


% -----------------------------------------------------------------------------------
function dsOut = mergedatasets(dsIn1, dsIn2)
% vertcat the 2 input datasets even if they do not have the same number of variables
dsOut = dataset();

% if one is empty, just return the other 
if isempty(dsIn1), dsOut = dsIn2; return; end
if isempty(dsIn2), dsOut = dsIn1; return; end

dsOut = join(dsIn1, dsIn2, 'type', 'outer', 'mergekeys', true);
%
% go through each variable in dsIn2 and confirm or add it to dsIn1
%dsIn1 = addextravars(dsIn1, dsIn2);

% same thing for dsIn2
%dsIn2 = addextravars(dsIn2, dsIn1);


% since they should have the same variables, vertcat the datasets
%dsOut = vertcat(dsIn1, dsIn2);

% -----------------------------------------------------------------------------------
function dsA = addextravars(dsA, dsB)
% go through each variable in dsB and confirm or add it to dsA

% get the variables for each input dataset
vnamesA = get(dsA, 'VarNames');
vnamesB = get(dsB, 'VarNames');
for i = 1:length(vnamesB),
	% find the vnamesB string in vnamesA
	found = sum(cellfun(@(x)(strcmp(x,vnamesB{i})), vnamesA));
	
	if ~found,
		% add the variable to dsA with NaN values
		dsA = horzcat(dsA, dataset({nan(size(dsA,1),1),vnamesB{i}}));
	end
end
