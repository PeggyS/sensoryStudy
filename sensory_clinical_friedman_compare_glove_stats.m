function sensory_clinical_friedman_compare_glove_stats(varargin)
%SENSORY_CLINICAL_COMPARE_GLOVE_STATS - compute comparison stats on the data in the clinical_data_taller_difference_variables file
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
		
	
	measure_list =  {'vibr_dig2_avg' ...
    'vibr_elbw_avg'}

for m_cnt = 1:length(measure_list);
	measure = measure_list{m_cnt};
	
	tbl_meas = tbl(strcmp(tbl.Measure, measure),:);
	
	% post1 & post2
	p_list = {'post1', 'post2'};
	for p_cnt = 1:length(p_list)
		p_str = p_list{p_cnt};
		
		
		% inv & uninv
		inv_list = {'inv', 'un'};
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
			
			% compare all 6
			% kruskal wallis
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
	
			% friedman - all 6
			data_mat = [sham_data, hi_data, lo_data, sham_no_g_data, hi_no_g_data, lo_no_g_data];
			data_mat = data_mat(~any(isnan(data_mat),2), :);
			fr_n = size(data_mat,1);		
			if fr_n > 1
				fr_p = friedman(data_mat, 1, 'off');
				if fr_p < 0.05
					[p,anovatab,stats] = friedman(data_mat, 1, 'on');
					disp([ 'fr ' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
					figure
					comp = multcompare(stats)
					ylabel([ 'fr ' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
				end
			else
				fr_p = nan;
			end
			
			% With glove data
			% compare all 3 
			data_mat = [sham_data, hi_data, lo_data];
			data_mat = data_mat(~any(isnan(data_mat),2), :);
			fr_with_n = size(data_mat,1);		
			if fr_with_n > 1
				fr_with_p = friedman(data_mat, 1, 'off');
				if fr_with_p < 0.05
					[p,anovatab,stats] = friedman(data_mat, 1, 'on');
					disp(['fr with glove - ' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
					figure
					comp = multcompare(stats)
					ylabel(['with glove - ' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
				end
			else
				fr_with_p = nan;
			end
			
			% between sham, hi, lo comparisons
			hi_with_n = sum(~isnan(sham_data) & ~isnan(hi_data));
			if hi_with_n
				hi_with_p = signrank(sham_data, hi_data);
			else
				hi_with_p = nan;
			end
			lo_with_n = sum(~isnan(sham_data) & ~isnan(lo_data));
			if lo_with_n
				lo_with_p = signrank(sham_data, lo_data);
			else
				lo_with_p = nan;
			end
			hi_v_lo_with_n = sum(~isnan(hi_data) & ~isnan(lo_data));
			if hi_v_lo_with_n
				hi_v_lo_with_p = signrank(hi_data, lo_data);
			else
				hi_v_lo_with_p = nan;
			end
			
			% without glove data	
			data_mat = [sham_no_g_data, hi_no_g_data, lo_no_g_data];
			data_mat = data_mat(~any(isnan(data_mat),2), :);
			fr_without_n = size(data_mat,1);		
			if fr_without_n > 1
				fr_without_p = friedman(data_mat, 1, 'off');
				if fr_without_p < 0.05
					[p,anovatab,stats] = friedman(data_mat, 1, 'on');
					disp(['fr without glove - ' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
					figure
					comp = multcompare(stats)
					ylabel(['without glove - ' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
				end
			else
				fr_without_p = nan;
			end
			% between sham, hi, lo comparisons
			hi_without_n = sum(~isnan(sham_no_g_data) & ~isnan(hi_no_g_data));
			if hi_without_n
				hi_without_p = signrank(sham_no_g_data, hi_no_g_data);
			else
				hi_without_p = nan;
			end
			lo_without_n = sum(~isnan(sham_no_g_data) & ~isnan(lo_no_g_data));
			if lo_without_n
				lo_without_p = signrank(sham_no_g_data, lo_no_g_data);
			else
				lo_without_p = nan;
			end
			hi_v_lo_without_n = sum(~isnan(hi_no_g_data) & ~isnan(lo_no_g_data));
			if hi_v_lo_without_n
				hi_v_lo_without_p = signrank(hi_no_g_data, lo_no_g_data);
			else
				hi_v_lo_without_p = nan;
			end
			
			
			% without glove group, with glove data (6 session cohort)
			data_mat = [sham_data(~isnan(sham_no_g_data)), hi_data(~isnan(sham_no_g_data)), lo_data(~isnan(sham_no_g_data))];
			data_mat = data_mat(~any(isnan(data_mat),2), :);
			fr_without_grp_with_n = size(data_mat,1);	
			if fr_without_grp_with_n > 1
				fr_without_grp_with_p = friedman(data_mat, 1, 'off');
				if fr_without_grp_with_p < 0.05
					[p,anovatab,stats] = friedman(data_mat, 1, 'on');
					disp(['fr 6-session cohort without glove - ' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
					figure
					comp  = multcompare(stats)
					ylabel(['6-session cohort group without glove - ' strrep(measure,'_',' ') ' ' i_str ' ' p_str])
				end
			else
				fr_without_grp_with_p = nan;
			end
			% between sham, hi, lo comparisons
			tmp_sham_data = sham_data(~isnan(sham_no_g_data));
			tmp_hi_data = hi_data(~isnan(sham_no_g_data));
			tmp_lo_data = lo_data(~isnan(sham_no_g_data));
			hi_wo_grp_w_data_n = sum(~isnan(tmp_sham_data) & ~isnan(tmp_hi_data));
			if hi_wo_grp_w_data_n
				hi_wo_grp_w_data_p = signrank(tmp_sham_data, tmp_hi_data);
			else
				hi_wo_grp_w_data_p = nan;
			end
			lo_wo_grp_w_data_n = sum(~isnan(tmp_sham_data) & ~isnan(tmp_lo_data));
			if lo_wo_grp_w_data_n
				lo_wo_grp_w_data_p = signrank(tmp_sham_data, tmp_lo_data);
			else
				lo_wo_grp_w_data_p = nan;
			end
			hi_v_lo_wo_grp_w_data_n = sum(~isnan(tmp_hi_data) & ~isnan(tmp_lo_data));
			if hi_v_lo_wo_grp_w_data_n
				hi_v_lo_wo_grp_w_data_p = signrank(tmp_hi_data, tmp_lo_data);
			else
				hi_v_lo_wo_grp_w_data_p = nan;
			end
				
	
			
			% with & without glove comparisons
			sham_n = sum(~isnan(sham_data) & ~isnan(sham_no_g_data));
			if sham_n
				sham_p = signrank(sham_data, sham_no_g_data);
			else
				sham_p = nan;
			end
			hi_n = sum(~isnan(hi_data) & ~isnan(hi_no_g_data));
			if hi_n
				hi_p = signrank(hi_data, hi_no_g_data);
			else
				hi_p = nan;
			end
			lo_n = sum(~isnan(lo_data) & ~isnan(lo_no_g_data));
			if lo_n
				lo_p = signrank(lo_data, lo_no_g_data);
			else
				lo_p = nan;
			end
			
			% (Ha-Hs) with glove vs Ha-Hs without glove
			hi_minus_sham_data =  hi_data - sham_data;
			hi_minus_sham_no_g_data =  hi_no_g_data - sham_no_g_data;
			hi_minus_sham_n = sum(~isnan(hi_minus_sham_data) & ~isnan(hi_minus_sham_no_g_data));
			if hi_minus_sham_n
				hi_minus_sham_p = signrank(hi_minus_sham_data, hi_minus_sham_no_g_data);
				if hi_minus_sham_p < 0.05;
					disp(['signrank: Ha-Hs with vs without glove - ' measure, ' ' p_str ' ' i_str ' p=' ...
						num2str(hi_minus_sham_p) ' mean w/g = ' num2str(mean(hi_minus_sham_data,'omitnan')) ...
						' mean w/o g = ' num2str(mean(hi_minus_sham_no_g_data,'omitnan'))])
				end
			else
				hi_minus_sham_p = nan;
			end
			% (L-Hs) with glove vs L-Hs without glove
			lo_minus_sham_data =  lo_data - sham_data;
			lo_minus_sham_no_g_data = lo_no_g_data - sham_no_g_data ;
			lo_minus_sham_n = sum(~isnan(lo_minus_sham_data) & ~isnan(lo_minus_sham_no_g_data));
			if lo_minus_sham_n
				lo_minus_sham_p = signrank(lo_minus_sham_data, lo_minus_sham_no_g_data);
			else
				lo_minus_sham_p = nan;
			end
			
			% add info to the output table
			tmp_tbl = table({measure}, {[p_str '-pre']}, {i_str}, {kw_n_list}, kw_p, fr_n, fr_p, fr_with_n, fr_with_p, ...
				hi_with_n, hi_with_p, lo_with_n, lo_with_p, hi_v_lo_with_n, hi_v_lo_with_p, ...
				fr_without_n, fr_without_p, hi_without_n, hi_without_p, lo_without_n, lo_without_p, hi_v_lo_without_n, hi_v_lo_without_p, ...
				fr_without_grp_with_n, fr_without_grp_with_p, ...
				hi_wo_grp_w_data_n, hi_wo_grp_w_data_p, lo_wo_grp_w_data_n, lo_wo_grp_w_data_p, hi_v_lo_wo_grp_w_data_n, hi_v_lo_wo_grp_w_data_p, ...
				sham_n, sham_p, hi_n, hi_p, lo_n, lo_p, ...
				hi_minus_sham_n, hi_minus_sham_p, lo_minus_sham_n, lo_minus_sham_p, ...
				'VariableNames', {'measure', 'post', 'side', 'kw_6way_n', 'kw_6way_p', 'fr_6way_n', 'fr_6way_p', 'fr_with_g_n', 'fr_with_g_p', ...
				'with_g_Hs_v_Ha_n', 'with_g_Hs_v_Ha_p', 'with_g_Hs_v_L_n', 'with_g_Hs_v_L_p', 'with_g_L_v_Ha_n', 'with_g_L_v_Ha_p', ...
				'fr_without_g_n', 'fr_without_g_p', ...
				'without_g_Hs_v_Ha_n', 'without_g_Hs_v_Ha_p', 'without_g_Hs_v_L_n', 'without_g_Hs_v_L_p', 'without_g_L_v_Ha_n', 'without_g_L_v_Ha_p', ...
				'fr_without_grp_with_g_data_n', 'fr_without_grp_with_g_data_p',  ...
				'without_grp_w_g_Hs_v_Ha_n', 'without_grp_w_g_Hs_v_Ha_p', 'without_grp_w_g_Hs_v_L_n', 'without_grp_w_g_Hs_v_L_p', 'without_grp_w_g_L_v_Ha_n', 'without_grp_w_g_L_v_Ha_p', ...
				'Hs_v_Hs_g_n', 'Hs_v_Hs_g_p', 'Ha_v_Ha_g_n', 'Ha_v_Ha_g_p', 'L_v_L_g_n', 'L_v_L_g_p', ...
				'Ha_minus_Hs_g_vs_no_g_n', 'Ha_minus_Hs_g_vs_no_g_p', 'L_minus_Hs_g_vs_no_g_n', 'L_minus_Hs_g_vs_no_g_p'});
			if isempty(out_tbl)
				out_tbl = tmp_tbl;
			else
				out_tbl = vertcat(out_tbl, tmp_tbl);
			end
			
		end % inv or un

	end % post1, post2
end % measure

% request where to save 
[fName, pathName] = getsavenames(fullfile(pwd, 'glove_comparison_stats.xlsx'), 'Save as');
if isequal(fName, 0) || isequal(pathName, 0),
	disp('Not saving. User canceled.');
	return;
end

writetable(out_tbl, fullfile(pathName,fName))

