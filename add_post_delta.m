function add_post_delta(varargin)
%add the post minus pre values for data formatted with measures as columns 
% like in clinical_data_tall.xlsx,  and sep_data_format_measure_cols.xlsx, &
% combined_data_measure_cols.xlsx

% input parameter-value pairs:
%	file - clinical filename


% define input parser
p = inputParser;
p.addParameter('file', '', @isstr);


% parse the input
p.parse(varargin{:});
inputs = p.Results;
inputs.file = request_file(inputs.file, '*.xlsx', 'Pick data file with measures in columns');
if isempty(inputs.file), return, end
tbl = readtable(inputs.file);

% clinical data may have 'arm_stim' other files have 'arm'
tbl.Properties.VariableNames = strrep(tbl.Properties.VariableNames, 'arm_stim', 'arm'); 
% if session_num is a variable, make it nominal
sn_ind = strfind(tbl.Properties.VariableNames, 'session_num');
if any(~cellfun(@isempty,sn_ind))
	tbl.session_num = nominal(tbl.session_num);
end

tbl.Subj = nominal(tbl.Subj);
tbl.SessType = nominal(tbl.SessType);
tbl.arm = nominal(tbl.arm);
tbl.pre_post = nominal(tbl.pre_post);

subj_list = unique(tbl.Subj);
sess_list = unique(tbl.SessType);
arm_list = unique(tbl.arm);

numvar_list = find_numerical_vars(tbl);
nonnum_var_list = find_nonnumerical_vars(tbl);

add_tbl = table();

for s_cnt = 1:length(subj_list)
	subj = subj_list(s_cnt);
	
	for sess_cnt = 1:length(sess_list)
		sess = sess_list(sess_cnt);
		
		for a_cnt = 1:length(arm_list)
			arm = arm_list(a_cnt);
			
			% data for this subj, session, arm
			data_tbl = tbl(tbl.Subj==subj & tbl.SessType==sess & tbl.arm==arm, :);
			
			if height(data_tbl) > 1
				assert(height(data_tbl)<=3, 'found too many entries for %s, %s, %s', subj, sess, arm)
				
				if any(data_tbl.pre_post=='pre')
					if any(data_tbl.pre_post=='post1')
						add_tbl = add_data_to_table(add_tbl, data_tbl, 'post1', numvar_list, nonnum_var_list);
					end % post 1
					if any(data_tbl.pre_post=='post2')
						add_tbl = add_data_to_table(add_tbl, data_tbl, 'post2', numvar_list, nonnum_var_list);
					end % post 2
				end % pre
			end
		end % arm_list
	end % sess_list
	
end % subj_list

comb_tbl = vertcat(tbl, add_tbl);

% request where to save 
[fName, pathName] = uiputfile(strrep(inputs.file, '.xlsx', '_d_post.xlsx'), 'Save as');
if isequal(fName, 0) || isequal(pathName, 0)
	disp('Not saving. User canceled.');
	return;
end

% if session_num is a variable, turn it back into a number
sn_ind = strfind(comb_tbl.Properties.VariableNames, 'session_num');
if any(~cellfun(@isempty,sn_ind))
	comb_tbl.session_num = double(comb_tbl.session_num);
end
writetable(comb_tbl, fullfile(pathName, fName));

return

function out_tbl = add_data_to_table(in_tbl, data_tbl, post_str, numvar_list, nonnum_var_list)
out_tbl = in_tbl;
pre_data = data_tbl(data_tbl.pre_post=='pre', numvar_list);
post1_data = data_tbl(data_tbl.pre_post==post_str, numvar_list);
diff_array = table2array(post1_data) - table2array(pre_data);
diff_tbl_row = data_tbl(1,nonnum_var_list);
diff_tbl_row = horzcat(diff_tbl_row, array2table(diff_array, 'VariableNames', numvar_list));
diff_tbl_row.pre_post = nominal(['d_' post_str]);
if isempty(out_tbl)
	out_tbl = diff_tbl_row;
else
	out_tbl = vertcat(out_tbl, diff_tbl_row);
end

return


function var_list = find_numerical_vars(tbl)
var_list = {};
for v_cnt = 1:length(tbl.Properties.VariableNames)
	if isnumeric(tbl.(tbl.Properties.VariableNames{v_cnt}))
		var_list = [var_list {tbl.Properties.VariableNames{v_cnt}}]; %#ok<AGROW>
	end
end
return

function var_list = find_nonnumerical_vars(tbl)
var_list = {};
for v_cnt = 1:length(tbl.Properties.VariableNames)
	if ~isnumeric(tbl.(tbl.Properties.VariableNames{v_cnt}))
		var_list = [var_list {tbl.Properties.VariableNames{v_cnt}}]; %#ok<AGROW>
	end
end
return