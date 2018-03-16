function out_file = request_file(in_file, type_str, instructions_str)


if isempty(in_file)		% no file specified
	% request the data file
	disp(instructions_str)
	[fname, pathname] = uigetfile(type_str, instructions_str);
	if isequal(fname,0) || isequal(pathname,0)
		disp('User canceled. Exitting')
		out_file = '';
		return
	else
		out_file = fullfile(pathname,fname);
	end
else
	out_file = in_file;
end

return