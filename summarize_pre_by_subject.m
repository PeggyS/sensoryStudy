function summarize_pre_by_subject(varargin)

% define input parser
p = inputParser;
p.addParameter('file', 'none', @isstr);
p.addParameter('exclude', {}, @iscell);
p.addParameter('measure',{'x2pt_dig2', 'x2pt_dig4', ...
	'monofil_dig2_local' 'monofil_dig4_local', ...
	'proprioception_index_pct', ...
	'vibr_dig2_avg' }, @iscell);
p.addParameter('arm', {'un', 'inv'}, @iscell);



% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none'),		% no file specified
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
out_tbl = table();

for row = 1:length(mean_list)
	out_tbl.subj = grp_cell{row, 1};
	vname = [grp_cell{row,3} '_' grp_cell{row,2}];
	out_tbl.(vname) = {};
end
