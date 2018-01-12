function session_ordered_pre_stats(varargin)
%SESSION_ORDERED_PRE_STATS - compute stats on the data in session_order_and_previous.xlsx
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
p.addParameter('measures',{'x2pt_dig4', 'x2pt_dig2', ...
	'monofil_dig2_local', 'monofil_dig4_local', ...
	'proprioception_index_pct', 'proprioception_wrist_pct', ...
	'vibr_dig2_avg', 'vibr_elbw_avg'}, @iscell);
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

% each measure

for m_cnt = 1:length(inputs.measures);
	measure = inputs.measures{m_cnt};
		
	% inv & uninv
	inv_list = inputs.arm;
	for i_cnt = 1:length(inv_list)
		i_str = inv_list{i_cnt};
		
		tbl_meas = tbl(tbl.measure==measure & tbl.arm_stim==i_str,:);
		
		
		% group data for each of 6 sessions
		for sess_num = 1:6,
			var_str = ['sess_' num2str(sess_num)];
			data.(var_str) = tbl_meas(tbl_meas.session_num==sess_num, {'Subj', 'value'});		
			descrip_stat_tbl = descrip_stats(data.(var_str).value, descrip_stat_tbl, measure, 'whole', var_str, i_str);
			
			% join session data into a single table
			if sess_num == 1
				sess_tbl = data.(var_str);
				sess_tbl.Properties.VariableNames = strrep(sess_tbl.Properties.VariableNames, 'value', var_str);
			else
				sess_tbl = outerjoin(sess_tbl, data.(var_str), 'Key','Subj','MergeKeys',true);
				sess_tbl.Properties.VariableNames = strrep(sess_tbl.Properties.VariableNames, 'value', var_str);
			end
		end
			
		
		% friedman comparisions
		% sessions 1-6
		data_mat = table2array(sess_tbl(:,2:7));
		data_mat = data_mat(~any(isnan(data_mat),2), :); % remove rows with nans
		n = size(data_mat,1);
		p = friedman(data_mat, 1, 'off');
		if p < 0.05 	
			[p,anovatab,stats] = friedman(data_mat, 1, 'on');
			multcompare(stats);
			ylabel([strrep(measure, '_', ' ')  ' ' i_str ' sessions 1-6' ]);
		end
		% add info to the output table
		tmp_tbl = table({measure}, {'whole'}, {'sessions 1-6'}, {i_str}, n, p, ...
			'VariableNames', {'measure', 'cohort', 'sessions', 'side', 'fr_n', 'fr_p'});
		
		if isempty(out_tbl)
			out_tbl = tmp_tbl;
		else
			out_tbl = vertcat(out_tbl, tmp_tbl);
		end
		
		
		% sessions 1-3
		data_mat = table2array(sess_tbl(:,2:4));
		data_mat = data_mat(~any(isnan(data_mat),2), :); % remove rows with nans
		n = size(data_mat,1);
		p = friedman(data_mat, 1, 'off');
		if p < 0.05 	
			[p,anovatab,stats] = friedman(data_mat, 1, 'on');
			multcompare(stats);
			ylabel([strrep(measure, '_', ' ')  ' ' i_str ' sessions 1-3' ]);
		end
		% add info to the output table
		tmp_tbl = table({measure}, {'whole'}, {'sessions 1-3'}, {i_str}, n, p, ...
			'VariableNames', {'measure', 'cohort', 'sessions', 'side', 'fr_n', 'fr_p'});
		
		out_tbl = vertcat(out_tbl, tmp_tbl);

		% sessions 4-6
		data_mat = table2array(sess_tbl(:,5:7));
		data_mat = data_mat(~any(isnan(data_mat),2), :); % remove rows with nans
		n = size(data_mat,1);
		p = friedman(data_mat, 1, 'off');
		if p < 0.05 	
			[p,anovatab,stats] = friedman(data_mat, 1, 'on');
			multcompare(stats);
			ylabel([strrep(measure, '_', ' ')  ' ' i_str ' sessions 4-6'  ]);
		end
		% add info to the output table
		tmp_tbl = table({measure}, {'whole'}, {'sessions 4-6'}, {i_str}, n, p, ...
			'VariableNames', {'measure', 'cohort', 'sessions', 'side', 'fr_n', 'fr_p'});
		
		out_tbl = vertcat(out_tbl, tmp_tbl);

		
				
	end % inv or un

end % measure

% request where to save 
[fName, pathName] = getsavenames(fullfile(pwd, 'pre_sessions_by_order_stats.xlsx'), 'Save as');
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
