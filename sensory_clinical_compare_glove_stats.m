function sensory_clinical_compare_glove_stats(varargin)
%SENSORY_CLINICAL_COMPARE_GLOVE_STATS - compute comparison stats on the data in the clinical_data_taller_difference_variables file
%
% input parameter-value pairs:
%	file - filename

% define input parser
p = inputParser;
p.addParameter('file', 'none', @isstr);
p.addParameter('exclude', {}, @iscell);

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

% exclude subjects 
if ~isempty(inputs.exclude)
	for s_cnt = 1:length(inputs.exclude)
		tbl = tbl(~strcmp(tbl.Subj, inputs.exclude{s_cnt}), :);
	end
end

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
			kw_n = sum(~isnan(sham_data) & ~isnan(hi_data) & ~isnan(lo_data) ...
				& ~isnan(sham_no_g_data) & ~isnan(hi_no_g_data) & ~isnan(lo_no_g_data));
			if kw_n
				kw_p = kruskalwallis([sham_data, hi_data, lo_data, sham_no_g_data, hi_no_g_data, lo_no_g_data], ...
					'', 'off');
				if kw_p < 0.05
					[p,anovatab,stats] = kruskalwallis([sham_data, hi_data, lo_data,sham_no_g_data, hi_no_g_data, lo_no_g_data], ...
						{'sham+g', 'hi+g', 'lo+g','sham-g', 'hi-g', 'lo-g'}, 'on');
					multcompare(stats);
					ylabel([ strrep(measure,'_',' ') ' ' i_str])
				end
			else
				kw_p = nan;
			end
			
			% compare all 3 with & 3 without
			data_mat =  [sham_data, hi_data, lo_data];
			data_mat = data_mat(~any(isnan(data_mat),2), :); % remove rows with nans
			fr_with_n = size(data_mat,1);
			if fr_with_n > 1
				fr_with_p = friedman(data_mat, 1, 'off');
				if fr_with_p < 0.05
					[p,anovatab,stats] = friedman(data_mat, 1, 'on');
					figure
					multcompare(stats);
					ylabel(['with glove - ' strrep(measure,'_',' ') ' ' i_str])
				end
			else
				fr_with_p = nan;
			end
			
			data_mat =  [sham_no_g_data, hi_no_g_data, lo_no_g_data];
			data_mat = data_mat(~any(isnan(data_mat),2), :); % remove rows with nans
			fr_without_n = size(data_mat,1);
			if fr_without_n > 1
				fr_without_p = friedman(data_mat, 1, 'off');
				if fr_without_p < 0.05
					[p,anovatab,stats] = friedman(data_mat, 1, 'on');
					figure
					multcompare(stats);
					ylabel(['without glove - ' strrep(measure,'_',' ') ' ' i_str])
				end
			else
				fr_without_p = nan;
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
					disp(['Ha-Hs with vs without glove - ' measure, ' ' p_str ' ' i_str ' p=' ...
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
			tmp_tbl = table({measure}, {[p_str '-pre']}, {i_str}, kw_n, kw_p, fr_with_n, fr_with_p, ...
				fr_without_n, fr_without_p,  sham_n, sham_p, hi_n, hi_p, lo_n, lo_p, ...
				hi_minus_sham_n, hi_minus_sham_p, lo_minus_sham_n, lo_minus_sham_p, ...
				'VariableNames', {'measure', 'post', 'side', 'kw_6way_n', 'kw_6way_p', 'fr_with_g_n', 'fr_with_g_p', ...
				'fr_without_g_n', 'fr_without_g_p',  ...
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

