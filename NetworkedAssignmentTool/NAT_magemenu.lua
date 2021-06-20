NAT_create_mage_menu_controller = 
function(_postOptionObject, _postLabel, _viewBody)
	local controller = NAT_create_menu_controller(_postOptionObject, _postLabel, _viewBody);
	controller.tag = "Mage";
	controller.toggle_command = "toggle_mage-"; --network
	controller.add_player_command = "add_mage"; --observer command 
	controller.remove_player_command = "remove_mage"; --observer command
	controller.current_focus_mark = "";
	controller.current_menu_parent = nil;
	controller.marks = {"Group1", "Group2", "Group3", "Group4", "Group5", "Group6", "Group7", "Group8", "Other"};
	controller.assigned_players = {["Group1"]={}, ["Group2"]={}, ["Group3"]={}, ["Group4"]={}, ["Group5"]={}, ["Group6"]={}, ["Group7"]={}, ["Group8"]={}, ["Other"]={}};
	controller.useable_classes = {"Mage"};
	
	--FUNCTIONS-------------------------------------------------------------------------------------------------------F

	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	
	return controller;
end 