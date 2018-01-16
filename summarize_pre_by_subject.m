function summarize_pre_by_subject(varargin)

% define input parser
p = inputParser;
p.addParameter('file', 'none', @isstr);
p.addParameter('arm', {'un', 'inv'}, @iscell);



% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none')		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.xlsx', 'Pick session_order_and_previous.xlsx file');
	if isequal(fname,0) || isequal(pathname,0)
		disp('User canceled. Exitting')
		return
	else
		filePathName = fullfile(pathname,fname);
	end
else
	filePathName = inputs.file;
end

tbl = readtable(filePathName);
tbl.Subj = nominal(tbl.Subj);
tbl.SessType = nominal(tbl.SessType);
tbl.prev_sess_type = nominal(tbl.prev_sess_type);
tbl.arm_stim = nominal(tbl.arm_stim);
tbl.measure = nominal(tbl.measure);

% remove X sessions
tbl_all_sessions = tbl(tbl.SessType~='X',:);
% verify
session_names = unique(tbl.SessType);
disp(session_names)

% group stats
[mean_list, std_list, cnt_list, grp_cell] = grpstats(tbl_all_sessions.value, ...
	{tbl_all_sessions.Subj, tbl_all_sessions.arm_stim, tbl_all_sessions.measure}, ...
	{'mean', 'std', 'numel', 'gname'});

% columns of grp_cell = subj, arm_stim, measure
out_tbl = table();	% 1 row for each subject: mean, std, cnt for each measure as variables
out_tbl.subj = unique(grp_cell(:,1));

for row = 1:length(mean_list)  % go through each row of the grpstats output matrices
	% find the row for this subj
	subj_ind = find(strcmp(out_tbl.subj, grp_cell{row,1}));
	
	if subj_ind>1
% 		keyboard
	end
	vname = [grp_cell{row,3} '_' grp_cell{row,2} '_mean'];
	if ~sum(strcmp(out_tbl.Properties.VariableNames, vname)) % new variable name, add it as nans for all subj
		out_tbl.(vname) = nan(height(out_tbl),1);
	end
	out_tbl.(vname)(subj_ind) = mean_list(row);
	
	vname = [grp_cell{row,3} '_' grp_cell{row,2} '_std'];
	if ~sum(strcmp(out_tbl.Properties.VariableNames, vname)) % new variable name, add it as nans for all subj
		out_tbl.(vname) = nan(height(out_tbl),1);
	end
	out_tbl.(vname)(subj_ind) = std_list(row);
	
	vname = [grp_cell{row,3} '_' grp_cell{row,2} '_n'];
	if ~sum(strcmp(out_tbl.Properties.VariableNames, vname)) % new variable name, add it as nans for all subj
		out_tbl.(vname) = nan(height(out_tbl),1);
	end
	out_tbl.(vname)(subj_ind) = cnt_list(row);
end
keyboard
writetable(out_tbl,'pre_summary_by_subj_all_sessions.csv')

