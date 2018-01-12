function finalDS = formatSep(startDir)
% formatSep - read in sep data (excel files in directory structure) and reformat into a single (wide) spreadsheet
% startDir - the starting directory string
%			directory structure: base/subjNum/date/sepExcelFiles.xlsx
%				subjNum = [s|c]26##sens, ex: s2601sens, c2602sens (for the VA only)
%						for the CCF subjects are M01, M12, etc.
%				date = date of data collection (yyyymmdd)
%				sepExcelFiles.xlsx = pre.xlsx, post1.xlsx, post2.xlsx 
%
%			base/subjNum/involvedside.txt - should contain the word right or left
%
% The formatted data is saved in the baseDir in a file named sepdata.txt or other name
% chosen by the user. 
%
% Note: the latency times for the VA are in milliSeconds. CCF data is in seconds. This
% function will convert CCF latencies to msec.

% Author: Peggy Skelly
% Date: 14 Dec 2012
% Time to create: 12/14/2012: 4 hrs
%					12/16/2012: 1 hr
%					12/17/2012: 10:30 - 7:00: 8 hrs
%					12/19/2012: 2 hrs
% 
%   2013-06-27: edit/fix/make work in ML2007 
%	2013-09-17: warnings about variable renaming is not turning off in ML2013
%		when a dataset is read in, change all nans to zeros (to indicate data was
%		recorded, but no peak was found at that time. In the combined all subject's 
%		dataset missing values will be nans. *** not exactly right *** fixed later
%	2013-09-20 (3 hrs) : edit to validate variable names, include CCF's subject names,
%	 convert latencies CCF to ms and replace nans with zeros in the intial table read in
%	2013-10-04: (2 hrs) fix how missing/bad data and ok data but no peaks identified are
%		flagged. Missing/bad data is marked with 999 in the spreadsheet read in. Blank
%		cells are read in as NaNs but indicate ok data, but no peaks. Immediately upon reading in, 
%		the NaNs are changed to -1 so later they can be excluded from the average calculation. 
%		The 999s are changed to NaNs. The average calculation first changes the <0 values
%		to NaN in a temp variable, thereby excluding them. Once in the final wide row
%		dataset format, <0 values are changed to zero, indicating ok data but no peaks
%		detected.

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

% turn off a warning about renaming the variables when read into the dataset
if verLessThan('matlab', '7.10')
	sw=warning('off', 'stats:dataset:setvarnames:ModifiedVarnames');		% ML2007a
elseif verLessThan('matlab', '8.1')
	sw=warning('off','stats:dataset:genvalidnames:ModifiedVarnames');		% ML2010a - 7.10
else
	sw=warning('off', 'MATLAB:codetools:ModifiedVarnames');					% ML2013a
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
	% look for the date in the startDir
	dateList = regexpi(startDir, '\d{8}$', 'match');
	if isempty(dateList)	% look within the directory structure
		% find subfolders with recording dates
		dateList = findregexpdir(fullfile(baseDir,subjList{i}), '^\d{8}$'); %% folder must be 8 digits only - the date in the format yyyymmdd
	end
	oneDayOneRow = dataset();

	% for each date
	for j = 1:length(dateList),
		oneDaysData = [];
		% update the waitbar
		waitbar(j/length(dateList), hwb, {'Combining SEP data into a single table.';
		['Processing subject ' subjList{i} ' ' num2str(i) '/' num2str(length(subjList))]} );
		
		% for each session
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
				ds = replacedata(ds, @(x) changeNan2negone(x), numVarList);
			
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

				% add it to thee day's struct
				oneDaysData.(session{k}) = ds;
			else
				ds = [];
			end
		end	%% session

		% format data for one day into a single row	and add to the complete dataset
		if ~isempty(oneDaysData),
			% put all data in 1 row and add computed average variables making sure to not
			% average the -1 (and -0.001) values
			oneDayOneRow = formatDStableToRow(oneDaysData, side);
			
			% now replace all -1 (and -0.001) with zeros - ok data but
			% add the subject and session date to the row
			oneRowVnames = get(oneDayOneRow, 'VarNames');
			trVar = regexpi(oneRowVnames, 'trial');
			numVarMsk = cellfun(@isempty, trVar);
			numVarList = oneRowVnames(numVarMsk);
			oneDayOneRow = replacedata(oneDayOneRow, @(x) changeNegOne2zero(x), numVarList);
						
			tmp = dataset({subjList{i}, 'Subj'}, {datestr(datenum(dateList{j}, 'yyyymmdd')), 'Date'});
			oneDayOneRow = horzcat(tmp, oneDayOneRow);
			
			% add that row to the final dataset
			finalDS = mergedatasets(finalDS, oneDayOneRow);	
		end
		
	end	%% dateList

end %% subjList

% find variables for the dual stim trial latencies and subtract 20 ms 
finalvarnames = get(finalDS, 'VarNames');
dualVars = regexpi(finalvarnames, '[preost12]+_[uninv]+_[npci\d]+_trdual','match');
nonDualVarMsk = cellfun(@isempty, dualVars);
dualVarList = finalvarnames(~nonDualVarMsk);
if ~isempty(dualVarList)
	finalDS = replacedata(finalDS, @(x) subtract20(x), dualVarList);
end

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

function out = subtract20(in)
out = in;
mask = in > 0;
out(mask) = in(mask)-20;

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
function outRow = formatDStableToRow(dayStruc, invSide);
% format data for one day (dayStruc) into a single row
% dayStruc - structure with fields: pre, post1, post2
%				each field is a dataset with the variable names:
% invSide - string: either 'left' or 'right', indicating the involved arm side
outRow = dataset();

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
	
	% prepend 'inv' & 'un' to L & R datasets
	switch lower(invSide),
		case 'left',
			% right side is 'un_'
			newDsR = prependVarNames(newDsR, 'un_');
			% left side is 'inv_'
			newDsL = prependVarNames(newDsL, 'inv_');
		case 'right',
			% right side is 'inv_'
			newDsR = prependVarNames(newDsR, 'inv_');
			% left side is 'un_'
			newDsL = prependVarNames(newDsL, 'un_');			
	end

	% combine left and right one-row-datasets together
	% unless one is empty
	if isempty(newDsR)
		sessDS = newDsL;
	elseif isempty(newDsL);
		sessDS = newDsR;
	else
		sessDS = horzcat(newDsR, newDsL);
	end
	% prepend the session name to the ds
	sessDS = prependVarNames(sessDS, [sessions{i} '_']);
	% add this to the output dataset 
	if isempty(outRow)
		outRow = sessDS;
	else
		outRow = horzcat(outRow, sessDS);
	end
end %% sessions

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

if any(numList>3)
%	keyboard
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
% take the dataset and reformat it into 1 big row. Each variable gets _tr# at its end
% also include average variables

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

cnt = 1;
% define the new info
for col = 2:nVars,		
	
	for row = 1:mRows,
		newVarNames{cnt} = [varNames{col} '_tr' char(dsIn.Trial(row))];
		data = dataMat(row, col-1);	% columns in dataMat begin with 2nd column of dsIn
		dataRow(cnt) = data;
		cnt = cnt + 1;
	end
	% average of the numbered trials variable 
	newVarNames{cnt} = [varNames{col} '_avg'];
	% mean ** excluding -1 values (& -0.001 for ccf sec converted to ms), 
	% the flag for good data but no peak assessed **
	dataTmpNegOnes = dataMat(numberedTrialsMsk, col-1);
	dataTmpNans = dataMat(numberedTrialsMsk, col-1);
	dataTmpNans(dataTmpNans<0) = nan;
	dataRow(cnt) = nanmean(dataTmpNans);
	
	% if all the values averaged were originally <0, then this is good data and the
	% average value is replaced with -1 instead of NaN
	if sum(dataTmpNegOnes<0) == length(dataTmpNegOnes),
		dataRow(cnt) = -1;
	end
	
	cnt = cnt + 1;	
	
end

dsOut = dataset({dataRow,newVarNames{:}});

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
