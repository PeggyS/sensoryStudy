function sep_initial_check(varargin)
%SEP_INITIAL_CHECK - initial plots of sep_data to check for outliers
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
	[fname, pathname] = uigetfile('*.xlsx', 'Pick sep data .xlsx file');
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



tbl.Subj = nominal(tbl.Subj);
tbl.SessType = nominal(tbl.SessType);
subj_list = unique(tbl.Subj);

% don't use sessions other than Hs, Hs, & L
tbl = tbl(tbl.SessType=='Hs' | tbl.SessType=='Ha' | tbl.SessType=='L' ...
	| tbl.SessType=='Hs-g' | tbl.SessType=='Ha-g' | tbl.SessType=='L-g',: );


latency_vars = {'N20Cc', 'P25Cc', 'N33Cc', 'P45Cc', 'N60Cc' ,'P100Cc', 'N120Cc'};
p_p_vars = {'N20Cc_P25Cc', 'P25Cc_N33Cc', 'N33Cc_P45Cc', 'P45Cc_N60Cc', 'N60Cc_P100Cc', 'P100Cc_N120Cc'};

for s_cnt = 1:length(subj_list)
	subj = subj_list(s_cnt);
	
	figure('Position', [ 1000         176         696        1162]);
	subplot(4,1,1)
	% inv p_p
	title([char(subj) ' - Inv Peak to Peak'])
	data = get_data(tbl, subj, p_p_vars, 'inv_');
	plot_points(data)
	
	subplot(4,1,2)
	% inv latency
	title([' Inv Latencies'])
	data = get_data(tbl, subj, latency_vars, 'inv_');
	plot_points(data)
	
	subplot(4,1,3)
	% un p_p
	title(['Uninv Peak to Peak'])
	data = get_data(tbl, subj, p_p_vars, 'un_');
	plot_points(data)
	
	subplot(4,1,4)
	% un latency
	title(['Uninv Latencies'])
	data = get_data(tbl, subj, latency_vars, 'un_');
	plot_points(data)
	
	
end

function data = get_data(tbl, subj, p_p_vars, prefix)
suffix = '_trAvg';
if subj=='M01' || subj=='M06' || subj=='M07' || subj=='M10',
	suffix = '_avg';
end


vars = regexprep(p_p_vars, '(.*)', ['pre_' prefix '$1' suffix]);
data = tbl(tbl.Subj==subj,vars);
if any(table2array(data)==0), 
	if ~all(table2array(data)==0), 
		fprintf('zero data: subj=%s, post1, %s\n', char(subj), prefix)
	end
end
data.Properties.VariableNames = p_p_vars;


vars = regexprep(p_p_vars, '(.*)', ['post1_' prefix '$1' suffix]);
post_data = tbl(tbl.Subj==subj,vars);
if any(table2array(post_data)==0), 
	if ~all(table2array(data)==0),
		fprintf('zero data: subj=%s, post1, %s\n', char(subj), prefix)
	end
end
post_data.Properties.VariableNames = p_p_vars;
data = vertcat(data, post_data);

vars = regexprep(p_p_vars, '(.*)', ['post2_' prefix '$1' suffix]);
post_data = tbl(tbl.Subj==subj,vars);
if any(table2array(post_data)==0), 
	if ~all(table2array(data)==0),
		fprintf('zero data: subj=%s, post1, %s\n', char(subj), prefix)
	end
end
post_data.Properties.VariableNames = p_p_vars;
data = vertcat(data, post_data);

% if ~(height(data) == 9 && height(data) == 18) ,
% 	msg = sprintf('subj = %s, num points = %d', char(subj), height(data));
% 	disp(msg)
% end
return



function plot_points(data)
if(~isempty(data))
	for l_cnt = 1:height(data)
		x = 1:width(data);
		h_line = line(x, table2array(data(l_cnt,:)));
		set(h_line, 'LineStyle', 'none', 'Marker', 'o', 'MarkerSize', 10, 'Color', 'b')
	end
	xticklabs = strrep(data.Properties.VariableNames, '_', ' ');
	for lab_cnt = 1:length(xticklabs)
		col_data = table2array(data(:,lab_cnt));
		n = sum(~isnan(col_data));
		xticklabs{lab_cnt} = [xticklabs{lab_cnt} '\newlineN=' num2str(n)];
	end
	set(gca,'XTick', x, 'XTickLabel', xticklabs)
end
