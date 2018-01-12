function  clinical_bar_chart(varargin)

% input parameter-value pairs:
%	file - filename
%	exclude = cell array of strings of subjects to exclude (e.g. {'s2608sens', s2616sens'}

% define input parser
p = inputParser;
p.addParameter('file', 'Sensory_rTMS_ClinicalData_20170710_taller_difference_variables.xlsx', @isstr);
p.addParameter('exclude', {}, @iscell);
p.addParameter('measures',{'x2pt_dig4' });
p.addParameter('arm', {'inv'}, @iscell);



close_fraction = 0.8; % for bar chart 1.0 = touching
bar_colors = {[0.3 0.3 0.3], [0.8 0.8 0.8]};
axes_fontsize = 18;
axes_linewidth = 3;
axes_position = [0.29 0.27 0.5 0.55];

error_linewidth = 1;

group_label_fontsize = 36;
left_y_lims = [-0.19 0.19];
left_y_ticks = [-0.1: 0.1 : 0.1];
group_label_y_pos = -2;
right_y_lims = [-1.75 1.75];
right_y_ticks = -1:1;

font_name = 'Arial';
label_font_size = 25;
title_font_size = 30;



% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none')		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.xlsx', 'Sensory_rTMS_ClinicalData_20170710_taller_difference_variables.xlsx file');
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
tbl.measure = nominal(tbl.Measure);

if ~isempty(inputs.exclude)
	for s_cnt = 1:length(inputs.exclude)
		tbl = tbl(~strcmp(tbl.Subj, inputs.exclude{s_cnt}), :);
	end
end


inv_list = inputs.arm;

glove_list = {'', '_g'};

% inv & uninv
for i_cnt = 1:length(inv_list)
	i_str = inv_list{i_cnt};
	
	for g_cnt = 1:length(glove_list)
		g_str = glove_list{g_cnt};
		
		% each measure
		for m_cnt = 1:length(inputs.measures)
			measure = inputs.measures{m_cnt};
			
			% data for each bar
			hs_pst1 = table2array(tbl(tbl.measure==measure, ['d_Hs' g_str '_post1_' i_str ]));
			hs_pst2 = table2array(tbl(tbl.measure==measure, ['d_Hs' g_str '_post2_' i_str ]));
			ha_pst1 = table2array(tbl(tbl.measure==measure, ['d_Ha' g_str '_post1_' i_str ]));
			ha_pst2 = table2array(tbl(tbl.measure==measure, ['d_Ha' g_str '_post2_' i_str ]));
			l_pst1 = table2array(tbl(tbl.measure==measure, ['d_L' g_str '_post1_' i_str ]));
			l_pst2 = table2array(tbl(tbl.measure==measure, ['d_L' g_str '_post2_' i_str ]));
			
			mean_bar_values = [nanmean(hs_pst1) nanmean(l_pst1) nanmean(ha_pst1); ...
				nanmean(hs_pst2) nanmean(l_pst2) nanmean(ha_pst2)];
			std_values = [nanstd(hs_pst1) nanstd(l_pst1) nanstd(ha_pst1); ...
				nanstd(hs_pst2) nanstd(l_pst2) nanstd(ha_pst2)];
			
			disp([measure g_str ': N=' num2str(sum(~isnan(hs_pst1))) ', ' num2str(sum(~isnan(hs_pst2)))  ', ' ...
				num2str(sum(~isnan(ha_pst1))) ', ' num2str(sum(~isnan(ha_pst2))) ', '...
				num2str(sum(~isnan(l_pst1))) ', ' num2str(sum(~isnan(l_pst2))) ', '	])
			
			hf = figure;
			hb = close_bar(1:3,mean_bar_values', close_fraction, bar_colors, axes_linewidth);
			set(gca, 'Fontsize', axes_fontsize, 'Position', axes_position, ...
				'Box', 'off', 'FontWeight', 'bold', 'LineWidth', axes_linewidth, 'FontName', font_name)
			hold on
			add_error_bars(hb, mean_bar_values, std_values, error_linewidth)
			
			set(gca, 'XTick', 1:3, 'XTickLabel', {'S' 'L' 'H'})
			ylabel('Change post-pre', 'FontSize', label_font_size)
			xlabel('rTMS Type', 'FontSize', label_font_size)
			title({[strrep(strrep(measure, 'x', ' '), '_', ' ') strrep(g_str,'_',' without ') ' ' i_str]; ' '}, 'FontSize', title_font_size)
% 			legend('post1','post2')
			
			ud.savefigname = [measure strrep(g_str,'_','_without_') '_' i_str];
			set(hf, 'UserData', ud)
			
		end % measure
	end
end % inv or un


return

function add_error_bars(hb, mean_bar_values, std_values, errorbar_linewidth)
% For each set of bars, find the centers of the bars, and write error bars
for ib = 1:numel(hb)
      % Find the centers of the bars
	  barCenters = hb(ib).XData+hb(ib).XOffset;

      herr = errorbar(barCenters,mean_bar_values(ib,:),std_values(ib,:),'k.');
      set(herr, 'LineWidth', errorbar_linewidth)
end

return


function hb = close_bar(x, bar_vals, gw, clrs, axes_linewidth)
hb(1) = bar(x-gw/4,bar_vals(:,1),gw/2) ;
set(hb(1), 'LineWidth', axes_linewidth, 'FaceColor', clrs{1})
hb(1).BaseLine.LineWidth = axes_linewidth;
hold on ;
hb(2) = bar(x+gw/4,bar_vals(:,2),gw/2, 'FaceColor', clrs{2}) ;
set(hb(2), 'LineWidth', axes_linewidth)
hold off ;
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
