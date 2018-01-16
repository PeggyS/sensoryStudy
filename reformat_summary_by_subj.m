function reformat_summary_by_subj(varargin)

% define input parser
p = inputParser;
p.addParameter('file', 'none', @isstr);
p.addParameter('measure',{'x2pt_dig2', 'x2pt_dig4', ...
	'monofil_dig2_local' 'monofil_dig4_local', ...
	'proprioception_index_pct', ...
	'vibr_dig2_avg' }, @iscell);
p.addParameter('arm', {'un', 'inv'}, @iscell);

% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none')		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.xlsx', 'Pick summary_by_subj.csv file');
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
out_tbl.subj = tbl.subj;

arm_list = {'inv', 'un'};

% each measure
for m_cnt = 1:length(inputs.measure)
	measure = inputs.measure{m_cnt};
	
	for a_cnt = 1:length(arm_list)
		arm = arm_list{a_cnt};
		
		mean_vname = [measure '_' arm '_mean'];
		std_vname = [measure '_' arm '_std'];
		out_vname = strcat(mean_vname, '_sd');
		
		out_col = arrayfun(@(x,y)format_mean_sd_parens(x,y), tbl.(mean_vname), tbl.(std_vname), 'UniformOutput', false);
		out_tbl.(out_vname) = out_col;
		
		n_vname = [measure '_' arm '_n'];
		out_tbl.(n_vname) = tbl.(n_vname);
	end
end

writetable(out_tbl, strrep(inputs.file, '.csv', '_mean_sd_parens.csv'))
return

% ----------------------------------------------
function out_str = format_mean_sd_parens(mean_val, sd_val)
out_str = sprintf('%.1f (%.1f)', mean_val, sd_val);

return
