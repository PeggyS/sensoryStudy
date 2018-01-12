function out_tbl = clinical_pre(varargin)
%CLINICAL_PRE -  the PRE data in the clinical_data_tall file
%
% input parameter-value pairs:
%	file - filename

% define input parser
p = inputParser;
p.addParameter('file', 'none', @isstr);
p.addParameter('exclude', {}, @iscell);

% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none'),		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.txt', 'Pick clinical measures TALL file');
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

% exclude subjects 
if ~isempty(inputs.exclude)
	for s_cnt = 1:length(inputs.exclude)
		tbl = tbl(~strcmp(tbl.Subj, inputs.exclude{s_cnt}), :);
	end
end

out_tbl = table();

% each measure
measure_list =  {'dome_dig2_thresh' ...
    'dome_dig4_thresh' ...
    'grpsgth_avg' ...
    'hcans' ...
    'lcans' ...
    'monofil_dig2_local' ...
    'monofil_dig4_local' ...
    'prop_table_dig2_error' ...
    'prop_table_dig2_motionerror' ...
    'proprioception_index_pct' ...
    'proprioception_wrist_pct' ...
    'smobj' ...
    'stkch' ...
    'temp' ...
    'vibr_dig2_avg' ...
    'vibr_elbw_avg' ...
    'x2pt_dig2' ...
	'x2pt_dig4' }; 
		  

for m_cnt = 1:length(measure_list)
	measure = measure_list{m_cnt};

	tbl_meas = tbl(strcmp(tbl.pre_post, 'pre') & ~strcmp(tbl.SessType,'BL'), ...
		{'Subj', 'Date', 'SessType', 'pre_post', 'arm_stim', measure});

	% convert date string to number
	tbl_meas.date_num = datenum(tbl_meas.Date);

	% for each subject, number each session by the date sequence - create new
	% column session_num with values 1, 2, & 3 and another variable for the
	% preceeding_sesstype (prev_sess_type)
	tbl_meas = add_session_num(tbl_meas);


	% for each subj & both arms, compute session 2 minus session 1 value, compute
	% session 3 minus session 2 value, 
	tbl_meas = add_session_diff(tbl_meas, measure);

	
	tbl_meas.Properties.VariableNames = strrep(tbl_meas.Properties.VariableNames, measure, 'value');
	tbl_meas.measure = repmat({measure}, height(tbl_meas), 1);
	
	% put new info in out table
	if isempty(out_tbl)
		out_tbl = tbl_meas;
	else
		out_tbl = vertcat(out_tbl, tbl_meas);
	end
end


% reorder columns 
out_tbl = out_tbl(:,[1,2,7,8,3,9,4,5,11,6,10]);

% request where to save 
[fName, pathName] = getsavenames(fullfile(pwd, 'session_order_and_previous.xlsx'), 'Save as');
if isequal(fName, 0) || isequal(pathName, 0),
	disp('Not saving. User canceled.');
	return;
end

writetable(out_tbl, fullfile(pathName,fName))
return


function out_tbl = add_session_diff(in_tbl, measure)
out_tbl = table();

subj_list = unique(in_tbl.Subj);
for subj_cnt = 1:length(subj_list)
	% subj data
	subj_tbl = in_tbl(strcmp(in_tbl.Subj, subj_list{subj_cnt}),:);
	subj_tbl.session_diff = nan(height(subj_tbl),1); % add session diff 
	
	prev_data.inv = [];
	prev_data.un = [];
	sess_num_list = unique(subj_tbl.session_num);
	for sess_cnt = 1:length(sess_num_list)
		sess_num = sess_num_list(sess_cnt);
		for arm = {'inv', 'un'}
			
			ind = find(subj_tbl.session_num==sess_num & strcmp(subj_tbl.arm_stim, arm));
			assert(length(ind)==1, 'session_num = %d, arm = %s', sess_num, arm{:})
			
			diff_data = subj_tbl.(measure)(ind) - prev_data.(arm{:});
			if ~isempty(diff_data)
				subj_tbl.session_diff(ind) = diff_data;
			end
			
			prev_data.(arm{:}) = subj_tbl.(measure)(ind);
		end
		
		
	end
	
	% put new info in out table
	if isempty(out_tbl)
		out_tbl = subj_tbl;
	else
		out_tbl = vertcat(out_tbl, subj_tbl);
	end
end
return

function out_tbl = add_session_num(in_tbl)
% using the date for each session, number them consecutively for each subject
out_tbl = table();

subj_list = unique(in_tbl.Subj);
for subj_cnt = 1:length(subj_list)
	% subj data
	subj_tbl = in_tbl(strcmp(in_tbl.Subj, subj_list{subj_cnt}),:);
	
	% new columns
	subj_tbl.session_num = nan(height(subj_tbl),1); % add session number 
	subj_tbl.prev_sess_type = repmat({''},height(subj_tbl),1); % and previous session type

		
	date_list = unique(subj_tbl.date_num); % returns list of unique date nums sorted lowest to highest
	prev_sess = 'X';

	for sess_cnt = 1:length(date_list)

		date_inds = find(subj_tbl.date_num==date_list(sess_cnt));
		subj_tbl(date_inds, 'session_num') = table(sess_cnt);
		subj_tbl(date_inds, 'prev_sess_type') = cell2table({prev_sess});
		
		% update previous values
		prev_sess = subj_tbl.SessType(date_inds(1));
	
	end
	
	% put new info in out table
	if isempty(out_tbl)
		out_tbl = subj_tbl;
	else
		out_tbl = vertcat(out_tbl, subj_tbl);
	end
end

return

