KAT_create_tank_menu_controller = 
function()
	controller = {};

	--VARIABLES-------------------------------------------------------------------------------------------------------V
	controller.setup_classes = function(obj)
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

	controller.assigned_tanks = {["skull"]={}, ["x"]={}, ["square"]={},["moon"]={},["triangle"]={},["diamond"]={},["circle"]={},["star"]={}};
	controller.marks = {"skull", "x", "square", "moon", "triangle", "diamond", "circle", "star"};
	controller.available_tanks = {}; controller.setup_classes (controller.available_tanks);

	--currented focus
	controller.current_focus_mark = "";
	controller.current_menu_parent = nil;
	controller.kat_assignment_labels = nil;

	--VARIABLES-------------------------------------------------------------------------------------------------------V

	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	--function to setup tank list
	controller.init =
	function(self)
		UIDROPDOWNMENU_SHOW_TIME  = 0;

		--create layer 2 information
		local create_sub_info =  
		function(name, color)
			local info = {};
		   info.hasArrow = false; -- no submenus this time
		   info.text = color..name;
		   info.value =  name;
		   info.func = 
		   function() 
				--UIDropDownMenu_SetSelectedName(KAT_tank_list, info.text); 
				--Am I in the list already? 
				for entry, list_name in ipairs(controller.assigned_tanks[controller.current_focus_mark])
				do
					if info.text == list_name
					then
						--remove from list
						table.remove(controller.assigned_tanks[controller.current_focus_mark], entry);
						controller.update_marks();
						
						return;
					end
				end
				
				--add to list
				table.insert(controller.assigned_tanks[controller.current_focus_mark], info.text);
				controller.update_marks();
				
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
			
			if table.getn(controller.available_tanks.warrior) == 0
			then
				warriors.disabled = true;
				warriors.hasArrow = false;
				warriors.text = "|cff545454Warrior";
			end
			
			local druids = {};
			druids.text = "|cffFF7D0ADruid";
			druids.value = 2;
			druids.hasArrow = true;
			druids.func = function()  end;
			
			if table.getn(controller.available_tanks.druid) == 0
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
			
			if table.getn(controller.available_tanks.paladin) == 0
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
			
			if table.getn(controller.available_tanks.mage) == 0
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
			
			if table.getn(controller.available_tanks.hunter) == 0
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
			
			if table.getn(controller.available_tanks.warlock) == 0
			then
				warlock.disabled = true;
				warlock.hasArrow = false;
				warlock.text = "|cff545454Warlock";
			end
			
			local priest= {};
			priest.text = "|cffFFFFFFPriest";
			priest.value = 7;
			priest.hasArrow = true;
			priest.func = function()  end;
			
			if table.getn(controller.available_tanks.priest) == 0
			then
				priest.disabled = true;
				priest.hasArrow = false;
				priest.text = "|cff545454Priest";
			end
			
			local rogue= {};
			rogue.text = "|cffFFF569Rogue";
			rogue.value = 8;
			rogue.hasArrow = true;
			rogue.func = function()  end;
			
			if table.getn(controller.available_tanks.rogue) == 0
			then
				rogue.disabled = true;
				rogue.hasArrow = false;
				rogue.text = "|cff545454Rogue";
			end
			
			UIDropDownMenu_AddButton(warriors, 1);
			UIDropDownMenu_AddButton(druids, 1);
			UIDropDownMenu_AddButton(paladins, 1);
			UIDropDownMenu_AddButton(mage, 1);
			UIDropDownMenu_AddButton(hunter, 1);
			UIDropDownMenu_AddButton(warlock, 1);
			UIDropDownMenu_AddButton(priest, 1);
			UIDropDownMenu_AddButton(rogue, 1);
		elseif UIDROPDOWNMENU_MENU_LEVEL == 2
		then
			if UIDROPDOWNMENU_MENU_VALUE == 1 -- warriors
			then
				for i, name in ipairs(controller.available_tanks.warrior)
				do
				   UIDropDownMenu_AddButton(create_sub_info(name,"|cffC79C6E"), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 2 --druids
			then
				for i, name in ipairs(controller.available_tanks.druid)
				do
					UIDropDownMenu_AddButton(create_sub_info(name,"|cffFF7D0A"), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE== 3 --paladins
			then
				for i, name in ipairs(controller.available_tanks.paladin)
				do
					UIDropDownMenu_AddButton(create_sub_info(name, "|cffF58CBA"), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 4 --mage 
			then
				for i, name in ipairs(controller.available_tanks.mage)
				do
					UIDropDownMenu_AddButton(create_sub_info(name, "|cff69CCF0"), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 5 --hunter
			then
				for i, name in ipairs(controller.available_tanks.hunter)
				do
					UIDropDownMenu_AddButton(create_sub_info(name, "|cffABD473"), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 6 --lock
			then
				for i, name in ipairs(controller.available_tanks.warlock)
				do
					UIDropDownMenu_AddButton(create_sub_info(name,"|cff9482C9"), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 7 --priest
			then
				for i, name in ipairs(controller.available_tanks.priest)
				do
					UIDropDownMenu_AddButton(create_sub_info(name,"|cffFFFFFF"), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 8 --rogue
			then
				for i, name in ipairs(controller.available_tanks.rogue)
				do
					UIDropDownMenu_AddButton(create_sub_info(name,"|cffFFF569"), 2);
				end
			end
		end
	end

	--populate available tank list
	controller.poll_for_tanks =
	function()
		--reset current list
		controller.setup_classes(controller.available_tanks);

		--lets see what we got in the raid
		local i = 1;
		for i=1, GetNumRaidMembers(), 1
		do
			local pname = UnitName("raid"..i);
			local class, classFileName = UnitClass("raid"..i);

			if class == "Warrior"
			then
				table.insert(controller.available_tanks.warrior, pname);
			elseif class == "Rogue"
			then
				table.insert(controller.available_tanks.rogue, pname);
			elseif class == "Druid"
			then
				table.insert(controller.available_tanks.druid, pname);
			elseif class == "Priest"
			then
				table.insert(controller.available_tanks.priest,pname)
			elseif class == "Paladin"
			then
				table.insert(controller.available_tanks.paladin, pname);
			elseif class == "Hunter"
			then
				table.insert(controller.available_tanks.hunter, pname);
			elseif class == "Mage"
			then
				table.insert(controller.available_tanks.mage, pname);
			elseif class == "Warlock"
			then
				table.insert(controller.available_tanks.warlock, pname);
			end
			
		end
	end

	controller.update_marks =
	function()
		--lazy instantiate labels (just in case user doesn't end up using addon rn)
		if kat_assignment_labels == nil
		then
			kat_assignment_labels = {};
			local create_label =
			function()
				local guiString = KAT:CreateFontString("text_label"..table.getn(kat_assignment_labels),"OVERLAY","GameFontNormal");
				guiString:SetText("If you see this, something broke with text assignments");
				guiString:SetPoint("TOP",  25,  -table.getn(kat_assignment_labels)*40-45);
				return guiString;
			end
			
			for i=1, 8, 1
			do
				table.insert(kat_assignment_labels, create_label());
			end 
		end

		--set text to selected tanks
		local key = 1;
		for _, mark in ipairs(controller.marks)
		do
			local text = " ";
			for index, tank in ipairs(controller.assigned_tanks[mark])
			do
				text = text .. tank .. "  ";
			end

			kat_assignment_labels[key]:SetText(text);
			key = key + 1;
		end
	end 

	controller.post = 
	function()
		SendChatMessage(" -- Tank Assignments --", "RAID", nil);
		for _, mark in ipairs(controller.marks)
		do
			if table.getn(controller.assigned_tanks[mark]) > 0
			then
				local tank_list = "";
				for index, tank in ipairs(controller.assigned_tanks[mark])
				do
					--if there was color applied. shitty server doesn't allow colored text in chat
					if strlen(tank) > 10
					then
						tank = strsub(tank, 11, strlen(tank));
					end
				
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
	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	
	return controller;
end 