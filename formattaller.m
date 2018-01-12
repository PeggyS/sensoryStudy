function dsOut = formattaller(varargin)
% FORMATTALLER - format the 'tall' format to an even taller format. 
% 'tall' format has columns for subject, sessionType, pre_post, arm_stim/tested, and
% each measure.
% 'taller' format has columns for subject, measure, and ~44 separate columns
% for each combination of sessionType_pre_post_arm
%
% inputs in the form of parameter-value pairs:
%	'file'-'c:\path\to\filename.txt' - optional - string with the full file and pathname to the 
%		clinical measures or sep data tab delimited text file. If it
%		is not specified, then the user will be asked to identify the file
%		in a dialog box.
% 
%	Note: 1st line in the text file contains the variable names. The names must be correct.
%
% If there is more than 1 session of a given type, then the values of the
% sessions are averaged together.

% Author: Peggy Skelly
% 2014-06-16 

% define input parser
p = inputParser;
p.addParamValue('file', 'none', @isstr);

% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none'),		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.txt', 'Pick tall format tab delimited file');
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

ds = dataset('file', filePathName);

% get list of subjects, session types, pre_post & inv_uninv
subjList = unique(ds.Subj);
sessList = unique(ds.SessType);
ppList = unique(ds.pre_post);
invunList = unique(ds.arm_stim);

% create new variable names from session_pre_post_inv_uninv
cnt = 1;
dsEmpty = dataset({{'subj'},'Subj'},{{'meas'},'Measure'});
for ss = 1:length(sessList),
	for pp = 1:length(ppList),
		for ii = 1:length(invunList),
            vName = [strrep(sessList{ss},'-','_') '_' ppList{pp} '_' invunList{ii}];
			newVarNames{cnt} = vName;
			cnt = cnt + 1;
            % empty dataset with new variable names
            dsEmpty = horzcat(dsEmpty, dataset({nan, vName}));
		end
	end
end
dsOut = dsEmpty;

oldVnames = get(ds,'VarNames');

% remove Site Subj	inv_arm	Date	SessType	pre_post	arm_stim
if sum(strcmp(oldVnames,'CcCi')) > 0
    ciFlg = true;
    vfs = regexpi(oldVnames, '(site)|(Subj)|(inv_arm)|(Date)|(SessType)|(pre_post)|(arm_stim)|(CcCi)');
else
    ciFlg = false;
    vfs = regexpi(oldVnames, '(site)|(Subj)|(inv_arm)|(Date)|(SessType)|(pre_post)|(arm_stim)');
end
indemp=cellfun(@isempty,vfs);
oldVnames = oldVnames(indemp);

% loop through each unique row of old dataset
if ciFlg
    [dsUniq, indsDs, indsUniqDs] = unique(ds,{'Subj','SessType','pre_post','arm_stim','CcCi'});
else
    [dsUniq, indsDs, indsUniqDs] = unique(ds,{'Subj','SessType','pre_post','arm_stim'});
end
[rows,cols]=size(dsUniq);

disp(['rows in dsUniq = ' num2str(rows)])
for rr = 1:rows,
   waitbar(rr/rows, hwb, {'Reformatting data.';
		['Processing ... ' ]} );
	
    for vv = 1:length(oldVnames),
        
        subj = ds.Subj(indsDs(rr));
        sess_type = ds.SessType(indsDs(rr));
        pre_post = ds.pre_post(indsDs(rr));
        arm_stim = ds.arm_stim(indsDs(rr));
        if ciFlg
            cc_ci = ds.CcCi(indsDs(rr));
            varName = {[oldVnames{vv} '_' cc_ci]};
            val = ds(strcmp(ds.Subj,subj) & ...
                 strcmp(ds.SessType,sess_type) & ...
                 strcmp(ds.pre_post,pre_post) & ...
                 strcmp(ds.arm_stim,arm_stim) & ...
                 strcmp(ds.CcCi,cc_ci), oldVnames(vv));
        else
            varName = oldVnames(vv);
            val = ds(strcmp(ds.Subj,subj) & ...
                 strcmp(ds.SessType,sess_type) & ...
                 strcmp(ds.pre_post,pre_post) & ...
                 strcmp(ds.arm_stim,arm_stim)  , varName);
        end
        newVal = dataset({nanmean(double(val)),varName{:}});
             if length(val)>1
%                  keyboard
             end
        newVname = [strrep(char(sess_type),'-','_') '_' char(pre_post) '_' char(arm_stim)];
        
        %dsTmp = dataset( {subj,'Subj'}, {varName,'Measure'}, ...
         %   {double(val), newVname} );
        % subj-measure in dsOut?
        if sum(strcmp(dsOut.Subj,subj) & strcmp(dsOut.Measure,varName)) == 1,
            dsOut(strcmp(dsOut.Subj,subj) & strcmp(dsOut.Measure,varName), newVname) = newVal;
        elseif sum(strcmp(dsOut.Subj,subj) & strcmp(dsOut.Measure,varName)) == 0,
            dsTmp = dsEmpty;
            dsTmp.Subj=subj;
            dsTmp.Measure=varName;
            dsTmp.(newVname)=double(val);
            dsOut = vertcat(dsOut, dsTmp);
        else
            error(['found > 1 matching subj measure pair: ' subj ' - ' varName])
        end
    end
end
% close waitbar
close(hwb)

% request where to save 
[fName, pathName] = getsavenames(fullfile(pwd, 'data_taller.txt'), 'Save as');
if isequal(fName, 0) || isequal(pathName, 0),
	disp('Not saving. User canceled.');
	return;
end

% save
export(dsOut, 'File', fullfile(pathName, fName), 'delimiter', '\t')


