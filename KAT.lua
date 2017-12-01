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

local tanks = {["skull"]={}, ["x"]={}, ["square"]={},["moon"]={},["triangle"]={},["diamond"]={},["circle"]={},["star"]={}};
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
end

--show submenu when mousing over current tanks
function KAT_show_healers()

end

--show submenu when mousing over current marks
function KAT_show_tanks(parent)
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
		
		UIDropDownMenu_AddButton(warriors, 1);
		UIDropDownMenu_AddButton(druids, 1);
		UIDropDownMenu_AddButton(paladins, 1);
		UIDropDownMenu_AddButton(mage, 1);
		UIDropDownMenu_AddButton(hunter, 1);
	elseif UIDROPDOWNMENU_MENU_LEVEL == 2
	then
		if UIDROPDOWNMENU_MENU_VALUE == 1 -- warriors
		then
			for i, war_name in ipairs(available_tanks.warrior)
			do
				local war = UIDropDownMenu_CreateInfo();
			   war.hasArrow = false; -- no submenus this time
			   war.text = war_name;
			   war.value = {UIDROPDOWNMENU_MENU_VALUE, i};
			   war.func = function() end;
			   
			   UIDropDownMenu_AddButton(war, 2);
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 2 --druids
		then
		elseif UIDROPDOWNMENU_MENU_VALUE== 3 --paladins
		then
		elseif UIDROPDOWNMENU_MENU_VALUE == 4 --mage 
		then
		elseif UIDROPDOWNMENU_MENU_VALUE == 5 --hunter
		then

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
