NAT_create_tank_menu_controller = 
function(_postOptionObject, _postLabel, _viewBody)
	local controller = NAT_create_menu_controller(_postOptionObject, _postLabel, _viewBody);
	controller.tag = "Tank";
	controller.toggle_command = "toggle_tank-"; --network
	controller.add_player_command = "add_tank"; --observer command 
	controller.remove_player_command = "remove_tank"; --observer command

	return controller;
end 