function sep_format_avg_data(varargin)
%SEP_FORMAT_AVG_DATA - read data from sep_data.xlsx and reformat the trAvg (or _avg for 'M' subjects)
%

% input parameter-value pairs:
%	file - filename

% define input parser
p = inputParser;
p.addParameter('file', 'none', @isstr);
p.addParameter('exclude', {}, @iscell);
p.addParameter('group_glove',0,@islogical); % if true, then relabel subjs M01-s2610 3 sessions 4-6
% so that all without glove sessions are 1-3 and with glove sessions are 4-6
sess_label_list = [4 5 6 1 2 3];

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

out_tbl = table();

tbl.Subj = nominal(tbl.Subj);
tbl.SessType = nominal(tbl.SessType);
subj_list = unique(tbl.Subj);
tbl.datenum = tbl.Date+696884;	% excel date numbers start in 1900 or 1904, this number converts excel datenum to a matlab datenum
% to see the actual date, use datestr(tbl.datenum)


% don't use sessions other than Hs, Hs, & L
tbl = tbl(tbl.SessType=='Hs' | tbl.SessType=='Ha' | tbl.SessType=='L' ...
	| tbl.SessType=='Hs-g' | tbl.SessType=='Ha-g' | tbl.SessType=='L-g',: );


var_list = {'N20Cc', 'P25Cc', 'N33Cc', 'P45Cc', 'N60Cc' ,'P100Cc', 'N120Cc', ...};
	'N20Cc_P25Cc', 'P25Cc_N33Cc', 'N33Cc_P45Cc', 'P45Cc_N60Cc', 'N60Cc_P100Cc', 'P100Cc_N120Cc'};
arm_list = {'inv', 'un'};

for s_cnt = 1:length(subj_list)
	subj = subj_list(s_cnt);
	
	subj_tbl = tbl(tbl.Subj==subj,:);
	
	% verify datenum is in order
	assert(min(diff(subj_tbl.datenum)) > 0, 'subj %s not in session order', subj)
	
	sess_list = unique(subj_tbl.SessType, 'stable');
	for sess_cnt = 1:length(sess_list)
		if inputs.group_glove
			if subj=='M01' || subj=='M06' || subj=='M07' || subj=='M10' || ...
				subj=='s2601sens' || subj=='s2604sens' || subj=='s2608sens' || subj=='s2609sens' || subj=='s2610sens' 
				sess_cnt_label = sess_label_list(sess_cnt);
			else
				sess_cnt_label = sess_cnt;
			end
		else
			sess_cnt_label = sess_cnt;
		end
		
		for arm_cnt = 1:length(arm_list),
			arm = arm_list{arm_cnt};
			
			for v_cnt = 1:length(var_list)
				var = var_list{v_cnt};
				% pre
				pre_data = get_data(subj_tbl(sess_cnt,:), 'pre',  var, arm );
				% post1
				post1_data = get_data(subj_tbl(sess_cnt,:), 'post1',  var, arm );
				% post2
				post2_data = get_data(subj_tbl(sess_cnt,:), 'post2',  var, arm );

				% save the data
				tmp_tbl = table(subj, subj_tbl.Date(sess_cnt), subj_tbl.datenum(sess_cnt), {datestr(subj_tbl.datenum(sess_cnt))}, ...
					sess_cnt_label, subj_tbl.SessType(sess_cnt), {arm}, {var}, ...
					pre_data, post1_data, post2_data, post1_data-pre_data, post2_data-pre_data, ...
					'VariableNames', {'Subj', 'exeldatenum', 'datenum', 'datestr', 'session_num', 'SessType', 'arm', 'measure', ...
					'pre', 'post1', 'post2', 'post1_minus_pre', 'post2_minus_pre'});
				if isempty(out_tbl)
					out_tbl = tmp_tbl;
				else
					out_tbl = vertcat(out_tbl, tmp_tbl);
				end
		
			end % var
		end % arm
	end % session	
end % subject

% request where to save 
[fName, pathName] = uiputfile('sep_data_format_pre_post_diff.xlsx', 'Save as');
if isequal(fName, 0) || isequal(pathName, 0),
	disp('Not saving. User canceled.');
	return;
end
writetable(out_tbl, fullfile(pathName, fName));



function data = get_data(tbl, dc, var, arm)
suffix = '_trAvg';
if tbl.Subj(1)=='M01' || tbl.Subj(1)=='M06' || tbl.Subj(1)=='M07' || tbl.Subj(1)=='M10',
	suffix = '_avg';
end

col_str = [dc '_' arm '_' var  suffix];
data = table2array(tbl(:, {col_str}));

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
