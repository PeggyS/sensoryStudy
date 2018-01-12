function sensory_clinical_compare_stats(varargin)
%SENSORY_CLINICAL_COMPARE_STATS - compute comparison stats on the data in the clinical_data_taller_difference_variables file
%
% input parameter-value pairs:
%	file - filename
%	exclude = cell array of strings of subjects to exclude (e.g. {'s2608sens', s2616sens'}

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
out_tbl = table();


if ~isempty(inputs.exclude)
	for s_cnt = 1:length(inputs.exclude)
		tbl = tbl(~strcmp(tbl.Subj, inputs.exclude{s_cnt}), :);
	end
end

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
				
				% sham
				sham_var = ['d_Hs' g_str '_' p_str '_' i_str];
				hi_var = ['d_Ha' g_str '_' p_str '_' i_str];
				lo_var = ['d_L' g_str '_' p_str '_' i_str];
				
				sham_data = tbl_meas.(sham_var);
				hi_data = tbl_meas.(hi_var);
				lo_data = tbl_meas.(lo_var);
				% compare all 3
				kw_n = sum(~isnan(sham_data) & ~isnan(hi_data) & ~isnan(lo_data));
				if kw_n > 1 	
% 					kw_p = kruskalwallis([sham_data, hi_data, lo_data],'', 'off');
					data_mat = [sham_data, hi_data, lo_data];
					data_mat = data_mat(~any(isnan(data_mat),2), :);
					kw_p = friedman(data_mat,1, 'off');
					if kw_p < 0.05
% 						[p,anovatab,stats] = kruskalwallis([sham_data, hi_data, lo_data],{'sham', 'hi', 'lo'}, 'on');
					[p,anovatab,stats] = friedman(data_mat,1, 'on');
						multcompare(stats);
						ylabel([measure ' ' i_str])
					end
				else
					kw_p = nan;
				end
				
				% compare sham to the others
				hi_n = sum(~isnan(sham_data) & ~isnan(hi_data));
				if hi_n
					hi_p = signrank(sham_data, hi_data);
				else
					hi_p = nan;
				end
				lo_n = sum(~isnan(sham_data) & ~isnan(lo_data));
				if lo_n
					lo_p = signrank(sham_data, lo_data);
				else
					lo_p = nan;
				end
				
				% add info to the output table
				tmp_tbl = table({measure}, {[p_str '-pre']}, {tbl_gstr}, {i_str}, kw_n, kw_p, hi_n, hi_p, lo_n, lo_p, ...
					'VariableNames', {'measure', 'post', 'glove', 'side', 'kw_n', 'kw_p', ...
					'Hs_v_Ha_n', 'Hs_v_Ha_p', 'Hs_v_L_n', 'Hs_v_L_p'});
				if isempty(out_tbl)
					out_tbl = tmp_tbl;
				else
					out_tbl = vertcat(out_tbl, tmp_tbl);
				end
				
			end % inv or un
		end % w/ & w/o glove
	end % post1, post2
end % measure

% request where to save 
[fName, pathName] = getsavenames(fullfile(pwd, 'comparison_stats.xlsx'), 'Save as');
if isequal(fName, 0) || isequal(pathName, 0),
	disp('Not saving. User canceled.');
	return;
end

writetable(out_tbl, fullfile(pathName,fName))

