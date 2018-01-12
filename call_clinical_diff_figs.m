function call_clinical_diff_figs


tbl = clinical_diff_figs('file','Sensory_rTMS_ClinicalData_20170710_taller_difference_variables.txt', ...
	'measure', {'vibr_elbw_avg'}, 'post',{'post2'},'arm',{'inv'},'glove',{'with'}, 'cohort',{'whole'});


tbl2 = clinical_diff_figs('file','Sensory_rTMS_ClinicalData_20170710_taller_difference_variables.txt', ...
	'measure', {'vibr_dig2_avg'}, 'post',{'post2'},'arm',{'inv'},'glove',{'without'}, 'cohort',{'whole'});

tbl = vertcat(tbl,tbl2);

tbl2 = clinical_diff_figs('file','Sensory_rTMS_ClinicalData_20170710_taller_difference_variables.txt', ...
	'measure', {'vibr_dig2_avg'}, 'post',{'post1'},'arm',{'inv'},'glove',{'with'}, 'cohort',{'6session'});

tbl = vertcat(tbl,tbl2);

tbl2 = clinical_diff_figs('file','Sensory_rTMS_ClinicalData_20170710_taller_difference_variables.txt', ...
	'measure', {'vibr_elbw_avg'}, 'post',{'post1'},'arm',{'inv'},'glove',{'with'}, 'cohort',{'6session'});

tbl = vertcat(tbl,tbl2);

tbl2 = clinical_diff_figs('file','Sensory_rTMS_ClinicalData_20170710_taller_difference_variables.txt', ...
	'measure', {'vibr_elbw_avg'}, 'post',{'post2'},'arm',{'inv'},'glove',{'with'}, 'cohort',{'6session'});

tbl = vertcat(tbl,tbl2);

writetable(tbl,'vibr_desrip_stats.xlsx')
