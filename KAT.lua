--[[
			@author: moth<milaninavid@gmail.com>
			title: KAT "Kat assignment tool"
			description: TBC tank and healing assignment tool.  
			This can be used too coordinate, display, and adjust 
			assignments quickly and efficiently.
			
			credits: shout out to attreyo on vg for some inspiration.
--]]

--VARIABLES-------------------------------------------------------------------------------------------------------V
local setup_obj = 
function(obj)
	obj.warrior = {};
	obj.paladin = {};
	obj.mage = {};
	obj.shaman = {};
	obj.druid = {};
	obj.warlock = {};
	obj.hunter = {};
	obj.priest = {};
	obj.rogue = {};
end

kat_tanks = {["skull"]={}, ["x"]={}, ["square"]={},["moon"]={},["triangle"]={},["diamond"]={},["circle"]={},["star"]={}};
local healers = {};
local interupters = {}; 
local misc = {};

local available_tanks = {}; setup_obj(available_tanks);
local available_healers = {}; setup_obj(available_healers);
local available_interupters = {}; setup_obj(available_interupters);
local available_misc = {}; setup_obj(available_misc);

--what selection mode im in
	--1: tanks
	--2: healers
	--3: interupters
	--4: misc
local current_mode = 1; 

--currented focus
current_focus_mark = "";

local kat_assignment_labels = nil;

--VARIABLES-------------------------------------------------------------------------------------------------------V

function KAT_handle_events(self, event, ...)
	if event == "RAID_ROSTER_UPDATE" 
	then 
		KAT_poll_for_players();
	end
end

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

--update the text that reflects changes to current mode
function KAT_update_mark_text()
	--lazy instantiate labels (just in case user doesn't end up using addon rn)
	if kat_assignment_labels == nil
	then
		kat_assignment_labels = {};
		local create_label =
		function()
			local guiString = KAT:CreateFontString("text_label"..table.getn(kat_assignment_labels),"OVERLAY","GameFontNormal");
			guiString:SetText("If you see this, something broke with text assignments");
			guiString:SetPoint("TOP",  0,  -table.getn(kat_assignment_labels)*40-45);
			return guiString;
		end
		
		for i=1, 8, 1
		do
			table.insert(kat_assignment_labels, create_label());
		end 
	end

	--tanks
	if current_mode == 1
	then
		--set text to selected tanks
		local key = 1;
		for mark, mark_list in pairs(kat_tanks)
		do
			local text = " ";
			for index, tank in ipairs(kat_tanks[mark])
			do
				text = text .. tank .. "    ";
			end

			kat_assignment_labels[key]:SetText(text);
			key = key + 1;
		end
		
	end
end

function KAT_post()
	--tanks
	SendChatMessage(" -- Tank Assignments --", "RAID", nil);
	for mark, mark_list in pairs(kat_tanks)
	do
		if table.getn(mark_list) > 0
		then
			local tank_list = "";
			for index, tank in ipairs(kat_tanks[mark])
			do
				tank_list = tank_list .. tank .. " ";
			end
			
			if mark == "x"
			then
				mark = "Cross";
			end
			
			SendChatMessage("{"..mark.."}: " ..tank_list, "RAID", nil);
		end
	end
	
end

--show submenu when mousing over current marks
function KAT_show_tanks(parent, focus_mark)
	current_focus_mark = focus_mark;
	ToggleDropDownMenu(nil, 1, KAT_tank_list, parent, 0, 0);
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


--function to setup tank list
function KAT_init_tank_list(self)
	--create layer 2 information
	local create_sub_info =  
	function(name, i)
		local info = {};
	   info.hasArrow = false; -- no submenus this time
	   info.text = name;
	   info.value = {UIDROPDOWNMENU_MENU_VALUE, i};
	   info.func = 
	   function() 
			--UIDropDownMenu_SetSelectedName(KAT_tank_list, info.text); 
			--Am I in the list already? note: func call above doesn't care about that
			for entry, list_name in ipairs(kat_tanks[current_focus_mark])
			do
				if info.text == list_name
				then
					table.remove(kat_tanks[current_focus_mark], entry);
					KAT_update_mark_text();
					return;
				end
			end
			
			--add to list
			table.insert(kat_tanks[current_focus_mark], info.text);
			KAT_update_mark_text();
		end
		
		return info;
	end

	if UIDROPDOWNMENU_MENU_LEVEL== 1
	then
		local warriors = {};
		warriors.text = "|cffC79C6EWarrior";
		warriors.value = 1;
		warriors.hasArrow = true;
		warriors.func = function() end;
		
		if table.getn(available_tanks.warrior) == 0
		then
			warriors.disabled = true;
			warriors.hasArrow = false;
			warriors.text = "|cff545454Warrior";
		else
			local list ={};
			for i, war_name in ipairs(available_tanks.warrior)
			do
			   table.insert(list, war_name)
			end
			warriors.menuList = list;
		end
		
		local druids = {};
		druids.text = "|cffFF7D0ADruid";
		druids.value = 2;
		druids.hasArrow = true;
		druids.func = function()  end;
		
		if table.getn(available_tanks.druid) == 0
		then
			druids.disabled = true;
			druids.hasArrow = false;
			druids.text = "|cff545454Druid";
		end
		
		local paladins = {};
		paladins.text = "|cffF58CBAPaladin";
		paladins.value = 3;
		paladins.hasArrow = true;
		paladins.func = function()  end;
		
		if table.getn(available_tanks.paladin) == 0
		then
			paladins.disabled = true;
			paladins.hasArrow = false;
			paladins.text = "|cff545454Paladin";
		end
		
		local mage = {};
		mage.text = "|cff69CCF0Mage";
		mage.value = 4;
		mage.hasArrow = true;
		mage.func = function()  end;
		
		if table.getn(available_tanks.mage) == 0
		then
			mage.disabled = true;
			mage.hasArrow = false;
			mage.text = "|cff545454Mage";
		end
		
		local hunter = {};
		hunter.text = "|cffABD473Hunter";
		hunter.value = 5;
		hunter.hasArrow = true;
		hunter.func = function()  end;
		
		if table.getn(available_tanks.hunter) == 0
		then
			hunter.disabled = true;
			hunter.hasArrow = false;
			hunter.text = "|cff545454Hunter";
		end
		
		local warlock = {};
		warlock.text = "|cff9482C9Warlock";
		warlock.value = 6;
		warlock.hasArrow = true;
		warlock.func = function()  end;
		
		if table.getn(available_tanks.warlock) == 0
		then
			warlock.disabled = true;
			warlock.hasArrow = false;
			warlock.text = "|cff545454Warlock";
		end
		
		UIDropDownMenu_AddButton(warriors, 1);
		UIDropDownMenu_AddButton(druids, 1);
		UIDropDownMenu_AddButton(paladins, 1);
		UIDropDownMenu_AddButton(mage, 1);
		UIDropDownMenu_AddButton(hunter, 1);
		UIDropDownMenu_AddButton(warlock, 1);
	elseif UIDROPDOWNMENU_MENU_LEVEL == 2
	then
		if UIDROPDOWNMENU_MENU_VALUE == 1 -- warriors
		then
			for i, name in ipairs(available_tanks.warrior)
			do
			   UIDropDownMenu_AddButton(create_sub_info(name,i), 2);
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 2 --druids
		then
			for i, name in ipairs(available_tanks.druid)
			do
				UIDropDownMenu_AddButton(create_sub_info(name,i), 2);
			end
		elseif UIDROPDOWNMENU_MENU_VALUE== 3 --paladins
		then
			for i, name in ipairs(available_tanks.paladin)
			do
				UIDropDownMenu_AddButton(create_sub_info(name,i), 2);
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 4 --mage 
		then
			for i, name in ipairs(available_tanks.mage)
			do
				UIDropDownMenu_AddButton(create_sub_info(name,i), 2);
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 5 --hunter
		then
			for i, name in ipairs(available_tanks.hunter)
			do
				UIDropDownMenu_AddButton(create_sub_info(name,i), 2);
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 6 --lock
		then
			for i, name in ipairs(available_tanks.warlock)
			do
				UIDropDownMenu_AddButton(create_sub_info(name,i), 2);
			end
		end
	end
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
	--reset available 
	setup_obj(available_tanks);
	setup_obj(available_healers);
	setup_obj(available_interupters);
	setup_obj(available_misc);
	
	--am I in raid?
	if UnitInRaid("player") == nil
	then
		return;
	end 
	
	--lets see what we got in the raid
	local i = 1;
	for i=1, GetNumRaidMembers(), 1
	do
		local pname = UnitName("raid"..i);
		local class, classFileName = UnitClass("raid"..i);

		if class == "Warrior"
		then
			table.insert(available_tanks.warrior, pname);
			table.insert(available_misc.warrior, pname);
			table.insert(available_interupters.warrior, pname);
		elseif class == "Rogue"
		then
			table.insert(available_tanks.rogue, pname);
			table.insert(available_misc.rogue, pname);
			table.insert(available_interupters.rogue, pname);
		elseif class == "Shaman"
		then
			table.insert(available_healers.shaman, pname);
			table.insert(available_misc.shaman, pname);
			table.insert(available_interupters.shaman, pname);
		elseif class == "Druid"
		then
			table.insert(available_healers.druid, pname);
			table.insert(available_misc.druid, pname);
			table.insert(available_tanks.druid, pname);
		elseif class == "Priest"
		then
			table.insert(available_tanks.priest,pname)
			table.insert(available_healers.priest, pname);
			table.insert(available_misc.priest, pname);
		elseif class == "Paladin"
		then
			table.insert(available_tanks.paladin, pname);
			table.insert(available_healers.paladin, pname);
			table.insert(available_misc.paladin, pname);
		elseif class == "Hunter"
		then
			table.insert(available_tanks.hunter, pname);
			table.insert(available_misc.hunter, pname);
		elseif class == "Mage"
		then
			table.insert(available_tanks.mage, pname);
			table.insert(available_misc.mage, pname);
			table.insert(available_interupters.mage, pname);
		elseif class == "Warlock"
		then
			table.insert(available_tanks.warlock, pname);
			table.insert(available_misc.warlock, pname);
		end
		
	end
	
	UIDropDownMenu_Initialize(KAT_tank_list, KAT_init_tank_list, "MENU", 2);
end
--HELPER FUNCTIONS---------------------------------------------------------------------------------------HF
