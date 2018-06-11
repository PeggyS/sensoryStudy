function out_tbl = table_format_pre_mean(varargin)
%TABLE_FORMAT - format data into a table with cols for pre sesssions 1, 2, & 3
%
% Use data from Combined_data_Sens_rTMS_20180316.csv. Create a table with
% columns: measure, pre, session 1, 2, 3, avg, friedman p
%
%		reporting either mean & sd,  and uninvolved or uninvolved side
%
% input parameter-value pairs:
%	file - filename
%	exclude = cell array of strings of subjects to exclude (e.g. {'s2608sens', s2616sens'}

% define input parser
p = inputParser;
p.addParameter('file', 'none', @isstr);
p.addParameter('exclude', {}, @iscell);
p.addParameter('measures',{'N20Cc', 'P25Cc', 'N33Cc', 'P45Cc', 'N60Cc' ,'P100Cc', 'N120Cc', ...};
	'N20Cc_P25Cc', 'P25Cc_N33Cc', 'N33Cc_P45Cc', 'P45Cc_N60Cc', 'N60Cc_P100Cc', 'P100Cc_N120Cc', ...
	'x2pt_dig4', 'monofil_dig4_local', 'proprioception_index_pct', 'vibr_dig2_avg',...
	'N20Ci', 'P25Ci', 'N33Ci', 'P45Ci', 'N60Ci' ,'P100Ci', 'N120Ci', ...
	'N20Ci_P25Ci', 'P25Ci_N33Ci', 'N33Ci_P45Ci', 'P45Ci_N60Ci', 'N60Ci_P100Ci', 'P100Ci_N120Ci' }, @iscell);
p.addParameter('arm', 'inv', @isstr);


% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none')		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.csv', 'Pick .csv file with SEP & clinical measures as columns');
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
tbl.arm = nominal(tbl.arm);
tbl.SessType = nominal(tbl.SessType);
tbl.pre_post = nominal(tbl.pre_post);

% only use sessions H, L & S (not H-g, etc)
tbl = tbl((tbl.SessType=='H' | tbl.SessType=='L' | tbl.SessType=='S'), ...
	[{'Subj', 'session_num', 'SessType', 'arm', 'pre_post'}, inputs.measures]);

% if session_num > 3, then change them to 1-3
inds_gt3 = find(tbl.session_num>3);
tbl.session_num(inds_gt3) = tbl.session_num(inds_gt3) - 3;

if ~isempty(inputs.exclude)
	for s_cnt = 1:length(inputs.exclude)
		tbl = tbl(~strcmp(tbl.Subj, inputs.exclude{s_cnt}), :);
	end
end

sess_list = [1 2 3];

arm = inputs.arm;


out_tbl = cell2table(inputs.measures', 'VariableNames', {'Measure'});
	
pre_tbl = tbl(tbl.arm==arm & tbl.pre_post=='pre' , : );
pre_data = table2array(pre_tbl(:,6:end));
pre_mean = median(pre_data, 'omitnan');
pre_sd   = iqr(pre_data);
pre_cnt  = sum(~isnan(pre_data));

pre_mean_sd = format_with_parens(pre_mean, pre_sd);

out_tbl.all_sessions = pre_mean_sd';
out_tbl.all_sessions_n = pre_cnt';

for m_cnt = 1:length(inputs.measures)
	meas = inputs.measures{m_cnt};
	data_mat = [table2array(pre_tbl(pre_tbl.session_num==1,meas)), ...
		table2array(pre_tbl(pre_tbl.session_num==2,meas)), ...
		table2array(pre_tbl(pre_tbl.session_num==3,meas)) ];
	% remove rows with NaN
	data_mat = data_mat(~any(isnan(data_mat),2), :);
	% friedman test
	[p, atable, stats] = friedman(data_mat,1,'off');
	out_tbl.friedman(m_cnt) = p;
	out_tbl.friedman_n(m_cnt) = stats.n;
end

for sess_cnt = 1:length(sess_list)
	sess = sess_list(sess_cnt);
		
	pre_sess_tbl = tbl(tbl.arm==arm & tbl.session_num==sess & tbl.pre_post=='pre' , : );
	pre_sess_data = table2array(pre_sess_tbl(:,6:end));
	pre_sess_mean = median(pre_sess_data, 'omitnan');
	pre_sess_sd   = iqr(pre_sess_data);
	pre_sess_cnt  = sum(~isnan(pre_sess_data));
	
	pre_sess_mean_sd = format_with_parens(pre_sess_mean, pre_sess_sd);
	
	sess_str = sess2str(sess);
	out_tbl.(sess_str) = pre_sess_mean_sd';
	out_tbl.([sess_str '_n']) = pre_sess_cnt';
	
end


writetable(out_tbl, ['pre_median_table_' arm '.csv'])

return

% ----------------------
function num_str = format_with_parens(a, b)
% return string of 'a (b)'
num_str = cell(size(a));
for cnt = 1:length(a)
	num_str{cnt} = sprintf('%0.2f (%0.2f)', a(cnt), b(cnt));
	%[num2str(a(cnt)) ' (' num2str(b(cnt)) ')'];
end
return


function sess_str = sess2str(sess_num)
switch sess_num
	case 1
		sess_str = 'one';
	case 2
		sess_str = 'two';
	case 3
		sess_str = 'three';
	otherwise
		sess_str = 'unknown';
end
return

