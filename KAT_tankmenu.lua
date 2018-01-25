KAT_create_tank_menu_controller = 
function()
	local controller = {};

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
	controller.observers = {};

	--currented focus
	controller.current_focus_mark = "";
	controller.current_menu_parent = nil;

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
				--check if addon is ready 
				if not KAT_is_ready()
				then 
					DEFAULT_CHAT_FRAME:AddMessage("KAT: You are not setup yet. Wait for the go ahead or try to setup again. (Master might be offline)", 0.6,1.0,0.6);
					return;
				end
		   
				--check if i have permission to make changes
				if not IsRaidLeader() and not IsRaidOfficer()
				then
					--no permission, exit
					DEFAULT_CHAT_FRAME:AddMessage("KAT: You need to be the raid leader OR have assist to make changes", 0.6,1.0,0.6);
					return;
				end

				--Am I in the list already? 
				for entry, list_name in ipairs(controller.assigned_tanks[controller.current_focus_mark])
				do
					if info.text == list_name
					then
						--remove from list
						table.remove(controller.assigned_tanks[controller.current_focus_mark], entry);
						controller.update_marks();
						
						--see if he is still assigned elsewhere
						local tank_found = false;
						for _,mark in pairs(controller.marks)
						do
							for i=1, table.getn(controller.assigned_tanks[mark]), 1
							do
								if controller.assigned_tanks[mark][i]== info.text
								then
									tank_found = true;
									break;
								end
							end
							
							if tank_found == true
							then
								break;
							end
						end
						
						--tank not found, remove from assigned list for healers
						if tank_found == false
						then
							controller.notify_observers("remove_tank", {info.text});
							SendAddonMessage("KAT", "toggle_tank-"..controller.current_focus_mark..":"..info.text.."-"..UnitName("player"), "RAID")
						end
						
						return;
					end
				end
				
				--add to list
				table.insert(controller.assigned_tanks[controller.current_focus_mark], info.text);
				controller.notify_observers("add_tank", {info.text});
				SendAddonMessage("KAT", "toggle_tank-"..controller.current_focus_mark..":"..info.text.."-"..UnitName("player"), "RAID")
				controller.update_marks();
			end
			
			return info;
		end

		if UIDROPDOWNMENU_MENU_LEVEL== 1
		then
			local title = {};
			title.text = "Tanks"
			title.isTitle = true;
		
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
			
			UIDropDownMenu_AddButton(title,1);
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
			local title = {};
			title.text = "Players"
			title.isTitle = true;
			UIDropDownMenu_AddButton(title, 2);
		
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

		--setup available tanks
		local i =1;
		local temp_avail_tanks = {};
		for i=1, GetNumRaidMembers(), 1
		do
			local pname = UnitName("raid"..i);
			local class, classFileName = UnitClass("raid"..i);

			if class == "Warrior"
			then
				table.insert(controller.available_tanks.warrior, pname);
				table.insert(temp_avail_tanks, pname);
			elseif class == "Rogue"
			then
				table.insert(controller.available_tanks.rogue, pname);
				table.insert(temp_avail_tanks, pname);
			elseif class == "Druid"
			then
				table.insert(controller.available_tanks.druid, pname);
				table.insert(temp_avail_tanks, pname);
			elseif class == "Priest"
			then
				table.insert(controller.available_tanks.priest,pname)
				table.insert(temp_avail_tanks, pname);
			elseif class == "Paladin"
			then
				table.insert(controller.available_tanks.paladin, pname);
				table.insert(temp_avail_tanks, pname);
			elseif class == "Hunter"
			then
				table.insert(controller.available_tanks.hunter, pname);
				table.insert(temp_avail_tanks, pname);
			elseif class == "Mage"
			then
				table.insert(controller.available_tanks.mage, pname);
				table.insert(temp_avail_tanks, pname);
			elseif class == "Warlock"
			then
				table.insert(controller.available_tanks.warlock, pname);
				table.insert(temp_avail_tanks, pname);
			end
			
		end
		
		--see if any assigned tank is no longer available
		local current_tanks = controller.get_current_unique_players();
		local tanks_to_remove = {};
		
		--check current tanks vs available tanks
		for _,current_tank in ipairs(current_tanks)
		do
			local tfound = false;
			local unprefix_current_tank = strsub(current_tank, 11, strlen(current_tank));
			for _,avail_tank in ipairs(temp_avail_tanks)
			do
				if avail_tank == unprefix_current_tank
				then 
					tfound = true;
					break;
				end
			end 
			
			--not found, mark for removal
			if tfound == false
			then
				table.insert(tanks_to_remove, current_tank);
			end 
			
		end
		
		for _, tank_to_remove in ipairs(tanks_to_remove)
		do
			--remove all traces of tanks marked for removal from our controller's model list
			local prefix_tank = "";
			for _, mark in ipairs(controller.marks)
			do
				for i=1, table.getn(controller.assigned_tanks[mark]), 1
				do
					--attempting to find tank among assignments
					if controller.assigned_tanks[mark][i] == tank_to_remove
					then
						table.remove(controller.assigned_tanks[mark], i); --remove tank from assignment
						break;
					end
				end 
			end
			
			--inform observers that we removed a tank
			controller.notify_observers("remove_tank", {tank_to_remove});
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
	
	controller.reset
	=
	function()
		--reset current assignments 
		for _, mark in ipairs(controller.marks)
		do
			controller.assigned_tanks[mark] = {};
		end
	end 
	
	--get list of assigned tanks
	controller.get_current_unique_players = 
	function()
		local list = {};
		for _,mark in ipairs(controller.marks)
		do
			for index, tank in ipairs(controller.assigned_tanks[mark])
			do
				local tank_exists = false;
				for _, utank in ipairs(list)
				do
					if utank == tank 
					then
						tank_exists = true;
						break;
					end
				end
				
				if tank_exists == false
				then
					table.insert(list, tank);
				end
			end
		end
		
		return list;
	end
	
	--get list of assigned tanks and their marks
	controller.get_current_assignments =
	function()
		local list = {};
		for _, mark in ipairs(controller.marks)
		do
			list[mark] = {};
			for ind, tank in ipairs(controller.assigned_tanks[mark])
			do
				table.insert(list[mark], tank);
			end
		end
		
		return list;
	end 
	
	--consume list of  assigned tanks and populate views/list
		--input: list of mark:tank
	controller.ingest_players = 
	function(tanks)
		--reset current assignments 
		controller.reset();
		
		--consume assignments
		for _, tank in ipairs(tanks)
		do
			local tuple = KAT_split(tank, ":");
			table.insert(controller.assigned_tanks[tuple[1]], tuple[2]);
			controller.notify_observers("add_tank", {tuple[2]});
		end 
	end 
	
	controller.notify_observers = 
	function(action, arglist)
		for _, obs in ipairs(controller.observers)
		do
			--see if observer can ingest notifications
			if obs.interpret_notification ~= nil
			then
				obs.interpret_notification(action, arglist);
			end 
		end
	end
	
	controller.toggle_player 
	=
	function(_mark, _player)
		--Am I in the list already? 
		for entry, list_name in ipairs(controller.assigned_tanks[_mark])
		do
			if _player == list_name
			then
				--remove from list
				table.remove(controller.assigned_tanks[_mark], entry);
				
				--see if he is still assigned elsewhere
				local tank_found = false;
				for _,mark in pairs(controller.marks)
				do
					for i=1, table.getn(controller.assigned_tanks[mark]), 1
					do
						if controller.assigned_tanks[mark][i]== _player
						then
							tank_found = true;
							break;
						end
					end
					
					if tank_found == true
					then
						break;
					end
				end
				
				--tank not found, remove from assigned list for healers
				if tank_found == false
				then
					controller.notify_observers("remove_tank", {_player});
				end
				
				return;
			end
		end
		
		--add to list
		table.insert(controller.assigned_tanks[_mark], _player);
		controller.notify_observers("add_tank", {_player});
	end
	
	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	
	return controller;
end 