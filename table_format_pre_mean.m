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
	'x2pt_dig4', 'monofil_dig4_local', 'proprioception_index_pct', 'vibr_dig2_avg' }, @iscell);
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

sess_list = {'H',  'L', 'S'};
post_list = {'d_post1','d_post2'};
arm = inputs.arm;


out_tbl = cell2table(inputs.measures', 'VariableNames', {'Measure'});

% % each measure
% for m_cnt = 1:length(inputs.measures)
% 	measure = inputs.measures{m_cnt};
			
	% pre data for all sessions
	pre_tbl = tbl(tbl.arm==arm & (tbl.SessType=='H' | tbl.SessType=='L' | tbl.SessType=='S') ...
					& tbl.pre_post=='pre' , : );
	pre_data = table2array(pre_tbl(:,5:end));
	pre_mean = mean(pre_data, 'omitnan');
	pre_sd   = std(pre_data, 'omitnan');
	pre_cnt  = sum(~isnan(pre_data));
	
	pre_mean_sd = format_with_parens(pre_mean, pre_sd);
	
	out_tbl.pre = pre_mean_sd';
	out_tbl.pre_n = pre_cnt';

for sess_cnt = 1:length(sess_list)
	sess = sess_list{sess_cnt};
	for post_cnt = 1:length(post_list)
		pst = post_list{post_cnt};
		
		pst_tbl = tbl(tbl.arm==arm & tbl.SessType==sess & tbl.pre_post==pst , : );
		pst_data = table2array(pst_tbl(:,5:end));
		pst_mean = mean(pst_data, 'omitnan');
		pst_sd   = std(pst_data, 'omitnan');
		pst_cnt  = sum(~isnan(pst_data));
		
		pst_mean_sd = format_with_parens(pst_mean, pst_sd);
		
		out_tbl.([sess '_' pst]) = pst_mean_sd';
		out_tbl.([sess '_' pst '_n']) = pst_cnt';
		
	end
end

writetable(out_tbl, ['mean_table_' arm '.csv'])

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


