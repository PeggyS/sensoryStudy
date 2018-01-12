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

out_tbl = table();
