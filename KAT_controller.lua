--[[
			@author: moth<milaninavid@gmail.com>
			title: KAT "Kat assignment tool"
			description: TBC tank and healing assignment tool.  
			This can be used too coordinate, display, and adjust 
			assignments quickly and efficiently.
			
			credits: shout out to attreyo on vg for some inspiration.
--]]
local tank_controller = KAT_create_tank_menu_controller(); --tank drop down menu controller

--what selection mode im in
	--1: tanks
	--2: healers
	--3: interupters
	--4: misc
local current_mode = 1; 


function KAT_init()
	--setup reg functions
	KAT:RegisterForDrag("LeftButton");
	KAT:RegisterEvent("RAID_ROSTER_UPDATE");
	KAT:SetScript("OnEvent", KAT_handle_events);

	--get initial list of raid mems
	KAT_poll_for_players();

	--See if someone is in the raid that is running the addon
		--take a copy of their assignments so far
		
	-- Slash commands
	SlashCmdList["KATCOMMAND"] = KAT_slashCommandHandler;
	SLASH_KATCOMMAND1 = "/kat";

	--Init handler
	DEFAULT_CHAT_FRAME:AddMessage("Initializing KAT version 0.1d.", 0.6,1.0,0.6);
end

function KAT_handle_events(self, event, ...)
	if event == "RAID_ROSTER_UPDATE" 
	then 
		KAT_poll_for_players();
	end
end

function KAT_slashCommandHandler(msg)
	if msg == "" or msg == " "
	then
		KAT_post();
	elseif msg == "show"
	then
		KAT:Show();
	elseif msg == "hide"
	then
		KAT:Hide();
	elseif strsub(msg, 1, 4) == "post"
	then
		KAT_post();
	else
		DEFAULT_CHAT_FRAME:AddMessage("KAT: Error, could not understand input.\nValid commands:\n1)/kat show\n2)/kat hide\n3)/kat post\n4)/kat", 0.6,1.0,0.6);
	end
end

--show submenu when mousing over current tanks
function KAT_show_healers()

end

function KAT_post()
	--tanks
	tank_controller.post();
	
end

--show submenu when mousing over current marks
function KAT_show_tanks(parent, focus_mark)
	tank_controller.current_focus_mark = focus_mark;
	tank_controller.current_menu_parent = parent;
	ToggleDropDownMenu(nil, 1, KAT_tank_list, parent, 0, 0);
end

function KAT_close_tank_menu()
	if current_menu_parent == nil
	then
		return;
	end

	ToggleDropDownMenu(nil, 1, KAT_tank_list, tank_controller.current_menu_parent, 0, 0);
end

--show submenu when mousing over current interupters
function KAT_show_interupters()

end

--show submenu for all
function KAT_show_misc()

end

--HELPER FUNCTIONS---------------------------------------------------------------------------------------HF

--Function to fire when a new mode is selected
function KAT_mode_picker_clicked(index)
	--reset visuals

	--select visuals
	if index == 1 --tank
	then
		current_mode = 1;
	elseif index == 2 --heals
	then
		current_mode = 2;
	elseif index == 3 --interupt
	then
		current_mode = 3;
	elseif index == 4 --misc
	then 
		current_mode = 4;
	end 
end

--Function to fire when tank menu list item is clicked
function KAT_tank_picker_clicked(index)

end




--Function to setup the mode picker selections
function KAT_init_mode_picker()
	local tank = {};
	tank.text = "Tank Assignments";
	tank.value = 1;
	tank.func = function() UIDropDownMenu_SetSelectedID(KAT_mode_chooser, 1); KAT_mode_picker_clicked(1); end;
	
	local heal = {};
	heal.text = "Healer Assignments";
	heal.value = 2;
	heal.func = function() UIDropDownMenu_SetSelectedID(KAT_mode_chooser, 2); KAT_mode_picker_clicked(2); end;
	
	local interupts = {};
	interupts.text = "Interupt Assignments";
	interupts.value = 3;
	interupts.func = function() UIDropDownMenu_SetSelectedID(KAT_mode_chooser, 3); KAT_mode_picker_clicked(3); end;
	
	local misc = {};
	misc.text = "Misc Assignments";
	misc.value = 4;
	misc.func = function() UIDropDownMenu_SetSelectedID(KAT_mode_chooser, 4); KAT_mode_picker_clicked(4); end;
	
	UIDropDownMenu_AddButton(tank);
	UIDropDownMenu_AddButton(heal);
	UIDropDownMenu_AddButton(interupts);
	UIDropDownMenu_AddButton(misc);
end

function KAT_poll_for_players()
	--am I in raid?
	if UnitInRaid("player") == nil
	then
		return;
	end 
	
	--tanks
	tank_controller.poll_for_tanks();
	UIDropDownMenu_Initialize(KAT_tank_list, tank_controller.init, "MENU", 2);
end
--HELPER FUNCTIONS---------------------------------------------------------------------------------------HF
