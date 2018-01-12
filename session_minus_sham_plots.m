function session_minus_sham_plots(varargin)
%SESSION_MINUS_SHAM_PLOTS - compute stats on the data in the clinical_data_taller_difference_variables file
%
% input parameter-value pairs:
%	file - filename

% define input parser
p = inputParser;
p.addParameter('file', 'none', @isstr);
p.addParameter('measure', {'vibr_dig2_avg','vibr_elbw_avg'}, @iscell);
p.addParameter('arm', {'inv','un'}, @iscell);
p.addParameter('post', {'post1','post2'}, @iscell);

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
measure_list =  inputs.measure;

%{'dome_dig2_thresh' ...
%     'dome_dig4_thresh' ...
%     'grpsgth_avg' ...
%     'hcans' ...
%     'lcans' ...
%     'monofil_dig2_local' ...
%     'monofil_dig4_local' ...
%     'prop_table_dig2_error' ...
%     'prop_table_dig2_motionerror' ...
%     'proprioception_index_pct' ...
%     'proprioception_wrist_pct' ...
%     'smobj' ...
%     'stkch' ...
%     'temp' ...
%     'vibr_dig2_avg' ...
%     'vibr_elbw_avg' ...
%     'x2pt_dig2' ...
% 		'x2pt_dig4' }; 
		

descrip_stat_tbl = table();

for m_cnt = 1:length(measure_list);
	measure = measure_list{m_cnt};
	
	tbl_meas = tbl(strcmp(tbl.Measure, measure),:);
	
	% post1 & post2
% 	p_list = {'post1', 'post2'};
	p_list = inputs.post;
	for p_cnt = 1:length(p_list)
		p_str = p_list{p_cnt};
		
		
		% inv & uninv
% 		inv_list = {'inv', 'un'};
		inv_list = inputs.arm;
		for i_cnt = 1:length(inv_list)
 			i_str = inv_list{i_cnt};
			
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
	
			% (Ha-Hs)  (L-Hs)
			hi_minus_sham_data =  hi_data - sham_data;
			lo_minus_sham_data = lo_data - sham_data;
			
% 			descrip_stat_tbl = descrip_stats(hi_minus_sham_data, descrip_stat_tbl, measure, p_str, '+g', i_str, 'Ha-Hs', 'all');
% 			descrip_stat_tbl = descrip_stats(lo_minus_sham_data, descrip_stat_tbl, measure, p_str, '+g', i_str, 'L-Hs', 'all');
			
			hi_vs_lo_all_with_g_n = sum(~isnan(hi_minus_sham_data) & ~isnan(lo_minus_sham_data));
			if hi_vs_lo_all_with_g_n
				figure
				scatterplot_labeled(lo_minus_sham_data, hi_minus_sham_data, tbl_meas.Subj)
				title({[strrep(measure, '_', ' ') ' ' p_str ' ' i_str]; ['All subjs with glove, N=' num2str(hi_vs_lo_all_with_g_n)]})
				ylabel('Ha - Hs')
				xlabel('L - Hs')
				hi_vs_lo_all_with_g_p = signrank(hi_minus_sham_data, lo_minus_sham_data);
				h_txt = text(0, 0, ['p = ' num2str(hi_vs_lo_all_with_g_p)]);
				draggable(h_txt)
				if hi_vs_lo_all_with_g_p < 0.05;
					disp(['signrank: hi vs lo, all with glove - ' measure, ' ' p_str ' ' i_str ' p=' ...
						num2str(hi_vs_lo_all_with_g_p) ' hi mean = ' num2str(mean(hi_minus_sham_data,'omitnan')) ...
						' lo mean = ' num2str(mean(lo_minus_sham_data,'omitnan'))])
				end
			else
				hi_vs_lo_all_with_g_p = nan;
			end
				
			

			% 6 session cohort
			% with glove
			hi_minus_sham_data =  hi_data(~isnan(sham_no_g_data)) - sham_data(~isnan(sham_no_g_data));
			lo_minus_sham_data = lo_data(~isnan(sham_no_g_data)) - sham_data(~isnan(sham_no_g_data));
% 			descrip_stat_tbl = descrip_stats(hi_minus_sham_data, descrip_stat_tbl, measure, p_str, '+g', i_str, 'Ha-Hs', '6sess');
% 			descrip_stat_tbl = descrip_stats(lo_minus_sham_data, descrip_stat_tbl, measure, p_str, '+g', i_str, 'L-Hs', '6sess');
			
			hi_vs_lo_6sess_with_g_n = sum(~isnan(hi_minus_sham_data) & ~isnan(lo_minus_sham_data));
			if hi_vs_lo_6sess_with_g_n
				figure
				scatterplot_labeled(lo_minus_sham_data, hi_minus_sham_data, tbl_meas.Subj(~isnan(sham_no_g_data)))
				title({[strrep(measure, '_', ' ') ' ' p_str ' ' i_str]; ['6-session cohort with glove, N=' num2str(hi_vs_lo_6sess_with_g_n)]})
				ylabel('Ha - Hs')
				xlabel('L - Hs')
				hi_vs_lo_6sess_with_g_p = signrank(hi_minus_sham_data, lo_minus_sham_data);
				h_txt = text(0, 0, ['p = ' num2str(hi_vs_lo_6sess_with_g_p)]);
				draggable(h_txt)
				if hi_vs_lo_6sess_with_g_p < 0.05;
					disp(['signrank: hi vs lo, 6-session with glove - ' measure, ' ' p_str ' ' i_str ' p=' ...
						num2str(hi_vs_lo_6sess_with_g_p) ' hi mean = ' num2str(mean(hi_minus_sham_data,'omitnan')) ...
						' lo mean = ' num2str(mean(lo_minus_sham_data,'omitnan'))])
				end
			else
				hi_vs_lo_6sess_with_g_p = nan;
			end
			
			% without glove
			hi_minus_sham_no_g_data =  hi_no_g_data - sham_no_g_data;
			lo_minus_sham_no_g_data =  lo_no_g_data - sham_no_g_data;
			
% 			descrip_stat_tbl = descrip_stats(hi_minus_sham_no_g_data, descrip_stat_tbl, measure, p_str, '-g', i_str, 'Ha-Hs', '6sess');
% 			descrip_stat_tbl = descrip_stats(lo_minus_sham_no_g_data, descrip_stat_tbl, measure, p_str, '-g', i_str, 'L-Hs', '6sess');

	
			hi_vs_lo_6sess_without_g_n = sum(~isnan(hi_minus_sham_no_g_data) & ~isnan(lo_minus_sham_no_g_data));
			if hi_vs_lo_6sess_without_g_n
				figure
				scatterplot_labeled(lo_minus_sham_no_g_data, hi_minus_sham_no_g_data, tbl_meas.Subj)
				title({[strrep(measure, '_', ' ') ' ' p_str ' ' i_str]; ['6-session cohort without glove, N=' num2str(hi_vs_lo_6sess_without_g_n)]})
				ylabel('Ha - Hs')
				xlabel('L - Hs')
				hi_vs_lo_6sess_without_g_p = signrank(hi_minus_sham_no_g_data, lo_minus_sham_no_g_data);
				h_txt = text(0, 0, ['p = ' num2str(hi_vs_lo_6sess_without_g_p)]);
				draggable(h_txt)
				if hi_vs_lo_6sess_without_g_p < 0.05;
					disp(['signrank: hi vs lo, 6-session without glove - ' measure, ' ' p_str ' ' i_str ' p=' ...
						num2str(hi_vs_lo_6sess_without_g_p) ' hi mean = ' num2str(mean(hi_minus_sham_no_g_data,'omitnan')) ...
						' lo mean = ' num2str(mean(lo_minus_sham_no_g_data,'omitnan'))])
				end
			else
				hi_vs_lo_6sess_without_g_p = nan;
			end
				
			
			% add info to the output table
% 			tmp_tbl = table({measure}, {[p_str '-pre']}, {i_str},  ...
% 				hi_vs_lo_all_with_g_n, hi_vs_lo_all_with_g_p,  ...
% 				hi_vs_lo_6sess_with_g_n, hi_vs_lo_6sess_with_g_p, hi_vs_lo_6sess_without_g_n, hi_vs_lo_6sess_without_g_p, ...
% 				'VariableNames', {'measure', 'post', 'side', ...
% 				'hi_vs_lo_all_with_g_n', 'hi_vs_lo_all_with_g_p', ...
% 				'hi_vs_lo_6sess_with_g_n', 'hi_vs_lo_6sess_with_g_p', 'hi_vs_lo_6sess_without_g_n', 'hi_vs_lo_6sess_without_g_p'});
% 			if isempty(out_tbl)
% 				out_tbl = tmp_tbl;
% 			else
% 				out_tbl = vertcat(out_tbl, tmp_tbl);
% 			end
			
		end % inv or un

	end % post1, post2
end % measure

% request where to save 
% [fName, pathName] = getsavenames(fullfile(pwd, 'ha_minus_hs_v_L_minus_hs_stats.xlsx'), 'Save as');
% if isequal(fName, 0) || isequal(pathName, 0),
% 	disp('Not saving. User canceled.');
% 	return;
% end
% 
% writetable(out_tbl, fullfile(pathName,fName))
% writetable(descrip_stat_tbl, fullfile(pathName,strrep(fName, '.', '_descr_stats.')))
return


function out_tbl = 	descrip_stats(data, in_tbl, measure, p_str, tbl_gstr, i_str, sess, cohort)

% descriptive stats
	cnt = sum(~isnan(data));
	mean_data = mean(data, 'omitnan');
	std_data = std(data, 'omitnan');
	serr = std_data / sqrt(cnt);
	median_data = median(data, 'omitnan');
	quantile_data = quantile(data ,[.25 .75]); % the quartiles of data
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
		[sw_h, sw_p] = swtest(data);
	else
		sw_h = nan; sw_p = nan;
	end
	% add info to the output table
	tmp_tbl = table({measure}, {[p_str '-pre']}, {tbl_gstr}, {i_str}, {sess}, {cohort}, ...
				cnt, mean_data, std_data, serr, median_data, quantile_data(1), quantile_data(2), ...
				min_data, max_data, lillie_h, lillie_p, sw_h, sw_p, ...
		'VariableNames', {'measure', 'post', 'glove', 'side', 'session', 'cohort' ...
		'N', 'mean', 'std_dev', 'std_err', 'median', 'quartile_25', 'quartile_75', 'min', 'max', 'lillie_h', 'lillie_p', 'sw_h', 'sw_p'});
	if isempty(in_tbl)
		out_tbl = tmp_tbl;
	else
		out_tbl = vertcat(in_tbl, tmp_tbl);
	end
	
return
