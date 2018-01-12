function kw_session_stats(varargin)
%SESSION_SESSION_STATS - compute stats on the data in the clinical_data_taller_difference_variables file
%
% input parameter-value pairs:
%	file - filename

% define input parser
p = inputParser;
p.addParamValue('file', 'none', @isstr);

% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none'),		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.txt', 'Pick clinical measures taller difference variables file');
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
		

descrip_stat_tbl = table();
s = warning('OFF', 'stats:lillietest:OutOfRangePLow');
s = warning('OFF', 'stats:lillietest:OutOfRangePHigh');

for m_cnt = 1:length(measure_list);
	measure = measure_list{m_cnt};
	
	tbl_meas = tbl(strcmp(tbl.Measure, measure),:);
	
		
	
	% inv & uninv
	inv_list = {'inv', 'un'};
	for i_cnt = 1:length(inv_list)
		i_str = inv_list{i_cnt};
		
		% pre
		pre_sham_var = ['Hs_pre_' i_str];
		pre_hi_var = ['Ha_pre_' i_str];
		pre_lo_var = ['L_pre_' i_str];
		pre_sham_no_g_var = ['Hs_g_pre_' i_str];
		pre_hi_no_g_var = ['Ha_g_pre_' i_str];
		pre_lo_no_g_var = ['L_g_pre_' i_str];
		pre_sham_data = tbl_meas.(pre_sham_var);
		pre_hi_data = tbl_meas.(pre_hi_var);
		pre_lo_data = tbl_meas.(pre_lo_var);
		pre_sham_no_g_data = tbl_meas.(pre_sham_no_g_var);
		pre_hi_no_g_data = tbl_meas.(pre_hi_no_g_var);
		pre_lo_no_g_data = tbl_meas.(pre_lo_no_g_var);
		
		descrip_stat_tbl = descrip_stats(pre_sham_data, descrip_stat_tbl, measure, 'pre', '+g', i_str, 'Hs', 'all');
		descrip_stat_tbl = descrip_stats(pre_hi_data, descrip_stat_tbl, measure, 'pre', '+g', i_str, 'Ha', 'all');
		descrip_stat_tbl = descrip_stats(pre_lo_data, descrip_stat_tbl, measure, 'pre', '+g', i_str, 'L', 'all');
		
		pre_sham_data =  pre_sham_data(~isnan(pre_sham_no_g_data));
		pre_hi_data =  pre_hi_data(~isnan(pre_sham_no_g_data));
		pre_lo_data = pre_lo_data(~isnan(pre_sham_no_g_data));
		descrip_stat_tbl = descrip_stats(pre_sham_data, descrip_stat_tbl, measure, 'pre', '+g', i_str, 'Hs', '6sess');
		descrip_stat_tbl = descrip_stats(pre_hi_data, descrip_stat_tbl, measure, 'pre', '+g', i_str, 'Ha', '6sess');
		descrip_stat_tbl = descrip_stats(pre_lo_data, descrip_stat_tbl, measure, 'pre', '+g', i_str, 'L', '6sess');
		
		descrip_stat_tbl = descrip_stats(pre_sham_no_g_data, descrip_stat_tbl, measure, 'pre', '-g', i_str, 'Hs', '6sess');
		descrip_stat_tbl = descrip_stats(pre_hi_no_g_data, descrip_stat_tbl, measure, 'pre', '-g', i_str, 'Ha', '6sess');
		descrip_stat_tbl = descrip_stats(pre_lo_no_g_data, descrip_stat_tbl, measure, 'pre', '-g', i_str, 'L', '6sess');
			
		% post1 & post2
		p_list = {'post1', 'post2'};
		for p_cnt = 1:length(p_list)
			p_str = p_list{p_cnt};
			
			% sham, hi, lo with glove
			sham_var = ['d_Hs_' p_str '_' i_str];
			hi_var = ['d_Ha_' p_str '_' i_str];
			lo_var = ['d_L_' p_str '_' i_str];
			
			% sham, hi, lo without glove
			sham_no_g_var = ['d_Hs_g_' p_str '_' i_str];
			hi_no_g_var = ['d_Ha_g_' p_str '_' i_str];
			lo_no_g_var = ['d_L_g_' p_str '_' i_str];
			
			sham_data = tbl_meas.(sham_var);
			hi_data = tbl_meas.(hi_var);
			lo_data = tbl_meas.(lo_var);
			sham_no_g_data = tbl_meas.(sham_no_g_var);
			hi_no_g_data = tbl_meas.(hi_no_g_var);
			lo_no_g_data = tbl_meas.(lo_no_g_var);
			
			
			% With glove data - ALL subjects
			descrip_stat_tbl = descrip_stats(sham_data, descrip_stat_tbl, measure, p_str, '+g', i_str, 'Hs', 'all');
			descrip_stat_tbl = descrip_stats(hi_data, descrip_stat_tbl, measure, p_str, '+g', i_str, 'Ha', 'all');
			descrip_stat_tbl = descrip_stats(lo_data, descrip_stat_tbl, measure, p_str, '+g', i_str, 'L', 'all');
			
			data_mat = [sham_data, hi_data, lo_data, sham_no_g_data, hi_no_g_data, lo_no_g_data];
			kw_n = size(data_mat,1);		
			if kw_n > 1
				[kw_p, ~, stats] = kruskalwallis(data_mat, {'sham+g', 'hi+g', 'lo+g', 'sham-g', 'hi-g', 'lo-g' }, 'off');
				kw_n_list = stats.n;
				if kw_p < 0.05
					[p,anovatab,stats] = kruskalwallis(data_mat, {'sham+g', 'hi+g', 'lo+g', 'sham-g', 'hi-g', 'lo-g' }, 'on');
					disp(['kw ' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
					comp = multcompare(stats)
					ylabel([ 'kw ' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
				end
			else
				kw_p = nan;
			end

			% with glove, all subjects, with glove sessions only
			data_mat = [sham_data, hi_data, lo_data];
			kw_n = size(data_mat,1);		
			if kw_n > 1
				[kw3way_p, ~, stats] = kruskalwallis(data_mat, {'sham+g', 'hi+g', 'lo+g' }, 'off');
				kw3way_n_list = stats.n;
				if kw3way_p < 0.05
					[p,anovatab,stats] = kruskalwallis(data_mat, {'sham+g', 'hi+g', 'lo+g' }, 'on');
					disp(['kw ' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
					comp = multcompare(stats)
					ylabel([ 'kw ' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
				end
			else
				kw3way_p = nan;
				kw3way_n_list = nan;
			end


			% 6 session cohort
			% with glove
			
			
			sham_data =  sham_data(~isnan(sham_no_g_data));
			hi_data =  hi_data(~isnan(sham_no_g_data));
			lo_data = lo_data(~isnan(sham_no_g_data));
			descrip_stat_tbl = descrip_stats(sham_data, descrip_stat_tbl, measure, p_str, '+g', i_str, 'Hs', '6sess');
			descrip_stat_tbl = descrip_stats(hi_data, descrip_stat_tbl, measure, p_str, '+g', i_str, 'Ha', '6sess');
			descrip_stat_tbl = descrip_stats(lo_data, descrip_stat_tbl, measure, p_str, '+g', i_str, 'L', '6sess');
			
			data_mat = [sham_data, hi_data, lo_data];
			if size(data_mat,1) > 1
				[kw_6sess_with_g_p, ~, stats] = kruskalwallis(data_mat, {'sham+g', 'hi+g', 'lo+g'}, 'off');
				if isnan(kw_6sess_with_g_p)
					%keyboard
				end
				kw_6sess_with_n_list = stats.n;
				if kw_6sess_with_g_p < 0.05;
					[p,anovatab,stats] = kruskalwallis(data_mat, {'sham+g', 'hi+g', 'lo+g' }, 'on');
					disp(['kw 6 sess with g ' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
					comp = multcompare(stats)
					ylabel([ 'kw  6 sess with g' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
				end
			else
				kw_6sess_with_g_p = nan;
				kw_6sess_with_n_list = nan;
			end
			
			% without glove
			
			descrip_stat_tbl = descrip_stats(sham_no_g_data, descrip_stat_tbl, measure, p_str, '-g', i_str, 'Hs', '6sess');
			descrip_stat_tbl = descrip_stats(hi_no_g_data, descrip_stat_tbl, measure, p_str, '-g', i_str, 'Ha', '6sess');
			descrip_stat_tbl = descrip_stats(lo_no_g_data, descrip_stat_tbl, measure, p_str, '-g', i_str, 'L', '6sess');
			
			data_mat = [sham_no_g_data, hi_no_g_data, lo_no_g_data];
			if size(data_mat,1) > 1
				[kw_6sess_without_g_p, ~, stats] = kruskalwallis(data_mat, {'sham-g', 'hi-g', 'lo-g'}, 'off');
				kw_6sess_without_n_list = stats.n;
				if kw_6sess_without_g_p < 0.05;
					[p,anovatab,stats] = kruskalwallis(data_mat, {'sham-g', 'hi-g', 'lo-g' }, 'on');
					disp(['kw 6 sess without g ' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
					comp = multcompare(stats)
					ylabel([ 'kw  6 sess without g' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
				end
			else
				kw_6sess_without_g_p = nan;
				kw_6sess_without_n_list = nan;
			end
			
				
			
			% add info to the output table
			tmp_tbl = table({measure}, {[p_str '-pre']}, {i_str},  ...
				{kw_n_list}, kw_p, {kw3way_n_list}, kw3way_p, {kw_6sess_with_n_list}, kw_6sess_with_g_p, {kw_6sess_without_n_list}, kw_6sess_without_g_p, ...
				'VariableNames', {'measure', 'post', 'side', ...
				 'kw_6way_n', 'kw_6way_p', 'kw_3way_with_g_n', 'kw_3way_with_g_p', 'kw_6sess_with_g_n', 'kw_6sess_with_g_p', 'kw_6sess_without_g_n', 'kw_6sess_without_g_p',  });
			if isempty(out_tbl)
				out_tbl = tmp_tbl;
			else
				out_tbl = vertcat(out_tbl, tmp_tbl);
			end
			
		end % post1, post2

	end % inv or un
end % measure

% request where to save 
[fName, pathName] = getsavenames(fullfile(pwd, 'kw_stats.xlsx'), 'Save as');
if isequal(fName, 0) || isequal(pathName, 0),
	disp('Not saving. User canceled.');
	return;
end

writetable(out_tbl, fullfile(pathName,fName))
writetable(descrip_stat_tbl, fullfile(pathName,strrep(fName, '.', '_descr_stats.')))
s = warning('ON', 'stats:lillietest:OutOfRangePLow');
return


function out_tbl = 	descrip_stats(data, in_tbl, measure, p_str, tbl_gstr, i_str, sess, cohort)

% descriptive stats
	cnt = sum(~isnan(data));
	mean_data = mean(data, 'omitnan');
	std_data = std(data, 'omitnan');
	serr = std_data / sqrt(cnt);
	median_data = median(data, 'omitnan');
	quantile_data = quantile(data ,[.25 .75]); % the quartiles of data
	quartile_range = abs(diff(quantile_data));
	min_data = min(data);
	if isempty(min_data), min_data = nan; end
	max_data = max(data);
	if isempty(max_data), max_data = nan; end
	
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
	
	if strncmp(p_str,'post', 4)
		pre_post_str = [p_str '-pre'];
	else
		pre_post_str = p_str;
	end
	% add info to the output table
	tmp_tbl = table({measure}, {pre_post_str}, {tbl_gstr}, {i_str}, {sess}, {cohort}, ...
				cnt, mean_data, std_data, serr, median_data, quantile_data(1), quantile_data(2), quartile_range, ...
				min_data, max_data, lillie_h, lillie_p, sw_h, sw_p, ...
		'VariableNames', {'measure', 'pre_post', 'glove', 'side', 'session', 'cohort' ...
		'N', 'mean', 'std_dev', 'std_err', 'median', 'quartile_25', 'quartile_75', 'quartile_range', 'min', 'max', 'lillie_h', 'lillie_p', 'sw_h', 'sw_p'});
	if isempty(in_tbl)
		out_tbl = tmp_tbl;
	else
		out_tbl = vertcat(in_tbl, tmp_tbl);
	end
	
return
