function clinical_pre_stats(varargin)
%clinical_PRE_STATS - compute stats on the data in session_order_and_previous.xlsx
%
% session_order_and_previous.xlsx is created with clinical_pre.m
%
% input parameter-value pairs:
%	file - filename
%	exclude = cell array of strings of subjects to exclude (e.g. {'s2608sens', s2616sens'}

% define input parser
p = inputParser;
p.addParameter('file', 'none', @isstr);
p.addParameter('exclude', {}, @iscell);
p.addParameter('measure_pairs',{{'x2pt_dig2' 'x2pt_dig4'}, ...
	{'monofil_dig2_local' 'monofil_dig4_local'}, ...
	{'proprioception_index_pct' 'proprioception_wrist_pct'}, ...
	{'vibr_dig2_avg' 'vibr_elbw_avg'}}, @iscell);
p.addParameter('arm', {'inv', 'un'}, @iscell);



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
descrip_stat_tbl = table();
s = warning('OFF', 'stats:lillietest:OutOfRangePLow');
s = warning('OFF', 'stats:lillietest:OutOfRangePHigh');

if ~isempty(inputs.exclude)
	for s_cnt = 1:length(inputs.exclude)
		tbl = tbl(~strcmp(tbl.Subj, inputs.exclude{s_cnt}), :);
	end
end

% each measure pair

for mp_cnt = 1:length(inputs.measure_pairs);
	measure_pair = inputs.measure_pairs{mp_cnt};
	
	measure_1 = measure_pair{1};
	measure_2 = measure_pair{2};
	
	
	% inv & uninv
	inv_list = inputs.arm;
	for i_cnt = 1:length(inv_list)
		i_str = inv_list{i_cnt};
		
		tbl_meas_1 = tbl(tbl.measure==measure_1 & tbl.arm_stim==i_str,:);
		tbl_meas_2 = tbl(tbl.measure==measure_2 & tbl.arm_stim==i_str,:);
		
		% whole cohort w/glove Hs, Ha, L
		tbl_meas_sess_1 = tbl_meas_1(tbl_meas_1.SessType=='Hs' | tbl_meas_1.SessType=='Ha' | tbl_meas_1.SessType=='L', :);		
		avg_tbl_meas_1 = avg_by_subj(tbl_meas_sess_1);
		descrip_stat_tbl = descrip_stats(avg_tbl_meas_1.session_mean, descrip_stat_tbl, measure_1, 'whole', 'Hs, Ha, L', i_str);
		tbl_meas_sess_2 = tbl_meas_2(tbl_meas_2.SessType=='Hs' | tbl_meas_2.SessType=='Ha' | tbl_meas_2.SessType=='L', :);
		avg_tbl_meas_2 = avg_by_subj(tbl_meas_sess_2);
		descrip_stat_tbl = descrip_stats(avg_tbl_meas_2.session_mean, descrip_stat_tbl, measure_2, 'whole', 'Hs, Ha, L', i_str);
		
		whole_n = sum(~isnan(avg_tbl_meas_1.session_mean) & ~isnan(avg_tbl_meas_2.session_mean));
		whole_p = signrank(avg_tbl_meas_1.session_mean, avg_tbl_meas_2.session_mean);
		% add info to the output table
		tmp_tbl = table({measure_1}, {measure_2}, {'whole'}, {'Hs, Ha, L'}, {i_str}, whole_n, whole_p, ...
			'VariableNames', {'measure_1', 'measure_2', 'cohort', 'sessions', 'side', 'signrank_n', 'signrank_p'});
		
		if isempty(out_tbl)
			out_tbl = tmp_tbl;
		else
			out_tbl = vertcat(out_tbl, tmp_tbl);
		end
		
		
		% 6-session cohort w/o glove Hs-g, Ha-g, L-g
		tbl_meas_sess_1 = tbl_meas_1(tbl_meas_1.SessType=='Hs-g' | tbl_meas_1.SessType=='Ha-g' | tbl_meas_1.SessType=='L-g', :);		
		avg_tbl_meas_1 = avg_by_subj(tbl_meas_sess_1);
		descrip_stat_tbl = descrip_stats(avg_tbl_meas_1.session_mean, descrip_stat_tbl, measure_1, '6-session',  'Hs-g, Ha-g, L-g', i_str);
		tbl_meas_sess_2 = tbl_meas_2(tbl_meas_2.SessType=='Hs-g' | tbl_meas_2.SessType=='Ha-g' | tbl_meas_2.SessType=='L-g', :);		
		avg_tbl_meas_2 = avg_by_subj(tbl_meas_sess_2);
		descrip_stat_tbl = descrip_stats(avg_tbl_meas_2.session_mean, descrip_stat_tbl, measure_2, '6-session',  'Hs-g, Ha-g, L-g', i_str);
		
		n = sum(~isnan(avg_tbl_meas_1.session_mean) & ~isnan(avg_tbl_meas_2.session_mean));
		p = signrank(avg_tbl_meas_1.session_mean, avg_tbl_meas_2.session_mean);
		% add info to the output table
		tmp_tbl = table({measure_1}, {measure_2}, {'6-session'}, {'Hs-g, Ha-g, L-g'}, {i_str}, n, p,  ...
			'VariableNames', {'measure_1', 'measure_2', 'cohort', 'sessions', 'side', 'signrank_n', 'signrank_p'});
		out_tbl = vertcat(out_tbl, tmp_tbl);
		
		% 6-session cohort all sessions Hs, Ha, L, Hs-g, Ha-g, L-g
		tbl_meas_sess_1 = tbl_meas_1(tbl_meas_1.SessType=='Hs-g' | tbl_meas_1.SessType=='Ha-g' | tbl_meas_1.SessType=='L-g' ...
			| tbl_meas_1.SessType=='Hs' | tbl_meas_1.SessType=='Ha' | tbl_meas_1.SessType=='L', :);		
		avg_tbl_meas_1 = avg_by_subj(tbl_meas_sess_1);
		descrip_stat_tbl = descrip_stats(avg_tbl_meas_1.session_mean, descrip_stat_tbl, measure_1, '6-session',  'Hs, Ha, L, Hs-g, Ha-g, L-g', i_str);
		tbl_meas_sess_2 = tbl_meas_2(tbl_meas_2.SessType=='Hs-g' | tbl_meas_2.SessType=='Ha-g' | tbl_meas_2.SessType=='L-g' ...
			| tbl_meas_2.SessType=='Hs' | tbl_meas_2.SessType=='Ha' | tbl_meas_2.SessType=='L', :);		
		avg_tbl_meas_2 = avg_by_subj(tbl_meas_sess_2);
		descrip_stat_tbl = descrip_stats(avg_tbl_meas_2.session_mean, descrip_stat_tbl, measure_2, '6-session',  'Hs, Ha, L, Hs-g, Ha-g, L-g', i_str);
		
		n = sum(~isnan(avg_tbl_meas_1.session_mean) & ~isnan(avg_tbl_meas_2.session_mean));
		p = signrank(avg_tbl_meas_1.session_mean, avg_tbl_meas_2.session_mean);
		% add info to the output table
		tmp_tbl = table({measure_1}, {measure_2}, {'6-session'}, {'Hs, Ha, L, Hs-g, Ha-g, L-g'}, {i_str}, n, p,  ...
			'VariableNames', {'measure_1', 'measure_2', 'cohort', 'sessions', 'side', 'signrank_n', 'signrank_p'});
		out_tbl = vertcat(out_tbl, tmp_tbl);
		
		% 6-session cohort w/glove Hs, Ha, L
		subjs = tbl_meas_1(tbl_meas_1.SessType=='Hs-g', {'Subj'});
		tbl_meas_1 = innerjoin(tbl_meas_1, subjs);
		tbl_meas_2 = innerjoin(tbl_meas_2, subjs);
		
		tbl_meas_sess_1 = tbl_meas_1(tbl_meas_1.SessType=='Hs' | tbl_meas_1.SessType=='Ha' | tbl_meas_1.SessType=='L', :);		
		avg_tbl_meas_1 = avg_by_subj(tbl_meas_sess_1);
		descrip_stat_tbl = descrip_stats(avg_tbl_meas_1.session_mean, descrip_stat_tbl, measure_1, '6-session', 'Hs, Ha, L', i_str);
		tbl_meas_sess_2 = tbl_meas_2(tbl_meas_2.SessType=='Hs' | tbl_meas_2.SessType=='Ha' | tbl_meas_2.SessType=='L', :);		
		avg_tbl_meas_2 = avg_by_subj(tbl_meas_sess_2);
		descrip_stat_tbl = descrip_stats(avg_tbl_meas_2.session_mean, descrip_stat_tbl, measure_2, '6-session', 'Hs, Ha, L', i_str);
		
		n = sum(~isnan(avg_tbl_meas_1.session_mean) & ~isnan(avg_tbl_meas_2.session_mean));
		p = signrank(avg_tbl_meas_1.session_mean, avg_tbl_meas_2.session_mean);
		% add info to the output table
		tmp_tbl = table({measure_1}, {measure_2}, {'6-session'}, {'Hs, Ha, L'}, {i_str}, n, p,  ...
			'VariableNames', {'measure_1', 'measure_2', 'cohort', 'sessions', 'side', 'signrank_n', 'signrank_p'});
		out_tbl = vertcat(out_tbl, tmp_tbl);
		
				
	end % inv or un

end % measure

% request where to save 
[fName, pathName] = getsavenames(fullfile(pwd, 'pre_grouping_sessions_together_stats.xlsx'), 'Save as');
if isequal(fName, 0) || isequal(pathName, 0),
	disp('Not saving. User canceled.');
	return;
end

writetable(out_tbl, fullfile(pathName,fName))
writetable(out_tbl, fullfile(pathName,fName))
writetable(descrip_stat_tbl, fullfile(pathName,strrep(fName, '.', '_descr_stats.')))
s = warning('ON', 'stats:lillietest:OutOfRangePLow');
return

function out_tbl = 	descrip_stats(data, in_tbl, measure, cohort, tbl_gstr, i_str)

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
	tmp_tbl = table({measure}, {cohort}, {tbl_gstr}, {i_str}, ...
				cnt, mean_data, std_data, serr, median_data, quantile_data(1), quantile_data(2), quartile_range, ...
				min_data, max_data, lillie_h, lillie_p, sw_h, sw_p, ...
		'VariableNames', {'measure', 'cohort', 'sessions', 'side', ...
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
