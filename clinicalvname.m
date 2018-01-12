
ptVar={'Pt2'	'Pt2_10'	'Pt4'	'Pt4_10'};
vVar={'V2t1'	'V2t2'	'V2t3'	'Vet1'	'Vet2'	'Vet3'};
propVar={'PropD'	'PropW'}
moVar={'Mono2non'	'Mono2loc'	'Mono4non'	'Mono4loc'};
tVar={'Temp'};


ioru = {'Inv' 'Un'}

dc={'pre' 'post1' 'post2'}


newVars = {};
for i = 1:length(dc), 
	for j = 1:length(ioru), 
		for k = 1:length(ptVar),
			newVars = {newVars{:} [dc{i} ioru{j} ptVar{k}] };
		end
	end

	for j = 1:length(ioru), 	
		for k = 1:length(vVar),
			newVars = {newVars{:} [dc{i} ioru{j} vVar{k}] };
		end
	end
	for j = 1:length(ioru), 
		for k = 1:length(propVar),
			newVars = {newVars{:} [dc{i} ioru{j} propVar{k}] };
		end
	end
	for j = 1:length(ioru), 
		for k = 1:length(moVar),
			newVars = {newVars{:} [dc{i} ioru{j} moVar{k}] };
		end
	end
	for j = 1:length(ioru), 
		for k = 1:length(tVar),
			newVars = {newVars{:} [dc{i} ioru{j} tVar{k}] };
		end
	end

end

fid = fopen('clinicalvnames.csv','w');
for i = 1:length(newVars),
%	disp( 'adl');
	fprintf(fid,'%s,', newVars{i});
end
fclose(fid);
