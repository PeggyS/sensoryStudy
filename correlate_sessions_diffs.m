function correlate_sesssions_diffs(varargin)
% correlate_sesssions_DIFFS - correlate between sham(Hs) vs L vs Ha for chosen diff measures
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
					% do not remove rows of data with NaN
					data_mat = [data.(sham_var) data.(high_var) data.(low_var)];
 					% data_mat = data_mat(~any(isnan(data_mat),2), :);
					
					% correlate
					if size(data_mat,1) > 1,
						[pearson_r, pearson_p] = corr(data_mat, 'type', 'Pearson', 'rows', 'pairwise' );
						[spearman_r, spearman_p] = corr(data_mat, 'type', 'Spearman', 'rows', 'pairwise' );
						row.measure = {measure};
						row.correlation = {sham_var ' ~ ' high_var};
						row.pearson_r = pearson_r(1,2);
						row.pearson_p = pearson_p(1,2);
						row.spearman_r = spearman_r(1,2);
						row.spearman_p = spearman_p(1,2);

						if isempty(out_tbl),
							out_tbl = row;
						else
							out_tbl = vertcat(out_tbl, row);
						end
						
						row.correlation = {sham_var ' ~ ' low_var};
						row.pearson_r = pearson_r(1,3);
						row.pearson_p = pearson_p(1,3);
						row.spearman_r = spearman_r(1,3);
						row.spearman_p = spearman_p(1,3);
					
						out_tbl = vertcat(out_tbl, row);
						
						row.correlation = {high_var ' ~ ' low_var};
						row.pearson_r = pearson_r(2,3);
						row.pearson_p = pearson_p(2,3);
						row.spearman_r = spearman_r(2,3);
						row.spearman_p = spearman_p(2,3);
					
						out_tbl = vertcat(out_tbl, row);
					
						
					end
				end
				

			end % session
			
		end % inv
	end % post
	% sham 
end

% save
[filename, pathname] = uiputfile('*.txt', 'Save output stats table as', 'correlate_sessions_table.txt');
if isequal(filename,0) || isequal(pathname,0)
	   disp('User pressed cancel')
	   return
end
	
file_name = fullfile(pathname, filename);
disp(['Saving ', file_name])
writetable(out_tbl, file_name, 'Delimiter', '\t')

