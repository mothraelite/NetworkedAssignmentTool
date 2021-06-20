NAT_create_interrupt_menu_controller = 
function(_postOptionObject, _postLabel, _viewBody)
	local controller = NAT_create_menu_controller(_postOptionObject, _postLabel, _viewBody);

	--VARIABLES-------------------------------------------------------------------------------------------------------V
	controller.tag = "Interrupt";
	controller.useable_classes = {"Warrior", "Mage", "Shaman", "Rogue"};
	controller.toggle_command = "toggle_interrupt-"; --network
	controller.add_player_command = "add_interrupter"; --observer command 
	controller.remove_player_command = "remove_interrupter"; --observer command

	--VARIABLES-------------------------------------------------------------------------------------------------------V


	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	
	return controller;
end 