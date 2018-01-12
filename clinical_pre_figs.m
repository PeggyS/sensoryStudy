
tbl = readtable('session_order_and_previous.xlsx');

tbl.Subj = nominal(tbl.Subj);
tbl.SessType = nominal(tbl.SessType);
tbl.prev_sess_type = nominal(tbl.prev_sess_type);
tbl.arm_stim = nominal(tbl.arm_stim);
tbl.measure = nominal(tbl.measure);

inv_2pt_dig4 = tbl(tbl.arm_stim=='inv' & tbl.measure=='x2pt_dig4',:);


% plot session_num vs session_diff
figure
hold on
% plot 1 line for each subj
subj_list = unique(tbl.Subj);
for subj_cnt = 1:length(subj_list)
	subj = subj_list(subj_cnt);
	
	subj_data = tbl(tbl.arm_stim=='inv' & tbl.measure=='x2pt_dig4' & tbl.Subj==subj,:);
	plot(subj_data.session_num, subj_data.session_diff, 'o-')
	
end