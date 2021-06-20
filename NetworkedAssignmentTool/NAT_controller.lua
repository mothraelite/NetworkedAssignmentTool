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

--[[
    current bugs:
        1) race condition for master
        2) current assignments not being transmitted/received correctly so it acts like its never set up
            a: check 9.0 send calls
            b: check and verify 
        3) event for joining raid not working, should ask for setup or setup if none vail
--]]

--xml references for easy access
local NAT = {};
NAT.subframes = {};
NAT.chooser_buttons = {};
NAT.subviews = {};

--what selection mode im in
	--1: tanks
	--2: healers
	--3: interrupters
local current_mode = 1; 

function NAT_init(_frame)
	--set reference frame
	NAT.frame = _frame;
	
	--retrieve subframes as references
	for i, cframe in ipairs({_frame:GetChildren()})
	do
		NAT.subframes[cframe:GetName()] = cframe;
		for _,ssframe in ipairs({cframe:GetChildren()})
		do
			NAT.subframes[ssframe:GetName()] = ssframe;
		end
	end
	
	--Setting up quick sub references
	table.insert(NAT.subviews, NAT.subframes["NAT_tank_body"] )
	table.insert(NAT.subviews, NAT.subframes["NAT_healer_body"] );
	table.insert(NAT.subviews, NAT.subframes["NAT_interrupt_body"] ) ;
	table.insert(NAT.subviews, NAT.subframes["NAT_priest_body"] );
	table.insert(NAT.subviews, NAT.subframes["NAT_mage_body"] ) ;
	table.insert(NAT.subviews, NAT.subframes["NAT_druid_body"] );
	table.insert(NAT.subviews, NAT.subframes["NAT_warlock_body"] );
	
	table.insert(NAT.chooser_buttons, NAT.subframes["NAT_choose_tank_menu"] )
	table.insert(NAT.chooser_buttons, NAT.subframes["NAT_choose_healer_menu"] );
	table.insert(NAT.chooser_buttons, NAT.subframes["NAT_choose_interrupt_menu"] ) ;
	table.insert(NAT.chooser_buttons, NAT.subframes["NAT_choose_priest_menu"] );
	table.insert(NAT.chooser_buttons, NAT.subframes["NAT_choose_mage_menu"] ) ;
	table.insert(NAT.chooser_buttons, NAT.subframes["NAT_choose_druid_menu"] );
	table.insert(NAT.chooser_buttons, NAT.subframes["NAT_choose_warlock_menu"] );

	--setup reg functions
	NAT.frame:RegisterForDrag("LeftButton");
	NAT.frame:RegisterEvent("GROUP_ROSTER_UPDATE"); --fires on personal promotion, personal demotion, anyone joining raid, anyone leaving raid
	NAT.frame:RegisterEvent("RAID_TARGET_UPDATE"); --unfortunately, no response that indicates what was changed. probably going to notify all assigned tanks that things have changed though.
	NAT.frame:RegisterEvent("CHAT_MSG_ADDON");
    NAT.frame:RegisterEvent("GROUP_JOINED");
    
    C_ChatInfo.RegisterAddonMessagePrefix("NAT");
	
	--setup controllers
	local tank_layers = {NAT.subframes["NAT_tank_body"]:GetRegions()} --retreive layered elemental like fonts etc
	tank_controller = NAT_create_tank_menu_controller(NAT.subframes["NATTankPostChannelEdit"],  tank_layers[2],NAT.subframes["NAT_tank_body"]); 
	
	local healer_layers = {NAT.subframes["NAT_healer_body"]:GetRegions()}
	local healer_assignment_labels = {};
	for i = 1, 9, 1
	do
		table.insert(healer_assignment_labels, NAT.subframes["tank"..i]:GetRegions());
	end
	
	healer_controller = NAT_create_healer_menu_controller(NAT.subframes["NATHealerPostChannelEdit"], healer_layers[2], NAT.subframes["NAT_healer_body"], healer_assignment_labels); 
	table.insert(tank_controller.observers, healer_controller); --add healer controller to tank observer list
	
	local interrupt_layers = {NAT.subframes["NAT_interrupt_body"]:GetRegions()}
	interrupt_controller = NAT_create_interrupt_menu_controller(NAT.subframes["NATInterruptPostChannelEdit"], interrupt_layers[2], NAT.subframes["NAT_interrupt_body"]);
	
	local priest_layers = {NAT.subframes["NAT_priest_body"]:GetRegions()} --retreive layered elemental like fonts etc
	priest_controller = NAT_create_priest_menu_controller(NAT.subframes["NATPriestPostChannelEdit"], priest_layers[2], NAT.subframes["NAT_priest_body"]);
	
	local mage_layers = {NAT.subframes["NAT_mage_body"]:GetRegions()} --retreive layered elemental like fonts etc
	mage_controller = NAT_create_mage_menu_controller(NAT.subframes["NATMagePostChannelEdit"], mage_layers[2], NAT.subframes["NAT_mage_body"]);
	
	local druid_layers = {NAT.subframes["NAT_druid_body"]:GetRegions()} --retreive layered elemental like fonts etc
	druid_controller = NAT_create_druid_menu_controller(NAT.subframes["NATDruidPostChannelEdit"], druid_layers[2], NAT.subframes["NAT_druid_body"]);
	
	local warlock_layers = {NAT.subframes["NAT_warlock_body"]:GetRegions()} --retreive layered elemental like fonts etc
	warlock_controller = NAT_create_warlock_menu_controller(NAT.subframes["NATWarlockPostChannelEdit"], warlock_layers[2], NAT.subframes["NAT_warlock_body"]);
	
	network_controller = NAT_create_network_handler(tank_controller, healer_controller, interrupt_controller, priest_controller, mage_controller, druid_controller, warlock_controller);

	--get initial list of raid mems
	NAT_poll_for_players();

	--See if someone is in the raid that is running the addon
	network_controller.request_setup();
		
	-- Slash commands
	SlashCmdList["NATCOMMAND"] = NAT_slashCommandHandler;
	SLASH_NATCOMMAND1 = "/NAT";

	--Init handler
	DEFAULT_CHAT_FRAME:AddMessage("NAT: Initializing NAT version 1.a", 0.6,1.0,0.6);
end

function NAT_request_master()
	if not UnitIsGroupLeader("player") and not UnitIsGroupAssistant("player")
	then
		DEFAULT_CHAT_FRAME:AddMessage("NAT: You need to be the raid leader or have assist to request master status.", 0.6,1.0,0.6);
		return;
	end

	network_controller.request_master();
end

function NAT_handle_events(event, ...)
	if event == "GROUP_ROSTER_UPDATE"  or event == "GROUP_JOINED"
	then
		--if im not setup yet, request a setup or become master
		if network_controller.state == -1
		then
			network_controller.request_setup();
		else
		--I lost pre-req for master status so check if I am the master
			if network_controller.master == UnitName("player") and not UnitIsGroupAssistant("player") and not UnitIsGroupLeader("player")
			then
				--I was master, relinquish title.
				network_controller.request_new_master();
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
		local args = {...};
		if args[1] == "NAT"
		then
			local command, message, sender = network_controller.extract_command_and_message(args[2]);
			
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
function NAT_update(self, elapsed)
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

function NAT_slashCommandHandler(msg)
	local msg_split = NAT_split(msg, " ");
	command = msg_split[1];

	if command == "show"
	then
		NAT.frame:Show();
	elseif command == "hide"
	then
		NAT.frame:Hide();
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
	local ypos = -35-50*(index-1);
	
	--select visuals
	if index == 1 --tank
	then
		--show tank visuals
		NAT.subframes["NAT_tank_body"]:Show();
		tank_controller.update_marks();
		NAT.subframes["NAT_choose_tank_menu"]:SetPoint("TOPLEFT", NAT.frame, "TOPLEFT", -38, ypos);
		NAT.subframes["NATTitleLabelContainer"]:GetRegions():SetText("Tank Assignments");
		current_mode = 1;
	elseif index == 2 --heals
	then
		NAT_healer_body:Show();
		healer_controller.update_marks();
		NAT.subframes["NAT_choose_healer_menu"]:SetPoint("TOPLEFT", NAT.frame, "TOPLEFT", -38, ypos);
		NAT.subframes["NATTitleLabelContainer"]:GetRegions():SetText("Healer Assignments");
		current_mode = 2;
	elseif index == 3 --interrupt
	then
		--show interrupt visuals
		NAT_interrupt_body:Show();
		interrupt_controller.update_marks();
		NAT.subframes["NAT_choose_interrupt_menu"]:SetPoint("TOPLEFT", NAT.frame, "TOPLEFT",  -38, ypos);
		NAT.subframes["NATTitleLabelContainer"]:GetRegions():SetText("Interrupt Assignments");
		current_mode = 3;
	elseif index == 4 --priest
	then
		--show priest visuals
		NAT_priest_body:Show();
		priest_controller.update_marks();
		NAT.subframes["NAT_choose_priest_menu"]:SetPoint("TOPLEFT", NAT.frame, "TOPLEFT",  -38, ypos);
		NAT.subframes["NATTitleLabelContainer"]:GetRegions():SetText("Priest Assignments");
		current_mode = 4;
	elseif index == 5 --mage
	then
		--show interrupt visuals
		NAT_mage_body:Show();
		mage_controller.update_marks();
		NAT.subframes["NAT_choose_mage_menu"]:SetPoint("TOPLEFT", NAT.frame, "TOPLEFT",  -38, ypos);
		NAT.subframes["NATTitleLabelContainer"]:GetRegions():SetText("Mage Assignments");
		current_mode = 5;
	elseif index == 6 --druid
	then
		--show interrupt visuals
		NAT_druid_body:Show();
		druid_controller.update_marks();
		NAT.subframes["NAT_choose_druid_menu"]:SetPoint("TOPLEFT", NAT.frame, "TOPLEFT",  -38, ypos);
		NAT.subframes["NATTitleLabelContainer"]:GetRegions():SetText("Druid Assignments");
		current_mode = 6;
	elseif index == 7 --warlock
	then
		--show interrupt visuals
		NAT_warlock_body:Show();
		warlock_controller.update_marks();
		NAT.subframes["NAT_choose_warlock_menu"]:SetPoint("TOPLEFT", NAT.frame, "TOPLEFT",  -38, ypos);
		NAT.subframes["NATTitleLabelContainer"]:GetRegions():SetText("Warlock Assignments");
		current_mode = 7;
	end 
end

function NAT_request_setup()
	--network_controller.request_setup();
end

function NAT_post()
	if not UnitIsGroupLeader("player") and not UnitIsGroupAssistant("player")
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

function NAT_post_all()
	if not UnitIsGroupLeader("player") and not UnitIsGroupAssistant("player")
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
function NAT_show_listmenu(parent, focus_mark)
	if current_mode == 1
	then
		tank_controller.current_focus_mark = focus_mark;
		tank_controller.current_menu_parent = parent;
		ToggleDropDownMenu(nil, 1, NAT.subframes["NAT_tank_list"], parent, 0, 25);
	elseif current_mode == 2
	then
		if focus_mark == "" or focus_mark == nil
		then
			return;
		end
	
		healer_controller.current_focus_mark = focus_mark;
		healer_controller.current_menu_parent = parent;
		ToggleDropDownMenu(nil,1,NAT.subframes["NAT_heal_list"], parent, 0, 25);
	elseif current_mode == 3
	then
		interrupt_controller.current_focus_mark = focus_mark;
		interrupt_controller.current_menu_parent = parent;
		ToggleDropDownMenu(nil,1,NAT.subframes["NAT_interrupt_list"],parent,0,25);
	elseif current_mode == 4
	then
		priest_controller.current_focus_mark = focus_mark;
		priest_controller.current_menu_parent = parent;
		ToggleDropDownMenu(nil, 1, NAT.subframes["NAT_priest_list"], parent, 0, 25);
	elseif current_mode == 5
	then 
		mage_controller.current_focus_mark = focus_mark;
		mage_controller.current_menu_parent = parent;
		ToggleDropDownMenu(nil, 1, NAT.subframes["NAT_mage_list"], parent, 0, 25);
	elseif current_mode == 6
	then 
		druid_controller.current_focus_mark = focus_mark;
		druid_controller.current_menu_parent = parent;
		ToggleDropDownMenu(nil, 1, NAT.subframes["NAT_druid_list"], parent, 0, 25);
	elseif current_mode == 7
	then
		warlock_controller.current_focus_mark = focus_mark;
		warlock_controller.current_menu_parent = parent;
		ToggleDropDownMenu(nil, 1, NAT.subframes["NAT_warlock_list"], parent, 0, 25);
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
	elseif current_mode == 4
	then
		priest_controller.set_post_location(self:GetText());
	elseif current_mode == 5
	then
		mage_controller.set_post_location(self:GetText());
	elseif current_mode == 6
	then
		druid_controller.set_post_location(self:GetText());
	elseif current_mode == 7
	then
		warlock_controller.set_post_location(self:GetText());
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
	tank_controller.poll_for_players();
	UIDropDownMenu_Initialize(NAT.subframes["NAT_tank_list"], tank_controller.init, "MENU", 2);
	
	--healers 
	healer_controller.poll_for_players();
	UIDropDownMenu_Initialize(NAT.subframes["NAT_heal_list"], healer_controller.init, "MENU", 2);
	
	--interupts
	interrupt_controller.poll_for_players();
	UIDropDownMenu_Initialize(NAT.subframes["NAT_interrupt_list"], interrupt_controller.init, "MENU", 2);
	
	--interupts
	priest_controller.poll_for_players();
	UIDropDownMenu_Initialize(NAT.subframes["NAT_priest_list"], priest_controller.init, "MENU", 2);
	
	--mage
	mage_controller.poll_for_players();
	UIDropDownMenu_Initialize(NAT.subframes["NAT_mage_list"], mage_controller.init, "MENU", 2);
	
	--druid
	druid_controller.poll_for_players();
	UIDropDownMenu_Initialize(NAT.subframes["NAT_druid_list"], druid_controller.init, "MENU", 2);

	--warlock
	warlock_controller.poll_for_players();
	UIDropDownMenu_Initialize(NAT.subframes["NAT_warlock_list"], warlock_controller.init, "MENU", 2);
	
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

function NAT_reset_visuals()
	for i, _frame in ipairs(NAT.subviews)
	do
		_frame:Hide();
	end
	
	for i,button in ipairs(NAT.chooser_buttons)
	do
		button:SetPoint("TOPLEFT", NAT.frame, "TOPLEFT",-25,-35-50*(i-1));
	end
end

function NAT_reset_addon()
	--reset healer marks
	healer_controller.reset_visual_marks();
	
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

function NAT_add_reference_object(_object)
	NAT.subframes[_object:GetName()] =_object;
end

function NAT_is_ready()
	if network_controller.state == 1
	then
		return true;
	else 
		return false;
	end
end

function NAT_hover_choose_frames(_frame, _dir, _mode) --dir: 1 = left, dir: 2 = right
	local point, relative_to, relative_point, xof, yof = _frame:GetPoint();

	if current_mode ~= _mode
	then
		if _dir == 1
		then
			xof = -38
			_frame:SetPoint(point, relative_to, relative_point, xof, yof);

		else
			xof = -25
			_frame:SetPoint(point, relative_to, relative_point, xof, yof);
		end
	else
		xof = -38
		_frame:SetPoint(point, relative_to, relative_point, xof, yof);
	end
end