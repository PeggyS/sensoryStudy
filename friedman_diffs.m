function friedman_diffs(varargin)
% friedman_DIFFS - friedman test between  difference variables sham(Hs) vs L vs Ha
%
% Takes the clincal data spreadsheet in taller with differnces format. 
%
% inputs in the form of parameter-value pairs:
%	'file'-'c:\path\to\filename.txt' - optional - string with the full file and pathname to the 
%		clinical measures tab delimited text file. If it
%		is not specified, then the user will be asked to identify the file
%		in a dialog box.
% 
%


% define input parser
p = inputParser;
p.addParamValue('file', 'none', @isstr);

% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none'),		% no file specified
	% request the data file
	disp('Pick clinical measures TALLER tab delimited file')
	[fname, pathname] = uigetfile('*.txt', 'Pick clinical measures tab delimited file');
	if isequal(fname,0) || isequal(pathname,0)
		disp('User canceled. Exitting')
		return
	else
		filePathName = fullfile(pathname,fname);
	end
else
	filePathName = inputs.file;
end

tbl = readtable(filePathName, 'Delimiter', '\t');

% measure_list = unique(tbl.Measure);
measure_list = {'x2pt_dig2', 'x2pt_dig4',  'monofil_dig4_local',  'vibr_elbw_avg', ...
 	'stkch', 'smobj'};
tbl.Measure = nominal(tbl.Measure);

out_tbl = table();
row = table();
% each measure
for meas_cnt = 1:length(measure_list),
	measure = measure_list{meas_cnt};
	disp(['----- ' measure ' -------'])
	
	post_list = {'post1', 'post2'};
	for pp = 1:length(post_list),
		post_str = post_list{pp};
		
		inv_un_list = {'inv', 'un'};
		for uu = 1:length(inv_un_list),
			inv_str = inv_un_list{uu};
			
			% data for the measure - EXCLUDING s2613sens - incomplete data
			data = tbl(tbl.Measure==measure & ~strcmp(tbl.Subj,'s2613sens'), :); 
			
			perif_list = {'', 'g_'};
			for ss = 1:length(perif_list),
				perif = perif_list{ss};
				
				sham_var = ['d_Hs_' perif post_str '_' inv_str];
				high_var = ['d_Ha_' perif post_str '_' inv_str];
				low_var = ['d_L_' perif post_str '_' inv_str];
				
				cnt = sum(~isnan(data.(sham_var))&~isnan(data.(high_var)));
				if cnt > 0
					% remove rows of data with NaN
					data_mat = [data.(sham_var) data.(high_var) data.(low_var)];
					data_mat = data_mat(~any(isnan(data_mat),2), :);
					
					% compare
					if size(data_mat,1) > 1,
						[p,stat_tbl,stats] = friedman(data_mat, ...
							1, 'off');
						disp([sham_var ' vs ' high_var  ' vs ' low_var ' p = ' num2str(p) ])
						row.measure = {measure};
						row.comparison = {[sham_var ' vs ' high_var ' vs ' low_var]};
						row.p = p;
						if p < 0.05
							figure
							multcompare(stats)
							keyboard
						end

						if isempty(out_tbl),
							out_tbl = row;
						else
							out_tbl = vertcat(out_tbl, row);
						end
					end
				end
				

			end % session
			
		end % inv
	end % post
	% sham 
end

% save
[filename, pathname] = uiputfile('*.txt', 'Save output stats table as', 'friedman_stats_table.txt');
if isequal(filename,0) || isequal(pathname,0)
	   disp('User pressed cancel')
	   return
end
	
file_name = fullfile(pathname, filename);
disp(['Saving ', file_name])
writetable(out_tbl, file_name, 'Delimiter', '\t')

