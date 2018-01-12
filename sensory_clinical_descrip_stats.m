function sensory_clinical_descrip_stats(varargin)
%SENSORY_CLINICAL_DESCRIP_STATS - compute descriptive stats on the data in the clinical_data_taller_difference_variables file
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

for m_cnt = 1:length(measure_list);
	measure = measure_list{m_cnt};
	tbl_meas = tbl(strcmp(tbl.Measure, measure),:);
	
	% post1 & post2
	p_list = {'post1', 'post2'};
	for p_cnt = 1:length(p_list)
		p_str = p_list{p_cnt};
		% with & without glove
		g_list = { '', '_g'};
		for g_cnt = 1:length(g_list)
			g_str = g_list{g_cnt};
			if strcmp(g_str,'')
				tbl_gstr = ' +g';
			else
				tbl_gstr = ' -g';
			end
			
			% inv & uninv
			inv_list = {'inv', 'un'};
			for i_cnt = 1:length(inv_list)
				i_str = inv_list{i_cnt};
				
				% sham, hi, low
				sess_list = {'Hs', 'Ha', 'L'};
				for s_cnt = 1:length(sess_list);
					sess = sess_list{s_cnt};
					
					% define the column in the table
					var_name = ['d_' sess g_str '_' p_str '_' i_str];
					
					data = tbl_meas.(var_name);
					
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
								min_data, max_data, sw_h, sw_p, ...
								lillie_h, lillie_p, ...
						'VariableNames', {'measure', 'post', 'glove', 'side', 'session', ...
						'N', 'mean', 'std_dev', 'std_err', 'median', 'quartile_25', 'quartile_75', 'min', 'max', ...
						'lillie_h', 'lillie_p', 'sw_h', 'sw_p'});
					if isempty(out_tbl)
						out_tbl = tmp_tbl;
					else
						out_tbl = vertcat(out_tbl, tmp_tbl);
					end
					
				end % session
			end % inv or un
		end % w/ & w/o glove
	end % post
end % measure

% request where to save 
[fName, pathName] = getsavenames(fullfile(pwd, 'descriptive_stats.xlsx'), 'Save as');
if isequal(fName, 0) || isequal(pathName, 0),
	disp('Not saving. User canceled.');
	return;
end

writetable(out_tbl, fullfile(pathName,fName))
