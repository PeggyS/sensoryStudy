function scatter_bar(varargin)

% define input parser
p = inputParser;
p.addParamValue('file', 'none', @isstr);
p.addParamValue('measures', {}, @iscell);
p.addParamValue('subjects', {}, @iscell);
p.addParamValue('sessions', {'d_Hs_post2_inv' 'd_Ha_post2_inv' 'd_L_post2_inv'}, @iscell);

% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.file, 'none'),		% no file specified
	% request the data file
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


ds=dataset('file',filePathName);


ds.Subj = nominal(ds.Subj);
if isempty(inputs.subjects)	% do them all
	subj_list = unique(ds.Subj);
else
	subj_list = nominal(inputs.Subj);
end

ds.Measure = nominal(ds.Measure);
if isempty(inputs.measures)	% do them all
	meas_list = unique(ds.Measure);
else
	meas_list = nominal(inputs.measures);
end


sess_List = inputs.sessions;

% one figure for each measure
for mm = 1:length(meas_list),
    %ds2pt=ds(ds.Measure=='x2pt_dig4',:);
    ds2pt=ds(ds.Measure==meas_list(mm),:);

    figure
    axes
    offset_incr = 1/10;

	% each session is a different x value
	for sessInd = 1:length(sess_List)
		uniq_vals = unique(ds2pt.(sess_List{sessInd}));
		uniq_vals(isnan(uniq_vals))=[]; % remove nans
		counts = hist(ds2pt.(sess_List{sessInd}), uniq_vals);
		
		n(sessInd) = sum(counts); % total number of points/subjects
		
		% max offsets for determinining width of mean line
		max_r_offset = 0;
		max_l_offset = 0;
		
		for ii = 1:length(uniq_vals)
			if counts(ii) > 0 && ~isnan(uniq_vals(ii))
				% there's at least 1 point to plot
				
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
						'MarkerSize', 10);
				end
			end
		end
		
		
		hold on
		% plot a line at the mean value
		% 	   mean_val = nanmean(ds2pt.(sess_List{sessInd}));
		% 	   sd_val = nanstd(ds2pt.(sess_List{sessInd}));
		% 	   hl= line([sessInd+max_l_offset sessInd+max_r_offset], [mean_val mean_val], ...
		% 		   'LineWidth', 4, 'Color', [0.8 0 0.2]);
		% 	   uistack(hl, 'bottom')
		%errorbar(sessInd, mean_val, sd_val)
		
	end
	
	ylabel( 'Post-Pre Difference', 'FontSize', 14, 'FontWeight', 'normal')
	set(gca, 'XTick', 1:length(sess_List), 'XTickLabel', strrep(sess_List, '_', '\_'))
    str = char(meas_list(mm));
    str = strrep(str, '_', ' ');
    title(str)
	set(gca, 'FontSize',14, 'FontWeight', 'normal', 'LineWidth',2);
	set(gcf,'PaperPosition', [1.24742 3 6 5])
	
% 	if any(n~=n(1))
% 		keyboard
% 	end
end

% keyboard