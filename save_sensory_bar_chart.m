function save_sensory_bar_chart(hfig_list)

for cnt = 1:length(hfig_list)
	hf = hfig_list(cnt);
	
	figure(hf)
	ud = get(hf, 'UserData');
	fname = ud.savefigname;
	savefig(hf, [fname '.fig'])
	
% 	ha = gca;
% 	ha.Title.Visible = 'off';
	print(hf, '-dpng', [fname '.png'])
end