function sess_tbl = sep_post_minus_pre_stats(varargin)
%SEP_POST_MINUS_PRE_STATS - compute stats on the data in sep_data_format_pre_post_diff.xlsx
%
% sep_data_format_pre_post_diff.xlsx is created with sep_format_avg_data
%
% input parameter-value pairs:
%	file - filename
%	exclude = cell array of strings of subjects to exclude (e.g. {'s2608sens', s2616sens'}

% define input parser
p = inputParser;
p.addParameter('file', 'none', @isstr);
p.addParameter('exclude', {}, @iscell);
p.addParameter('measures',{'N20Cc', 'P25Cc', 'N33Cc', 'P45Cc', 'N60Cc' ,'P100Cc', 'N120Cc', ...};
 	'N20Cc_P25Cc', 'P25Cc_N33Cc', 'N33Cc_P45Cc', 'P45Cc_N60Cc', 'N60Cc_P100Cc', 'P100Cc_N120Cc'}, @iscell);
p.addParameter('arm', {'inv', 'un'}, @iscell);
% p.addParameter('measures',{'P25Cc_N33Cc'}, @iscell);

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
tbl.arm = nominal(tbl.arm);
tbl.measure = nominal(tbl.measure);

out_tbl = table();
descrip_stat_tbl = table();
s = warning('OFF', 'stats:lillietest:OutOfRangePLow');
s = warning('OFF', 'stats:lillietest:OutOfRangePHigh');

if ~isempty(inputs.exclude)
	for s_cnt = 1:length(inputs.exclude)
		tbl = tbl(~strcmp(tbl.Subj, inputs.exclude{s_cnt}), :);
	end
end

sess_list = {'Hs', 'Ha', 'L', 'Hs-g', 'Ha-g', 'L-g'};
post_list = {'post1', 'post2'};
inv_list = inputs.arm;


% each measure
for m_cnt = 1:length(inputs.measures);
	measure = inputs.measures{m_cnt};
	
	% post
	for p_cnt = 1:length(post_list)
		post_var_str = [post_list{p_cnt} '_minus_pre'];
		
		% inv & uninv
		for i_cnt = 1:length(inv_list)
			i_str = inv_list{i_cnt};
			
			tbl_meas = tbl(tbl.measure==measure & tbl.arm==i_str,:);
			
			% group data for each of 6 sessions
			for sess_cnt = 1:length(sess_list)
				sess = sess_list{sess_cnt};
				data = tbl_meas(tbl_meas.SessType==sess, {'Subj', post_var_str});
				descrip_stat_tbl = descrip_stats(data.(post_var_str), descrip_stat_tbl, measure, 'whole', sess, post_var_str, i_str);
				
				% join session data into a single table
				if sess_cnt == 1
					sess_tbl = data;
					sess_tbl.Properties.VariableNames = strrep(sess_tbl.Properties.VariableNames, post_var_str, strrep(sess,'-', '_'));
				else
					sess_tbl = outerjoin(sess_tbl, data, 'Key','Subj','MergeKeys',true);
					sess_tbl.Properties.VariableNames = strrep(sess_tbl.Properties.VariableNames, post_var_str, strrep(sess,'-', '_'));
				end
			end
			
			% kruskalwallis comparisons of sessions 1-6
			data_mat = table2array(sess_tbl(:,2:7));
			if size(data_mat,1) > 1
				[p, ~, stats] = kruskalwallis(data_mat,'', 'off');
				n = stats.n;
				if p < 0.05
					kruskalwallis(data_mat, sess_list, 'on');
					figure
					multcompare(stats);
					ylabel([measure ' ' i_str ' kw sessions 1-6 ' post_var_str])
				end
			else
				p = nan;
				n = nan;
			end
			% add info to the output table
			tmp_tbl = table({measure}, {'whole'}, {'+/-g'}, {i_str}, {post_var_str}, {'kruskalwallis'}, {n}, p, ...
				'VariableNames', {'measure', 'cohort', 'sessions', 'side', 'post', 'test', 'n', 'p'});
			if isempty(out_tbl)
				out_tbl = tmp_tbl;
			else
				out_tbl = vertcat(out_tbl, tmp_tbl);
			end
			
			
			% kw - with glove
			data_mat = table2array(sess_tbl(:,2:4));
			if size(data_mat,1) > 1
				[p, ~, stats] = kruskalwallis(data_mat,'', 'off');
				n = stats.n;
				if p < 0.05
					kruskalwallis(data_mat, sess_list(1:3), 'on');
					figure
					multcompare(stats);
					ylabel([measure ' ' i_str ' kw 3 sessions with glove ' post_var_str])
				end
			else
				p = nan;
				n = nan;
			end
			% add info to the output table
			tmp_tbl = table({measure}, {'whole'}, {'+g'}, {i_str}, {post_var_str}, {'kruskalwallis'}, {n}, p, ...
				'VariableNames', {'measure', 'cohort', 'sessions', 'side', 'post', 'test', 'n', 'p'});
			out_tbl = vertcat(out_tbl, tmp_tbl);
			
			% kw - without glove
			data_mat = table2array(sess_tbl(:,5:7));
			if size(data_mat,1) > 1
				[p, ~, stats] = kruskalwallis(data_mat,'', 'off');
				n = stats.n;
				if p < 0.05
					kruskalwallis(data_mat, sess_list(4:6), 'on');
					figure
					multcompare(stats);
					ylabel([measure ' ' i_str ' kw 3 sessions without glove ' post_var_str])
				end
			else
				p = nan;
				n = nan;
			end
			% add info to the output table
			tmp_tbl = table({measure}, {'6sess'}, {'-g'}, {i_str}, {post_var_str}, {'kruskalwallis'}, {n}, p, ...
				'VariableNames', {'measure', 'cohort', 'sessions', 'side', 'post', 'test', 'n', 'p'});
			out_tbl = vertcat(out_tbl, tmp_tbl);
			
			% kw 6 session cohort - with glove
			data_mat = table2array(sess_tbl(~isnan(sess_tbl.Hs_g),2:4));
			if size(data_mat,1) > 1
				[p, ~, stats] = kruskalwallis(data_mat,'', 'off');
				n = stats.n;
				if p < 0.05
					kruskalwallis(data_mat, sess_list(4:6), 'on');
					figure
					multcompare(stats);
					ylabel([measure ' ' i_str ' kw 3 sessions without glove ' post_var_str])
				end
			else
				p = nan;
				n = nan;
			end
			tmp_tbl = table({measure}, {'6sess'}, {'+g'}, {i_str}, {post_var_str}, {'kruskalwallis'}, {n}, p, ...
				'VariableNames', {'measure', 'cohort', 'sessions', 'side', 'post', 'test', 'n', 'p'});
			out_tbl = vertcat(out_tbl, tmp_tbl);
			
			
			% friedman comparisions
			% all sessions - with glove
			data_mat = table2array(sess_tbl(:,2:4));
			data_mat = data_mat(~any(isnan(data_mat),2), :); % remove rows with nans
			n = size(data_mat,1);
			p = friedman(data_mat, 1, 'off');
			if p < 0.05
				[p,anovatab,stats] = friedman(data_mat, 1, 'on');
				figure
				multcompare(stats);
				ylabel([strrep(measure, '_', ' ')  ' ' i_str ' fr whole cohort with glove '  post_var_str]);
			end
			% add info to the output table
			tmp_tbl = table({measure}, {'whole'}, {'+g'}, {i_str}, {post_var_str}, {'friedman'}, {n}, p, ...
				'VariableNames', {'measure', 'cohort', 'sessions', 'side', 'post', 'test', 'n', 'p'});
			out_tbl = vertcat(out_tbl, tmp_tbl);
			
			
			% friedman comparisions
			% sessions without glove
			data_mat = table2array(sess_tbl(:,5:7));
			data_mat = data_mat(~any(isnan(data_mat),2), :); % remove rows with nans
			descrip_stat_tbl = descrip_stats(data_mat(:,1), descrip_stat_tbl, measure, '6sess', 'Hs_g', post_var_str, i_str);
			descrip_stat_tbl = descrip_stats(data_mat(:,1), descrip_stat_tbl, measure, '6sess', 'Ha_g', post_var_str, i_str);
			descrip_stat_tbl = descrip_stats(data_mat(:,1), descrip_stat_tbl, measure, '6sess', 'L_g', post_var_str, i_str);
				
			n = size(data_mat,1);
			p = friedman(data_mat, 1, 'off');
			if p < 0.05
				[p,anovatab,stats] = friedman(data_mat, 1, 'on');
				multcompare(stats);
				ylabel([strrep(measure, '_', ' ')  ' ' i_str ' fr without glove ' post_var_str ]);
			end
			% add info to the output table
			tmp_tbl = table({measure}, {'6sess'}, {'-g'}, {i_str}, {post_var_str}, {'friedman'}, {n}, p, ...
				'VariableNames', {'measure', 'cohort', 'sessions', 'side', 'post', 'test', 'n', 'p'});
			
			out_tbl = vertcat(out_tbl, tmp_tbl);
			
			% sessions with glove for the 6 session cohort
			data_mat = table2array(sess_tbl(~isnan(sess_tbl.Hs_g),2:4));
			data_mat = data_mat(~any(isnan(data_mat),2), :); % remove rows with nans
			n = size(data_mat,1);
			p = friedman(data_mat, 1, 'off');
			if p < 0.05
				[p,anovatab,stats] = friedman(data_mat, 1, 'on');
				multcompare(stats);
				ylabel([strrep(measure, '_', ' ')  ' ' i_str ' fr 6 session cohort +g ' post_var_str  ]);
			end
			% add info to the output table
			tmp_tbl = table({measure}, {'6sess'}, {'+g'}, {i_str}, {post_var_str}, {'friedman'}, {n}, p, ...
				'VariableNames', {'measure', 'cohort', 'sessions', 'side', 'post', 'test', 'n', 'p'});
			
			out_tbl = vertcat(out_tbl, tmp_tbl);
			
			
			
		end % inv or un

	end % post
end % measure

% request where to save 
[fName, pathName] = getsavenames(fullfile(pwd, 'sep_post_minus_pre_stats.xlsx'), 'Save as');
if isequal(fName, 0) || isequal(pathName, 0),
	disp('Not saving. User canceled.');
	return;
end

writetable(out_tbl, fullfile(pathName,fName))
writetable(out_tbl, fullfile(pathName,fName))
writetable(descrip_stat_tbl, fullfile(pathName,strrep(fName, '.', '_descr_stats.')))
s = warning('ON', 'stats:lillietest:OutOfRangePLow');
return

function out_tbl = 	descrip_stats(data, in_tbl, measure, cohort, sess_gstr, var_str, i_str)

% descriptive stats
	cnt = sum(~isnan(data));
	mean_data = mean(data, 'omitnan');
	std_data = std(data, 'omitnan');
	serr = std_data / sqrt(cnt);
	median_data = median(data, 'omitnan');
	quantile_data = quantile(data ,[.25 .75]); % the quartiles of data
	quartile_range = abs(diff(quantile_data));
	min_data = min(data);
	max_data = max(data);
	
	% normality test
	if sum(~isnan(data)) > 3
		[lillie_h, lillie_p] = lillietest(data); % h = 0 the null hyp that the data is normal cannot be rejected
		% h = 1, the data is not normally distributed
	else
		lillie_h=nan; lillie_p=nan;
	end
	if sum(~isnan(data)) > 2
		try
			[sw_h, sw_p] = swtest(data);
		catch ME
			sw_h = nan; sw_p = nan;
		end
	else
		sw_h = nan; sw_p = nan;
	end
	% add info to the output table
	tmp_tbl = table({measure}, {cohort}, {sess_gstr}, {var_str}, {i_str}, ...
				cnt, mean_data, std_data, serr, median_data, quantile_data(1), quantile_data(2), quartile_range, ...
				min_data, max_data, lillie_h, lillie_p, sw_h, sw_p, ...
		'VariableNames', {'measure', 'cohort', 'sessions', 'post' 'side', ...
		'N', 'mean', 'std_dev', 'std_err', 'median', 'quartile_25', 'quartile_75', 'quartile_range', 'min', 'max', 'lillie_h', 'lillie_p', 'sw_h', 'sw_p'});
	if isempty(in_tbl)
		out_tbl = tmp_tbl;
	else
		out_tbl = vertcat(in_tbl, tmp_tbl);
	end
	
return

function avg_tbl = avg_by_subj(tbl)
avg_tbl = table();
subj_list = unique(tbl.Subj);
for s_cnt = 1:length(subj_list)
	subj = table(subj_list(s_cnt),'VariableNames',{'Subj'});
	subj_tbl = innerjoin(tbl, subj);
	mean_data = mean(subj_tbl.value,'omitnan');
	tmp_tbl = table(subj_list(s_cnt), subj_tbl.arm_stim(1), subj_tbl.measure(1), subj_tbl.pre_post(1), mean_data, ...
		'VariableNames', {'Subj', 'arm', 'measure', 'pre_post', 'session_mean'});
	
	if isempty(avg_tbl)
		avg_tbl = tmp_tbl;
	else
		avg_tbl = vertcat(avg_tbl, tmp_tbl);
	end
	
end
return
