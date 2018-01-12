function format_for_mix_model(varargin)



% define input parser
p = inputParser;
p.addParameter('in_file', 'none', @isstr);
p.addParameter('out_file', 'none', @isstr);
p.addParameter('measure', {'x2pt_dig2','x2pt_dig4','vibr_dig2_avg','vibr_elbw_avg', ...
	'proprioception_index_pct', 'proprioception_wrist_pct','monofil_dig2_local','monofil_dig4_local',...
	'dome_dig2_thresh', 'dome_dig4_thresh', 'stkch', 'smobj' }, @iscell);
p.addParameter('with_glove', true, @islogical);
p.addParameter('arm', 'inv', @isstr);

% parse the input
p.parse(varargin{:});
inputs = p.Results;
if strcmp(inputs.in_file, 'none')		% no file specified
	% request the data file
	[fname, pathname] = uigetfile('*.txt', 'Pick taller diff variable format tab delimited file');
	if isequal(fname,0) || isequal(pathname,0)
		disp('User canceled. Exitting')
		return
	else
		filePathName = fullfile(pathname,fname);
	end
else
	filePathName = inputs.in_file;
end


ds = dataset('file', filePathName);
ds.Measure = nominal(ds.Measure);

varNames = get(ds, 'VarNames');

% sess_match_cell = regexp(varNames, '(Hs_g)|(Ha_g)|(L_g)|(BL)|(Hs)|(Ha)|(L)', 'match');
% msk = ~cellfun('isempty',sess_match_cell);
% sess_cell_list = sess_match_cell(msk);
% sess_list = [sess_cell_list{:}];
% sess_types = unique(sess_list);

sess_types = { 'Hs' 'Ha' 'L' };

arm = inputs.arm;
if ~inputs.with_glove
	sess_types = strcat(sess_types, '_g'); % without glove sessions
end

pre_post_list = {'pre', 'post1', 'post2'};

out_ds = dataset();
for m_cnt = 1:length(inputs.measure)
	measure = inputs.measure{m_cnt}

	improved_is_lower = is_improved_lower(measure);
	measure_ds = dataset();
	
	for s_cnt = 1:length(sess_types)
		sess_str = sess_types{s_cnt};

		for p_cnt = 1:length(pre_post_list)
			p_str = pre_post_list{p_cnt};

			var_str = [sess_str '_' p_str '_' arm];
			p_ds = ds(ds.Measure==measure, {'Subj' var_str});
			p_ds = set(p_ds, 'VarNames', {'Subj', measure});
			p_ds.Treatment = repmat(new_sess_str(sess_str), size(p_ds,1), 1);
			p_ds.Pre_post = repmat({p_str}, size(p_ds,1), 1);
% 			p_ds.([measure '_improved']) = nan(size(p_ds,1), 1);
			
			if isempty(measure_ds)
				measure_ds = p_ds;
			else
				measure_ds = vertcat(measure_ds, p_ds);
			end
			
			if ~strcmp(p_str, 'pre')
				var_str = ['d_' sess_str '_' p_str '_' arm];
				p_ds = ds(ds.Measure==measure, {'Subj' var_str});
				p_ds = set(p_ds, 'VarNames', {'Subj', measure});
				p_ds.Treatment = repmat(new_sess_str(sess_str), size(p_ds,1), 1);
				p_ds.Pre_post = repmat({['d_' p_str]}, size(p_ds,1), 1);
				
				measure_ds = vertcat(measure_ds, p_ds);
				
				if improved_is_lower
					p_ds.Pre_post = repmat({['d_' p_str '_improved']}, size(p_ds,1), 1);
					p_ds.(measure) = p_ds.(measure) < 0;
				else
					p_ds.Pre_post = repmat({['d_' p_str '_improved']}, size(p_ds,1), 1);
					p_ds.(measure) = p_ds.(measure) > 0;
				end
				measure_ds = vertcat(measure_ds, p_ds);
			end
			
		end
		
		
% 		var_str = ['d_' sess_str '_post1_' arm];
% 		pst1_ds = ds(ds.Measure==measure, {'Subj' var_str});
% 		v_names = get(pst1_ds,'VarNames');
% 		new_v_name = ['delta_' measure '_post1'];
% 		v_names = strrep(v_names, var_str, new_v_name);
% 		pst1_ds = set(pst1_ds,'VarNames', v_names);
% 		imp_str = [measure '_impr_post1'];
% 		imp_abs_str = [measure '_abs_impr_post1'];
% 		if improved_is_lower
% 			pst1_ds.(imp_str) = pst1_ds.(new_v_name) < 0;
% 		else
% 			pst1_ds.(imp_str) = pst1_ds.(new_v_name) > 0;
% 		end
% 		pst1_ds.(imp_abs_str) = pst1_ds.(imp_str) .* abs(pst1_ds.(new_v_name));
% 		
% 		var_str = ['d_' sess_str '_post2_' arm];
% 		pst2_ds = ds(ds.Measure==measure, {'Subj' var_str});
% 		v_names = get(pst2_ds,'VarNames');
% 		new_v_name = ['delta_' measure '_post2'];
% 		v_names = strrep(v_names, var_str, new_v_name);
% 		pst2_ds = set(pst2_ds,'VarNames', v_names);
% 		imp_str = [measure '_impr_post2'];
% 		imp_abs_str = [measure '_abs_impr_post2'];
% 		if improved_is_lower
% 			pst2_ds.(imp_str) = pst2_ds.(new_v_name) < 0;
% 		else
% 			pst2_ds.(imp_str) = pst2_ds.(new_v_name) > 0;
% 		end
% 		pst2_ds.(imp_abs_str) = pst2_ds.(imp_str) .* abs(pst2_ds.(new_v_name));
% 		
% 		both_ds = join(pst1_ds,pst2_ds);
% 		both_ds.Treatment = repmat(new_sess_str(sess_str), size(both_ds,1),1);
% 		
% 		if isempty(measure_ds)
% 			measure_ds = both_ds;
% 		else
% 			measure_ds = vertcat(measure_ds, both_ds);
% 		end
		
	end % sess_types

	if isempty(out_ds)
		out_ds = measure_ds;
	else
		out_ds = join(out_ds,measure_ds,{'Subj', 'Treatment', 'Pre_post'});
	end
end % measure

if strcmp(inputs.out_file, 'none')
	% request where to save 
	[fName, pathName] = getsavenames(fullfile(pwd, 'mm_format.txt'), 'Save as');
	if isequal(fName, 0) || isequal(pathName, 0)
		disp('Not saving. User canceled.');
		return;
	end
	inputs.out_file = fullfile(pathName, fName);
end

% save
export(out_ds, 'File', inputs.out_file, 'delimiter', '\t')

return

% ----------------------------------------
function new_str = new_sess_str(sess_str)
switch sess_str
	case 'Hs'
		new_str = 'S';
	case 'Ha'
		new_str = 'H';
	case 'L'
		new_str = 'L';
	case 'Hs_g'
		new_str = 'S_g';
	case 'Ha_g'
		new_str = 'H_g';
	case 'L_g'
		new_str = 'L_g';
	otherwise
		new_str = 'X';
end
return

function improved_is_lower = is_improved_lower(measure)
switch measure(1:4)
	case {'prop' 'grip'}
		improved_is_lower = false;
	otherwise
		improved_is_lower = true;
end
return
		