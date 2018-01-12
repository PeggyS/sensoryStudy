function sensory_clinical_compare_pre_stats(varargin)
%SENSORY_CLINICAL_COMPARE_PRE_STATS - compute comparison stats on the PRE data in the clinical_data_taller_difference_variables file
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
measure_list =  {'x2pt_dig4' ...
	'dome_dig2_thresh' ...
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
    'x2pt_dig2' };

for m_cnt = 1:length(measure_list);
	measure = measure_list{m_cnt};
	
	tbl_meas = tbl(strcmp(tbl.Measure, measure),:);
	
	% with & without glove
	g_list = { '_g', '' };
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
			sham_var = ['Hs' g_str '_pre_' i_str];
			hi_var = ['Ha' g_str '_pre_' i_str];
			lo_var = ['L' g_str '_pre_' i_str];
			
			sham_data = tbl_meas.(sham_var);
			hi_data = tbl_meas.(hi_var);
			lo_data = tbl_meas.(lo_var);
			% compare all 3
			kw_n = sum(~isnan(sham_data) & ~isnan(hi_data) & ~isnan(lo_data));
			if kw_n > 1
% 				kw_p = kruskalwallis([sham_data, hi_data, lo_data],'', 'off');
				data_mat = [sham_data, hi_data, lo_data];
				msk = ~any(isnan(data_mat),2);
				data_mat = data_mat(msk, :);
				tbl = table(tbl_meas.Subj,sham_data,hi_data,lo_data,'VariableNames',{'Subj','sh', 'hi','lo'});
				tp=table([1 2 3]','VariableNames',{'timepoints'});
				
				tbl = tbl(msk,:);
% 				rm = fitrm(tbl,'sh-hi-lo~Subj','WithinDesign',tp)
				
				kw_p = friedman(data_mat, 1, 'off');
				if kw_p < 0.05
% 					[p,anovatab,stats] = kruskalwallis([sham_data, hi_data, lo_data],{'sham', 'hi', 'lo'}, 'on');
					[p,anovatab,stats] = friedman(data_mat, 1, 'on');
					multcompare(stats);
					ylabel([strrep(measure, '_', ' ')  ' ' i_str ' ' tbl_gstr])
					disp([measure ' ' i_str ' ' tbl_gstr])
					disp(['sham median = ' num2str(median(sham_data, 'omitnan'))])
					disp(['hi median = ' num2str(median(hi_data, 'omitnan'))])
					disp(['lo median = ' num2str(median(lo_data, 'omitnan'))])
				end
			else
				kw_p = nan;
			end
			
			
			% add info to the output table
			tmp_tbl = table({measure},  {tbl_gstr}, {i_str}, kw_n, kw_p, ...
				'VariableNames', {'measure', 'glove', 'side', 'friedman_n', 'friedman_p'});
			if isempty(out_tbl)
				out_tbl = tmp_tbl;
			else
				out_tbl = vertcat(out_tbl, tmp_tbl);
			end
			
		end % inv or un
	end % w/ & w/o glove
	
end % measure

% request where to save 
[fName, pathName] = getsavenames(fullfile(pwd, 'pre_comparison_stats.xlsx'), 'Save as');
if isequal(fName, 0) || isequal(pathName, 0),
	disp('Not saving. User canceled.');
	return;
end

writetable(out_tbl, fullfile(pathName,fName))

