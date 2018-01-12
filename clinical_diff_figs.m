function descrip_stat_tbl = clinical_diff_figs(varargin)
%CLINICAL_FIGS - data in the clinical_data_taller diffs file
%
% input parameter-value pairs:
%	file - filename

% define input parser
p = inputParser;
p.addParameter('file', 'none', @isstr);
p.addParameter('exclude', {}, @iscell);
p.addParameter('measure', {'vibr_elbw_avg'}, @iscell);
p.addParameter('post', {'post1', 'post2'}, @iscell);
p.addParameter('arm', {'inv', 'un'}, @iscell);
p.addParameter('glove', {'with', 'without'}, @iscell);
p.addParameter('cohort', {'6session', 'whole'}, @iscell);



% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none'),		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.txt', 'Pick clinical measures TALL file');
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

measure_list =  inputs.measure;
descrip_stat_tbl = table();

for m_cnt = 1:length(measure_list);
	measure = measure_list{m_cnt};
	
	tbl_meas = tbl(strcmp(tbl.Measure, measure),:);
	
	% post1 & post2
	p_list = inputs.post;
	for p_cnt = 1:length(p_list)
		p_str = p_list{p_cnt};
		
		
		% inv & uninv
		inv_list = inputs.arm;
		for i_cnt = 1:length(inv_list)
			i_str = inv_list{i_cnt};
			
			% with & without glove
			g_list = inputs.glove;
			for g_cnt = 1:length(g_list)
				if strcmp(g_list{g_cnt},'with')
					tbl_gstr = ' +g';
					g_str = '';
				else
					tbl_gstr = ' -g';
					g_str = '_g';
				end
			
			% sham, hi, lo 
			sham_var = ['d_Hs' g_str '_' p_str '_' i_str];
			hi_var = ['d_Ha' g_str '_' p_str '_' i_str];
			lo_var = ['d_L' g_str '_' p_str '_' i_str];
			
			% cohorts
			cohort_list = inputs.cohort;
			for c_cnt = 1:length(cohort_list)
					sham_data = tbl_meas.(sham_var);
					hi_data = tbl_meas.(hi_var);
					lo_data = tbl_meas.(lo_var);
					subj_data = tbl_meas.Subj;

				if strcmp(cohort_list{c_cnt}, '6session')
					sham_no_g_var = ['d_Hs_g_' p_str '_' i_str];
					sham_no_g_data = tbl_meas.(sham_no_g_var);
					
					sham_data = sham_data(~isnan(sham_no_g_data));
					hi_data = hi_data(~isnan(sham_no_g_data));
					lo_data = lo_data(~isnan(sham_no_g_data));
				end


					% friedman comparison
					data_mat = [sham_data, hi_data, lo_data];
					data_mat = data_mat(~any(isnan(data_mat),2), :);
					subj_data = subj_data(~any(isnan(data_mat),2), :);
					fr_n = size(data_mat,1);		
					if fr_n > 1
						fr_p = friedman(data_mat, 1, 'off');
						if fr_p < 0.05
							[p,anovatab,stats] = friedman(data_mat, 1, 'on');
							disp(['fr '  strrep(measure,'_',' ') ' ' g_list{g_cnt} ' glove - '  i_str ' ' p_str ' ' cohort_list{c_cnt} ' cohort'])
							disp(['p = ' num2str(p)])
							figure
							comp = multcompare(stats)
							ylabel([strrep(measure,'_',' ') ' ' g_list{g_cnt} ' glove '  i_str ' ' p_str ' ' cohort_list{c_cnt} ' cohort'])
						end
					else 
						fr_p = nan;
					end

					% scatterplot
					scatter_bar(data_mat, {sham_var hi_var lo_var}, measure, subj_data);

					% descriptive stats
					descrip_stat_tbl = descrip_stats(data_mat(:,1), descrip_stat_tbl, measure, p_str, tbl_gstr, i_str, 'Hs');
					descrip_stat_tbl = descrip_stats(data_mat(:,2), descrip_stat_tbl, measure, p_str, tbl_gstr, i_str, 'Ha');
					descrip_stat_tbl = descrip_stats(data_mat(:,3), descrip_stat_tbl, measure, p_str, tbl_gstr, i_str, 'L');
					
			
			end % cohort
			end % + or - glove
		end % arm
	end % post1 or post2
end % measure

function out_tbl = 	descrip_stats(data, in_tbl, measure, p_str, tbl_gstr, i_str, sess)

% descriptive stats
	cnt = sum(~isnan(data));
	mean_data = mean(data, 'omitnan');
	std_data = std(data, 'omitnan');
	serr = std_data / sqrt(cnt);
	median_data = median(data, 'omitnan');
	quantile_data = quantile(data ,[.25 .75]); % the quartiles of data
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
		[sw_h, sw_p] = swtest(data);
	else
		sw_h = nan; sw_p = nan;
	end
	% add info to the output table
	tmp_tbl = table({measure}, {[p_str '-pre']}, {tbl_gstr}, {i_str}, {sess}, ...
				cnt, mean_data, std_data, serr, median_data, quantile_data(1), quantile_data(2), ...
				min_data, max_data, lillie_h, lillie_p, sw_h, sw_p, ...
		'VariableNames', {'measure', 'post', 'glove', 'side', 'session', ...
		'N', 'mean', 'std_dev', 'std_err', 'median', 'quartile_25', 'quartile_75', 'min', 'max', 'lillie_h', 'lillie_p', 'sw_h', 'sw_p'});
	if isempty(in_tbl)
		out_tbl = tmp_tbl;
	else
		out_tbl = vertcat(in_tbl, tmp_tbl);
	end
	
return

function scatter_bar(data_mat, sess_List, measure, labeldata)

    h_fig = figure;
    h_ax = axes;
    offset_incr = 1/10;

	% each session is a different x value
	for sessInd = 1:length(sess_List)
		uniq_vals = unique(data_mat(:,sessInd));
		uniq_vals(isnan(uniq_vals))=[]; % remove nans
		counts = hist(data_mat(:,sessInd), uniq_vals);
		
		n(sessInd) = sum(counts); % total number of points/subjects
		
		% max offsets for determinining width of mean line
		max_r_offset = 0;
		max_l_offset = 0;
		
		label_cnt = 1;
		for ii = 1:length(uniq_vals)
			if counts(ii) > 0 && ~isnan(uniq_vals(ii))
				% there's at least 1 point to plot
				
				% offsets for additional points
				if rem(counts(ii),2) == 1, % odd number of points
					r_offset = 0;
					l_offset = -offset_incr;
				else % even number of points
					r_offset = offset_incr/2;
					l_offset = -offset_incr/2;
				end
				
				% plot each point
				for jj = 1:counts(ii),
					% plot a point - horizontal position depends on jj
					% jj = 1 is at the r_offset, 2 is l_offset, 3 r_offset, etc
					if rem(jj,2) == 1,  % odd jj
						offset = r_offset;
						if(r_offset > max_r_offset), max_r_offset = r_offset; end
						r_offset = r_offset + offset_incr;
					else % even jj
						offset = l_offset;
						if(l_offset < max_l_offset), max_l_offset = l_offset; end
						l_offset = l_offset - offset_incr;
					end
					h_line = line(sessInd+offset, uniq_vals(ii), 'Marker', 'o', 'MarkerFaceColor', 'b', ...
						'MarkerSize', 10);

				end
			end
		end
		
	
		hold on
		% plot a line at the mean value
		% 	   mean_val = nanmean(ds2pt.(sess_List{sessInd}));
		% 	   sd_val = nanstd(ds2pt.(sess_List{sessInd}));
		% 	   hl= line([sessInd+max_l_offset sessInd+max_r_offset], [mean_val mean_val], ...
		% 		   'LineWidth', 4, 'Color', [0.8 0 0.2]);
		% 	   uistack(hl, 'bottom')
		%errorbar(sessInd, mean_val, sd_val)
		
	end
	
	ylabel( 'Post-Pre Difference', 'FontSize', 14, 'FontWeight', 'normal')
	set(gca, 'XTick', 1:length(sess_List), 'XTickLabel', strrep(sess_List, '_', '\_'))
    str = char(measure);
    str = strrep(str, '_', ' ');
    title(str)
	set(gca, 'FontSize',14, 'FontWeight', 'normal', 'LineWidth',2);
	set(gcf,'PaperPosition', [1.24742 3 6 5])
return


