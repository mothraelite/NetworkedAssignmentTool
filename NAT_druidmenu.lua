NAT_create_druid_menu_controller = 
function(_postOptionObject, _postLabel, _viewBody)
	local controller = NAT_create_menu_controller(_postOptionObject, _postLabel, _viewBody);
	controller.tag = "Druid";
	controller.toggle_command = "toggle_druid-"; --network
	controller.add_player_command = "add_druid"; --observer command 
	controller.remove_player_command = "remove_druid"; --observer command
	controller.current_focus_mark = "";
	controller.current_menu_parent = nil;
	controller.marks = {"Group1", "Group2", "Group3", "Group4", "Group5", "Group6", "Group7", "Group8", "Other"};
	controller.assigned_players = {["Group1"]={}, ["Group2"]={}, ["Group3"]={}, ["Group4"]={}, ["Group5"]={}, ["Group6"]={}, ["Group7"]={}, ["Group8"]={}, ["Other"]={}};
	controller.useable_classes = {"Druid"};
	
	--FUNCTIONS-------------------------------------------------------------------------------------------------------F

	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	
	return controller;
end 