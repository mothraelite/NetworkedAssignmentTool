--[[
			@author: moth<milaninavid@gmail.com>
			title: NAT "Networked assignment tool"
			description: TBC tank and healing assignment tool.  
			This can be used too coordinate, display, and adjust 
			assignments quickly and efficiently.
			
			credits: shout out to attreyo on vg for some inspiration.
--]]
local tank_controller = NAT_create_tank_menu_controller(); --tank drop down menu controller
local healer_controller = NAT_create_healer_menu_controller(); --healer drop down menu controller
table.insert(tank_controller.observers, healer_controller); --add healer controller to tank observer list
local interrupt_controller = NAT_create_interrupt_menu_controller();
local network_controller = NAT_create_network_handler(tank_controller, healer_controller, interrupt_controller);

--what selection mode im in
	--1: tanks
	--2: healers
	--3: interrupters
local current_mode = 1; 

function NAT_init()
	--setup reg functions
	NAT:RegisterForDrag("LeftButton");
	NAT:RegisterEvent("RAID_ROSTER_UPDATE"); --fires on personal promotion, personal demotion, anyone joining raid, anyone leaving raid
	NAT:RegisterEvent("RAID_TARGET_UPDATE"); --unfortunately, no response that indicates what was changed. probably going to notify all assigned tanks that things have changed though.
	NAT:RegisterEvent("CHAT_MSG_ADDON");
	--RegisterAddonMessagePrefix("NAT");
	
	--get initial list of raid mems
	NAT_poll_for_players();

	--See if someone is in the raid that is running the addon
	network_controller.request_setup();
		
	-- Slash commands
	SlashCmdList["NATCOMMAND"] = NAT_slashCommandHandler;
	SLASH_NATCOMMAND1 = "/NAT";

	--Init handler
	DEFAULT_CHAT_FRAME:AddMessage("NAT: Initializing NAT version 1.02", 0.6,1.0,0.6);
end

function NAT_request_master()
	if not IsRaidLeader() and not IsRaidOfficer()
	then
		DEFAULT_CHAT_FRAME:AddMessage("NAT: You need to be the raid leader or have assist to request master status.", 0.6,1.0,0.6);
		return;
	end

	network_controller.request_master();
end

function NAT_handle_events(event)
	if event == "RAID_ROSTER_UPDATE" 
	then
		--if im not setup yet, request a setup or become master
		if network_controller.state == -1
		then
			network_controller.request_setup();
		else
		--I lost pre-req for master status so check if I am the master
			if network_controller.master == UnitName("player") and not IsRaidOfficer() and not IsRaidLeader()
			then
				--I was master, relinquish title.
				--network_controller.request_new_master();
			end 
		end
		
		--check if I left a raid
		if UnitInRaid("player") == nil
		then
			DEFAULT_CHAT_FRAME:AddMessage("NAT: left raid. resetting.", 0.6,1.0,0.6);
			NAT_reset_addon();
			return;
		end
	
		NAT_poll_for_players();
	elseif event == "CHAT_MSG_ADDON"
	then
		if arg1 == "NAT"
		then
			local command, message, sender = network_controller.extract_command_and_message(arg2);
			
			--ignore my own networked messages
			if sender == UnitName("player")
			then
				return;
			end
		
			if command == "request_setup"
			then
				network_controller.return_setup(message);
			elseif command == "request_master"
			then
				network_controller.master = message;
				NATMasterLabel:SetText("Master: "..message);
			elseif command == "setup_master" --setup my own
			then 
				
				network_controller.setup_master(message);
			elseif command == "setup_tanks"
			then
				network_controller.setup_tanks(message);
			elseif command == "setup_healers"
			then
				network_controller.setup_healers(message);
			elseif command == "setup_interrupters"
			then
				network_controller.setup_interrupters(message);
				
				if current_mode == 3
				then
					interrupt_controller.update_marks();
				end
			elseif command == "toggle_tank"
			then
				network_controller.toggle_tank(message);
			elseif command == "toggle_healer"
			then
				network_controller.toggle_healer(message);
			elseif command == "toggle_interrupt"
			then
				network_controller.toggle_interrupter(message);
			
				if current_mode == 3
				then
					interrupt_controller.update_marks();
				end
			elseif command == "reset"
			then 
				NAT_reset_addon();
				network_controller.request_setup();
				DEFAULT_CHAT_FRAME:AddMessage("NAT: Reset by "..sender, 0.6,1.0,0.6);
			end
			
		end
	end
end

local time_since_last_update = 0;
function NAT_update(elapsed)
	--UPDATE PER CYCLE
	network_controller.update();
	
	--UPDATES VIA SECONDS
		--time since last update cycle. note, this returns a float not an int in seconds thus the need to do this.
	time_since_last_update = time_since_last_update + elapsed;
	
	local seconds = math.floor(time_since_last_update);
	for i=1, seconds, 1
	do
		NAT_update_alarms();
	end 
	time_since_last_update = time_since_last_update - seconds; --we exhausted the updates needed per second
end

function NAT_slashCommandHandler(msg)
	local msg_split = NAT_split(msg, " ");
	command = msg_split[1];

	if command == "show"
	then
		NAT:Show();
	elseif command == "hide"
	then
		NAT:Hide();
	elseif command == "post"
	then
		NAT_post();
	elseif command == "postall"
	then
		NAT_post_all();
	elseif command == "reset"
	then
		NAT_reset_addon();
		network_controller.request_setup();
	elseif command == "randomtanks"
	then
		if table.getn(msg_split) == 1
		then
			DEFAULT_CHAT_FRAME:AddMessage("NAT: Error - command randomtanks expects a space then a number to proceed it", 0.6,1.0,0.6);
			return;
		end
		
		local val = tonumber(msg_split[2]);
		if val == nil
		then
			DEFAULT_CHAT_FRAME:AddMessage("NAT: Error - command randomtanks expects a number but got " .. msg_split[2], 0.6,1.0,0.6);
		end

		tank_controller.random_assign(val);
	elseif command == "master"
	then
		network_controller.request_master();
	else
		DEFAULT_CHAT_FRAME:AddMessage("NAT: Error, could not understand input.\nValid commands:\n1)/nat show\n2)/nat hide\n3)/nat post'\n4)/nat postall\n5)/nat randomtanks <number>", 0.6,1.0,0.6);
	end
end

--Function to fire when a new mode is selected
function NAT_mode_picker_clicked(index)
	--reset visuals
	NAT_reset_visuals();
	
	--select visuals
	if index == 1 --tank
	then
		--show tank visuals
		NAT_tank_body:Show();
		tank_controller.update_marks();
		current_mode = 1;
	elseif index == 2 --heals
	then
		NAT_healer_body:Show();
		healer_controller.update_marks();
		current_mode = 2;
	elseif index == 3 --interrupt
	then
		--show interrupt visuals
		NAT_interrupt_body:Show();
		interrupt_controller.update_marks();
		current_mode = 3;
	end 
end

function NAT_request_setup()
	network_controller.request_setup();
end

function NAT_post()
	if not IsRaidLeader() and not IsRaidOfficer()
	then
		DEFAULT_CHAT_FRAME:AddMessage("NAT: You need to be the raid leader or have assist to use this command", 0.6,1.0,0.6);
		return;
	end
	
	if current_mode == 1 --tanks
	then 
		tank_controller.post();
	elseif current_mode == 2 --healers
	then
		healer_controller.post();
	elseif current_mode == 3 --interrupts
	then
		interrupt_controller.post();
	end
end

function NAT_post_all()
	if not IsRaidLeader() and not IsRaidOfficer()
	then
		DEFAULT_CHAT_FRAME:AddMessage("NAT: You need to be the raid leader or have assist to use this command", 0.6,1.0,0.6);
		return;
	end
	
	tank_controller.post();
	healer_controller.post();
	interrupt_controller.post();
end

--show submenu when mousing over current marks
function NAT_show_listmenu(parent, focus_mark)
	if current_mode == 1
	then
		tank_controller.current_focus_mark = focus_mark;
		tank_controller.current_menu_parent = parent;
		ToggleDropDownMenu(nil, 1, NAT_tank_list, parent, 0, 25);
	elseif current_mode == 2
	then
		if focus_mark == "" or focus_mark == nil
		then
			return;
		end
	
		healer_controller.current_focus_mark = focus_mark;
		healer_controller.current_menu_parent = parent;
		ToggleDropDownMenu(nil,1,NAT_heal_list, parent, 0, 25);
	elseif current_mode == 3
	then
		interrupt_controller.current_focus_mark = focus_mark;
		interrupt_controller.current_menu_parent = parent;
		ToggleDropDownMenu(nil,1,NAT_interrupt_list,parent,0,25);
	end
end

--POST INPUT BOX FUNCTIONS---------------------------------------------------------------------------PI
function NAT_on_post_enter(self)
	GameTooltip:SetOwner(self);
	GameTooltip:SetText("Set channel to announce current assignments");
	GameTooltip:AddLine("Selections:");
	GameTooltip:AddLine("-s: Say");
	GameTooltip:AddLine("-p: Party");
	GameTooltip:AddLine("-r: Raid");
	GameTooltip:AddLine("-<number>: Channel number");
	GameTooltip:Show();
end

function NAT_on_post_text_changed(self)
	if current_mode == 1
	then
		tank_controller.set_post_location(self:GetText());
	elseif current_mode == 2
	then
		healer_controller.set_post_location(self:GetText());
	elseif current_mode == 3
	then
		interrupt_controller.set_post_location(self:GetText());
	end
	self:ClearFocus();
end

function NAT_on_post_exit(self)
	GameTooltip:Hide();
end
--POST INPUT BOX FUNCTIONS---------------------------------------------------------------------------PI

--HELPER FUNCTIONS---------------------------------------------------------------------------------------HF
function NAT_poll_for_players()
	--am I in raid?
	if UnitInRaid("player") == nil
	then
		return;
	end 
	
	--tanks
	tank_controller.poll_for_tanks();
	UIDropDownMenu_Initialize(NAT_tank_list, tank_controller.init, "MENU", 2);
	
	--healers 
	healer_controller.poll_for_healers();
	UIDropDownMenu_Initialize(NAT_heal_list, healer_controller.init, "MENU", 2);
	
	--interupts
	interrupt_controller.poll_for_interrupts();
	UIDropDownMenu_Initialize(NAT_interrupt_list, interrupt_controller.init, "MENU", 2);
	
	if current_mode == 1
	then
		tank_controller.update_marks();
	elseif current_mode == 2
	then
		healer_controller.update_marks();
	elseif current_mode == 3
	then
		interrupt_controller.update_marks();
	end
end


--Function to setup the mode picker selections
function NAT_init_mode_picker()
	local tank = {};
	tank.text = "Tanks";
	tank.value = 1;
	tank.func = function() UIDropDownMenu_SetSelectedID(NAT_mode_chooser, 1); NAT_mode_picker_clicked(1); end;
	
	local heal = {};
	heal.text = "Healers";
	heal.value = 2;
	heal.func = function() UIDropDownMenu_SetSelectedID(NAT_mode_chooser, 2); NAT_mode_picker_clicked(2); end;
	
	local interupts = {};
	interupts.text = "Interrupts";
	interupts.value = 3;
	interupts.func = function() UIDropDownMenu_SetSelectedID(NAT_mode_chooser, 3); NAT_mode_picker_clicked(3); end;
	
	UIDropDownMenu_AddButton(tank);
	UIDropDownMenu_AddButton(heal);
	UIDropDownMenu_AddButton(interupts);
end

function NAT_reset_visuals()
	NAT_tank_body:Hide();
	NAT_healer_body:Hide();
	NAT_interrupt_body:Hide();
end

function NAT_reset_addon()
	--reset healer marks
	tank1_label:SetText("");
	tank2_label:SetText("");
	tank3_label:SetText("");
	tank4_label:SetText("");
	tank5_label:SetText("");
	tank6_label:SetText("");
	tank7_label:SetText("");
	tank8_label:SetText("");
	tank9_label:SetText("");
	
	--reset data
	network_controller.reset_setup();
	
	--reset visuals
	if current_mode == 1
	then
		tank_controller.update_marks();
	elseif current_mode == 2
	then
		tank_controller.update_marks();
	elseif current_mode == 3
	then
		tank_controller.update_marks();
	end
end
--HELPER FUNCTIONS---------------------------------------------------------------------------------------HF

function NAT_is_ready()
	if network_controller.state == 1
	then
		return true;
	else 
		return false;
	end
end