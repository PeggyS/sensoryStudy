function data_tbl = scatter_bar_plot2(varargin)
%SCATTER_BAR_PLOT2 - plot of the data in sep_data_format_pre_post_diff.xlsx
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
p.addParameter('pre_post', {'d_post1','d_post2'}, @iscell);
p.addParameter('cohort',{'whole', '6sess'}, @iscell);
p.addParameter('glove',{'+g','-g','+/-g'}, @iscell);

% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none')		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.xlsx', 'Pick .xlsx file with measures as columns');
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


if ~isempty(inputs.exclude)
	for s_cnt = 1:length(inputs.exclude)
		tbl = tbl(~strcmp(tbl.Subj, inputs.exclude{s_cnt}), :);
	end
end

sess_list = {'Hs', 'Ha', 'L', 'Hs-g', 'Ha-g', 'L-g'};
post_list = inputs.post;
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
				
				% join session data into a single table
				if sess_cnt == 1
					sess_tbl = data;
					sess_tbl.Properties.VariableNames = strrep(sess_tbl.Properties.VariableNames, post_var_str, strrep(sess,'-', '_'));
				else
					sess_tbl = outerjoin(sess_tbl, data, 'Key','Subj','MergeKeys',true);
					sess_tbl.Properties.VariableNames = strrep(sess_tbl.Properties.VariableNames, post_var_str, strrep(sess,'-', '_'));
				end
			end
			
			for co_cnt = 1:length(inputs.cohort)
				cohort_str = inputs.cohort{co_cnt};
				
				switch cohort_str
					case 'whole'
						cohort_tbl = sess_tbl;
					case '6sess'
						% subjects with Hs-g data
						cohort_tbl = sess_tbl(~isnan(sess_tbl.Hs_g),:);
					otherwise
						error('unkown cohort: %s', cohort_str)
				end
			
				for g_cnt = 1:length(inputs.glove)
					g_str = inputs.glove{g_cnt};
					switch g_str
						case '+g'
							data_tbl = cohort_tbl(:,{'Subj', 'Hs', 'Ha', 'L'});
						case '-g'
							data_tbl = cohort_tbl(:,{'Subj', 'Hs_g', 'Ha_g', 'L_g'});
						case '+/-g'
							data_tbl = cohort_tbl;
						otherwise
							error('unkown glove parameter: %s', g_str)
					end
					h_fig = figure;
					h = datacursormode(h_fig);
					set(h,'UpdateFcn',@myupdatefcn,'SnapToDataVertex','on');
					datacursormode on
					scatter_bar(data_tbl)
					set(gca, 'FontSize',14, 'FontWeight', 'normal', 'LineWidth',2);
					ylabel( strrep(post_var_str, '_', '\_ '), 'FontWeight', 'normal')
					title([strrep(measure,'_', '\_') ', ' i_str ', ' cohort_str ', ' g_str])
				end % glove
			end % cohort
		end % inv or un
	end % post
end % measure



return

function scatter_bar(tbl)

sess_List = tbl.Properties.VariableNames(2:end);
offset_incr = 1/10;

% each session is a different x value
for sessInd = 1:length(sess_List)
	[uniq_vals, tbl_ind, uniq_ind] = unique(tbl.(sess_List{sessInd}));
 	uniq_vals(isnan(uniq_vals))=[]; % remove nans

	counts = hist(tbl.(sess_List{sessInd}), uniq_vals);
	
	n(sessInd) = sum(counts); % total number of points/subjects
	
	% max offsets for determinining width of mean line
	max_r_offset = 0;
	max_l_offset = 0;
	
	for ii = 1:length(uniq_vals)
		if counts(ii) > 0 && ~isnan(uniq_vals(ii))
			% there's at least 1 point to plot
			
			% find the subjs
			subj_ind = find(tbl.(sess_List{sessInd}) == uniq_vals(ii));
			assert(length(subj_ind) == counts(ii), 'did not find %d subjects with uniq_val=%f',counts(ii), uniq_vals(ii))
			
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
				line(sessInd+offset, uniq_vals(ii), 'Marker', 'o', 'MarkerFaceColor', 'b', ...
					'MarkerSize', 10, 'UserData', tbl.Subj(subj_ind(jj)));
			end
		end
	end
end
set(gca, 'XTick', 1:length(sess_List), 'XTickLabel', strrep(sess_List, '_', '-'))
return

function [txt] = myupdatefcn(obj,event_obj)
% Display 'Time' and 'Amplitude'
pos = get(event_obj,'Position');
hLine = get(event_obj, 'Target');
xdata = get(hLine, 'XData');
ydata = get(hLine, 'YData');
labeldata = get(hLine, 'UserData');
a=find(abs(xdata-pos(1))< eps & abs(ydata-pos(2))< eps);

txt = {char(labeldata),	['Y: ',num2str(pos(2))]};
return