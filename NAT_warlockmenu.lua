NAT_create_warlock_menu_controller = 
function(_postOptionObject, _postLabel, _viewBody)
	local controller = NAT_create_menu_controller(_postOptionObject, _postLabel, _viewBody);
	controller.tag = "Warlock";
	controller.toggle_command = "toggle_warlock-"; --network
	controller.add_player_command = "add_warlock"; --observer command 
	controller.remove_player_command = "remove_warlock"; --observer command
	controller.current_focus_mark = "";
	controller.current_menu_parent = nil;
	controller.marks = {"Recklessness", "Shadow", "Elements"};
	controller.assigned_players = {["Recklessness"]={}, ["Shadow"]={}, ["Elements"]={}};
	controller.useable_classes = {"Warlock"};
	
	--FUNCTIONS-------------------------------------------------------------------------------------------------------F

	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	
	return controller;
end 