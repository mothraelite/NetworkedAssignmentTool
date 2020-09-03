--[[
			@author: moth<milaninavid@gmail.com>
			title: NAT "Networked assignment tool"
			description: TBC tank and healing assignment tool.  
			This can be used too coordinate, display, and adjust 
			assignments quickly and efficiently.
			
			credits: shout out to attreyo on vg for some inspiration.
--]]
local tank_controller; --tank drop down menu controller
local healer_controller; --healer drop down menu controller
local interrupt_controller; --interrupt drop down menu controller
local priest_controller; --priest drop down menu controller
local network_controller;

--xml references for easy access
local chooser_buttons = {};

--what selection mode im in
	--1: tanks
	--2: healers
	--3: interrupters
local current_mode = 1; 

function NAT:init()
	--setup reg functions
	NAT:RegisterForDrag("LeftButton");
	NAT:RegisterEvent("RAID_ROSTER_UPDATE"); --fires on personal promotion, personal demotion, anyone joining raid, anyone leaving raid
	NAT:RegisterEvent("RAID_TARGET_UPDATE"); --unfortunately, no response that indicates what was changed. probably going to notify all assigned tanks that things have changed though.
	NAT:RegisterEvent("CHAT_MSG_ADDON");
	--RegisterAddonMessagePrefix("NAT");
	
	--setup controllers
	tank_controller = NAT_create_tank_menu_controller(NATTankPostChannelEdit, NATTankPostLabel, NAT_tank_body); 
	healer_controller = NAT_create_healer_menu_controller(NATHealerPostChannelEdit, NATHealPostLabel, NAT_healer_body); 
	table.insert(tank_controller.observers, healer_controller); --add healer controller to tank observer list
	interrupt_controller = NAT_create_interrupt_menu_controller(NATInterruptPostChannelEdit, NATInterruptPostLabel, NAT_interrupt_body);
	priest_controller = NAT_create_priest_menu_controller(NATPirestPostChannelEdit, NATPriestPostLabel, NAT_priest_body);
	mage_controller = NAT_create_mage_menu_controller(NATMagePostChannelEdit, NATMagePostLabel, NAT_mage_body);
	druid_controller = NAT_create_druid_menu_controller(NATDruidPostChannelEdit, NATDruidPostLabel, NAT_druid_body);
	warlock_controller = NAT_create_warlock_menu_controller(NATWarlockPostChannelEdit, NATWarlockPostLabel, NAT_warlock_body);
	network_controller = NAT_create_network_handler(tank_controller, healer_controller, interrupt_controller, priest_controller, mage_controller, druid_controller, warlock_controller);

	table.insert(chooser_buttons, NAT_choose_tank_menu);
	table.insert(chooser_buttons, NAT_choose_healer_menu);
	table.insert(chooser_buttons, NAT_choose_interrupt_menu);
	table.insert(chooser_buttons, NAT_choose_priest_menu);
	table.insert(chooser_buttons, NAT_choose_mage_menu);
	table.insert(chooser_buttons, NAT_choose_druid_menu);
	table.insert(chooser_buttons, NAT_choose_warlock_menu);
	
	--get initial list of raid mems
	NAT_poll_for_players();

	--See if someone is in the raid that is running the addon
	network_controller.request_setup();
		
	-- Slash commands
	SlashCmdList["NATCOMMAND"] = NAT_slashCommandHandler;
	SLASH_NATCOMMAND1 = "/NAT";

	--Init handler
	DEFAULT_CHAT_FRAME:AddMessage("NAT: Initializing NAT version 2.1", 0.6,1.0,0.6);
end

function NAT:request_master()
	if not IsRaidLeader() and not IsRaidOfficer()
	then
		DEFAULT_CHAT_FRAME:AddMessage("NAT: You need to be the raid leader or have assist to request master status.", 0.6,1.0,0.6);
		return;
	end

	network_controller.request_master();
end

function NAT:handle_events(event)
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
			elseif command == "setup_version"
			then
				network_controller.setup_version(message);
			elseif command == "setup_master" --setup my own
			then 
				network_controller.setup_master(message);
			elseif command == "setup_tanks"
			then
				network_controller.setup_tanks(message);
			elseif command == "setup_healers"
			then
				--check if im ready to ingest healers as tanks are a prereq
				if network_controller.setup["tanks"] == true
				then
					network_controller.setup_healers(message);
				else
					--im not, wait a second and try then
					NAT_set_alarm(1, 
					function() 
						if network_controller.setup["tanks"] == true 
						then 
							network_controller.setup_healers(message); 
						end 
					end);
				end
				
			elseif command == "setup_interrupters"
			then
				network_controller.setup_interrupters(message);
			elseif command == "setup_priests"
			then
				network_controller.setup_priests(message);
			elseif command == "setup_mages"
			then
				network_controller.setup_mages(message);
			elseif command =="setup_druids"
			then
				network_controller.setup_druids(message);
			elseif command == "setup_warlocks"
			then
				network_controller.setup_warlocks(message);
			elseif command == "toggle_tank"
			then
				network_controller.toggle_tank(message);
			elseif command == "toggle_healer"
			then
				network_controller.toggle_healer(message);
			elseif command == "toggle_interrupt"
			then
				network_controller.toggle_interrupter(message);
			elseif command == "toggle_priest"
			then
				network_controller.toggle_priest(message);
			elseif command == "toggle_mage"
			then
				network_controller.toggle_mage(message);
			elseif command == "toggle_druid"
			then
				network_controller.toggle_druid(message);
			elseif command == "toggle_warlock"
			then
				network_controller.toggle_warlock(message);
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
function NAT:update(elapsed)
--DEFAULT_CHAT_FRAME:AddMessage("NAT: " .. elapsed , 0.6,1.0,0.6);
	--UPDATE PER CYCLE
	network_controller.update();
	
	--UPDATES VIA SECONDS
		--time since last update cycle. note, this returns a float not an int in seconds thus the need to do this.
	time_since_last_update = time_since_last_update + elapsed;
	
	if time_since_last_update >= 1
	then
		local seconds = math.floor(time_since_last_update);
		for i=1, seconds, 1
		do
			NAT_update_alarms();
		end 
		time_since_last_update = time_since_last_update - seconds; --we exhausted the updates needed per second
	end
end

function NAT:slashCommandHandler(msg)
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
	
	local ypos = -35-50*(index-1)
	
	--select visuals
	if index == 1 --tank
	then
		--show tank visuals
		NAT_tank_body:Show();
		tank_controller.update_marks();
		chooser_buttons[index]:SetPoint("TOPLEFT", NAT, "TOPLEFT", -38, ypos);
		NATTitleLabel:SetText("Tank Assignments");
		current_mode = 1;
	elseif index == 2 --heals
	then
		NAT_healer_body:Show();
		healer_controller.update_marks();
		chooser_buttons[index]:SetPoint("TOPLEFT", NAT, "TOPLEFT", -38, ypos);
		NATTitleLabel:SetText("Healer Assignments");
		current_mode = 2;
	elseif index == 3 --interrupt
	then
		--show interrupt visuals
		NAT_interrupt_body:Show();
		interrupt_controller.update_marks();
		chooser_buttons[index]:SetPoint("TOPLEFT", NAT, "TOPLEFT",  -38, ypos);
		NATTitleLabel:SetText("Interrupt Assignments");
		current_mode = 3;
	elseif index == 4 --priest
	then
		--show interrupt visuals
		NAT_priest_body:Show();
		priest_controller.update_marks();
		chooser_buttons[index]:SetPoint("TOPLEFT", NAT, "TOPLEFT",  -38, ypos);
		NATTitleLabel:SetText("Priest Assignments");
		current_mode = 4;
	elseif index == 5 --mage
	then
		--show interrupt visuals
		NAT_mage_body:Show();
		mage_controller.update_marks();
		chooser_buttons[index]:SetPoint("TOPLEFT", NAT, "TOPLEFT",  -38, ypos);
		NATTitleLabel:SetText("Mage Assignments");
		current_mode = 5;
	elseif index == 6 --druid
	then
		--show interrupt visuals
		NAT_druid_body:Show();
		druid_controller.update_marks();
		chooser_buttons[index]:SetPoint("TOPLEFT", NAT, "TOPLEFT",  -38, ypos);
		NATTitleLabel:SetText("Druid Assignments");
		current_mode = 6;
	elseif index == 7 --warlock
	then
		--show interrupt visuals
		NAT_warlock_body:Show();
		warlock_controller.update_marks();
		chooser_buttons[index]:SetPoint("TOPLEFT", NAT, "TOPLEFT",  -38, ypos);
		NATTitleLabel:SetText("Warlock Assignments");
		current_mode = 7;
	end 
end

function NAT:request_setup()
	network_controller.request_setup();
end

function NAT:post()
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
	elseif current_mode == 4 --priests
	then
		priest_controller.post();
	elseif current_mode == 5 --mage
	then
		mage_controller.post();
	elseif current_mode == 6 --druid
	then
		druid_controller.post();
	elseif current_mode == 7 --warlock
	then
		warlock_controller.post();
	end
end

function NAT:post_all()
	if not IsRaidLeader() and not IsRaidOfficer()
	then
		DEFAULT_CHAT_FRAME:AddMessage("NAT: You need to be the raid leader or have assist to use this command", 0.6,1.0,0.6);
		return;
	end
	
	tank_controller.post();
	healer_controller.post();
	interrupt_controller.post();
	priest_controller.post();
	mage_controller.post();
	druid_controller.post();
	warlock_controller.post();
end

--show submenu when mousing over current marks
function NAT:show_listmenu(parent, focus_mark)
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
	elseif current_mode == 4
	then
		priest_controller.current_focus_mark = focus_mark;
		priest_controller.current_menu_parent = parent;
		ToggleDropDownMenu(nil, 1, NAT_priest_list, parent, 0, 25);
	elseif current_mode == 5
	then 
		mage_controller.current_focus_mark = focus_mark;
		mage_controller.current_menu_parent = parent;
		ToggleDropDownMenu(nil, 1, NAT_mage_list, parent, 0, 25);
	elseif current_mode == 6
	then 
		druid_controller.current_focus_mark = focus_mark;
		druid_controller.current_menu_parent = parent;
		ToggleDropDownMenu(nil, 1, NAT_druid_list, parent, 0, 25);
	elseif current_mode == 7
	then
		warlock_controller.current_focus_mark = focus_mark;
		warlock_controller.current_menu_parent = parent;
		ToggleDropDownMenu(nil, 1, NAT_warlock_list, parent, 0, 25);
	end
end

--POST INPUT BOX FUNCTIONS---------------------------------------------------------------------------PI
function NAT:on_post_enter(self)
	GameTooltip:SetOwner(self);
	GameTooltip:SetText("Set channel to announce current assignments");
	GameTooltip:AddLine("Selections:");
	GameTooltip:AddLine("-s: Say");
	GameTooltip:AddLine("-p: Party");
	GameTooltip:AddLine("-r: Raid");
	GameTooltip:AddLine("-<number>: Channel number");
	GameTooltip:Show();
end

function NAT:on_post_text_changed(self)
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

function NAT:on_post_exit(self)
	GameTooltip:Hide();
end
--POST INPUT BOX FUNCTIONS---------------------------------------------------------------------------PI

--HELPER FUNCTIONS---------------------------------------------------------------------------------------HF
function NAT:poll_for_players()
	--am I in raid?
	if UnitInRaid("player") == nil
	then
		return;
	end 
	
	--tanks
	tank_controller.poll_for_players();
	UIDropDownMenu_Initialize(NAT_tank_list, tank_controller.init, "MENU", 2);
	
	--healers 
	healer_controller.poll_for_players();
	UIDropDownMenu_Initialize(NAT_heal_list, healer_controller.init, "MENU", 2);
	
	--interupts
	interrupt_controller.poll_for_players();
	UIDropDownMenu_Initialize(NAT_interrupt_list, interrupt_controller.init, "MENU", 2);
	
	--interupts
	priest_controller.poll_for_players();
	UIDropDownMenu_Initialize(NAT_priest_list, priest_controller.init, "MENU", 2);
	
	--mage
	mage_controller.poll_for_players();
	UIDropDownMenu_Initialize(NAT_mage_list, mage_controller.init, "MENU", 2);
	
	--druid
	druid_controller.poll_for_players();
	UIDropDownMenu_Initialize(NAT_druid_list, druid_controller.init, "MENU", 2);

	--warlock
	warlock_controller.poll_for_players();
	UIDropDownMenu_Initialize(NAT_warlock_list, warlock_controller.init, "MENU", 2);
	
	if current_mode == 1
	then
		tank_controller.update_marks();
	elseif current_mode == 2
	then
		healer_controller.update_marks();
	elseif current_mode == 3
	then
		interrupt_controller.update_marks();
	elseif current_mode == 4
	then
		priest_controller.update_marks();
	elseif current_mode == 5 --mage 
	then
		mage_controller.update_marks();
	elseif current_mode == 6 --druid
	then
		druid_controller.update_marks();
	elseif current_mode == 7 --warlock
	then 
		warlock_controller.update_marks();
	end
end

function NAT:reset_visuals()
	NAT_tank_body:Hide();
	NAT_healer_body:Hide();
	NAT_interrupt_body:Hide();
	NAT_priest_body:Hide();
	NAT_mage_body:Hide();
	NAT_druid_body:Hide();
	NAT_warlock_body:Hide();
	
	for i,button in ipairs(chooser_buttons)
	do
		button:SetPoint("TOPLEFT", NAT, "TOPLEFT",-15,-35-50*(i-1));
	end
end

function NAT:reset_addon()
	--reset healer marks
	tank1_label:SetText("Raid");
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
		healer_controller.update_marks();
	elseif current_mode == 3
	then
		interrupt_controller.update_marks();
	elseif current_mode == 4
	then
		priest_controller.update_marks();
	elseif current_mode == 5
	then
		mage_controller.update_marks();
	elseif current_mode == 6
	then
		druid_controller.update_marks();
	elseif current_mode == 7
	then
		warlock_controller.update_marks();
	end
end
--HELPER FUNCTIONS---------------------------------------------------------------------------------------HF

function NAT:is_ready()
	if network_controller.state == 1
	then
		return true;
	else 
		return false;
	end
end

function NAT:hover_choose_frames(_frame, _dir, _mode) --dir: 1 = left, dir: 2 = right
	local point, relative_to, relative_point, xof, yof = _frame:GetPoint();

	if current_mode ~= _mode
	then
		if _dir == 1
		then
			xof = -38
			_frame:SetPoint(point, relative_to, relative_point, xof, yof);

		else
			xof = -15
			_frame:SetPoint(point, relative_to, relative_point, xof, yof);
		end
	else
		xof = -38
		_frame:SetPoint(point, relative_to, relative_point, xof, yof);
	end
end