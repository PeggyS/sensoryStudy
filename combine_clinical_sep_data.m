function combine_clinical_sep_data(varargin)
%combine clincal data from Sensory_rTMS_Clincial_tall.xlsx (with the date formatted dd-Mon-yyyy
% and sep_data_format_measure_cols.xlsx

% input parameter-value pairs:
%	clinical_file - clinical filename
%	sep_file - sep data file name
%	exclude - cell array fo string of subjects to exclude

% define input parser
p = inputParser;
p.addParameter('clinical_file', '', @isstr);
p.addParameter('sep_file', '', @isstr);
p.addParameter('exclude', {}, @iscell);


% parse the input
p.parse(varargin{:});
inputs = p.Results;
inputs.clinical_file = request_file(inputs.clinical_file, '*.xlsx', 'Pick clinical data tall .xlsx file');
if isempty(inputs.clinical_file), return, end
clinical_tbl = readtable(inputs.clinical_file);
% only include sessTypes: Ha, Hs, L, Ha-g, Hs-g, L-g
clinical_tbl.SessType = nominal(clinical_tbl.SessType);
clinical_tbl = clinical_tbl(clinical_tbl.SessType=='Hs' | clinical_tbl.SessType=='Ha' | clinical_tbl.SessType=='L' ...
	| clinical_tbl.SessType=='Hs-g' | clinical_tbl.SessType=='Ha-g' | clinical_tbl.SessType=='L-g',: );


clinical_var_list = {'x2pt_dig2','x2pt_dig4','vibr_dig2_avg','vibr_elbw_avg', ...
	'proprioception_index_pct', 'proprioception_wrist_pct','monofil_dig2_local','monofil_dig4_local',...
	'dome_dig2_thresh', 'dome_dig4_thresh', 'stkch', 'smobj' };

inputs.sep_file = request_file(inputs.sep_file, '*.xlsx', 'Pick sep data format measure cols .xlsx file');
if isempty(inputs.sep_file), return, end
sep_tbl = readtable(inputs.sep_file, 'DatetimeType', 'exceldatenum');
sep_tbl.SessType = nominal(sep_tbl.SessType);
sep_tbl = sep_tbl(sep_tbl.SessType=='Hs' | sep_tbl.SessType=='Ha' | sep_tbl.SessType=='L' ...
	| sep_tbl.SessType=='Hs-g' | sep_tbl.SessType=='Ha-g' | sep_tbl.SessType=='L-g',: );
sep_tbl.Date = datetime(sep_tbl.datestr);
sep_var_list = {'N20Cc', 'P25Cc', 'N33Cc', 'P45Cc', 'N60Cc' ,'P100Cc', 'N120Cc', ...
	'N20Cc_P25Cc', 'P25Cc_N33Cc', 'N33Cc_P45Cc', 'P45Cc_N60Cc', 'N60Cc_P100Cc', 'P100Cc_N120Cc'};


s24_c_tbl = clinical_tbl(strcmp(clinical_tbl.Subj, 's2624sens'),:);
s24_s_tbl = sep_tbl(strcmp(sep_tbl.Subj, 's2624sens'),:);
jt = outerjoin(s24_s_tbl, s24_c_tbl, ...
	'LeftKeys', {'Subj', 'Date', 'arm', 'pre_post', 'SessType'}, ...
	'RightKeys', {'Subj', 'Date', 'arm_stim', 'pre_post', 'SessType'}, 'MergeKeys', true);

% join the tables
comb_tbl = outerjoin(sep_tbl, clinical_tbl, ...
	'LeftKeys', {'Subj', 'Date', 'arm', 'pre_post', 'SessType'}, ...
	'RightKeys', {'Subj', 'Date', 'arm_stim', 'pre_post', 'SessType'}, ...
	'LeftVariables', [{'Subj', 'Date', 'session_num', 'SessType', 'arm', 'pre_post'}, sep_var_list], ...
	'RightVariables', clinical_var_list, 'MergeKeys', true);
% rename variable arm_arm_stim to arm
comb_tbl.Properties.VariableNames = strrep(comb_tbl.Properties.VariableNames, 'arm_arm_stim', 'arm');

comb_tbl.SessType = string(comb_tbl.SessType); 
comb_tbl.SessType = strrep(comb_tbl.SessType, 'Ha', 'H');
comb_tbl.SessType = strrep(comb_tbl.SessType, 'Hs', 'S');

% exclude subjects 
if ~isempty(inputs.exclude)
	for s_cnt = 1:length(inputs.exclude)
		tbl = tbl(~strcmp(tbl.Subj, inputs.exclude{s_cnt}), :);
	end
end

% request where to save 
[fName, pathName] = uiputfile('combined_data_measure_cols.xlsx', 'Save as');
if isequal(fName, 0) || isequal(pathName, 0)
	disp('Not saving. User canceled.');
	return;
end
writetable(comb_tbl, fullfile(pathName, fName));
