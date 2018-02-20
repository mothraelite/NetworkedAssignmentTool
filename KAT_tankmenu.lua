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
	
	controller.assigned_tanks = {["skull"]={}, ["x"]={}, ["square"]={},["moon"]={},["triangle"]={},["diamond"]={},["circle"]={},["star"]={},["MT"]={}};
	controller.marks = {"skull", "x", "square", "moon", "triangle", "diamond", "circle", "star", "MT"};
	controller.available_tanks = {}; controller.setup_classes (controller.available_tanks);
	controller.observers = {};

	--currented focus
	controller.current_focus_mark = "";
	controller.current_menu_parent = nil;
	controller.kat_assignment_frames = {["skull"]={}, ["x"]={}, ["square"]={},["moon"]={},["triangle"]={},["diamond"]={},["circle"]={},["star"]={},["MT"]={}};
	controller.post_location = {["channel"]="RAID", ["option"]=nil, ["char"]="r"};
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
							KAT_network_message("KAT", "toggle_tank-"..controller.current_focus_mark..":"..info.text.."-"..UnitName("player"), "RAID")
							controller.update_marks();
						end
						
						return;
					end
				end
				
				--add to list
				table.insert(controller.assigned_tanks[controller.current_focus_mark], info.text);
				controller.notify_observers("add_tank", {info.text});
				KAT_network_message("KAT", "toggle_tank-"..controller.current_focus_mark..":"..info.text.."-"..UnitName("player"), "RAID")
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
			
			local clear = {}
			clear.text = "|cffFF0000Clear";
			clear.value = 9;
			clear.hasArrow = false;
			clear.func = 
			function() 
				if not IsRaidLeader() and not IsRaidOfficer()
				then
					DEFAULT_CHAT_FRAME:AddMessage("KAT: Can not use clear function without being the raid leader or having assist.", 0.6,1.0,0.6);
					return;
				end
			
				controller.clear_mark(controller.current_focus_mark);
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
			UIDropDownMenu_AddButton(clear, 1)
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
		--set text to selected tanks
		for mark_pos, mark in ipairs(controller.marks)
		do
			for index, tank in ipairs(controller.assigned_tanks[mark])
			do
				--do I have enough free frames at this mark?
				if 	index > table.getn(controller.kat_assignment_frames[mark])
				then
					-- I don't, add a frame to view
					local frame = KAT_create_player_frame("tank_player_frame_"..mark.."_"..index, KAT_tank_body, tank);
					frame.mark = mark;
					frame.colored_name = tank;
					frame:SetScript("OnClick", 
					function()
						if not IsRaidLeader() and not IsRaidOfficer() 
						then 
							DEFAULT_CHAT_FRAME:AddMessage("KAT: You need to be the raid leader OR have assist to make changes", 0.6,1.0,0.6);
							return;
						end
						KAT_network_message("KAT", "toggle_tank-"..frame.mark..":"..frame.colored_name.."-"..UnitName("player"), "RAID");
						controller.toggle_player(frame.mark, frame.colored_name);  
					end);
					
					if index > 3
					then
						frame:SetPoint("TOPLEFT", -40+KAT_mod(index,3)*133, 10-(mark_pos*40)-19);
						frame:SetHeight(19);
						frame.highlight:SetHeight(19);
						frame.name:SetPoint("CENTER",0,0);
						frame.model:Hide();
					else	
						frame:SetPoint("TOPLEFT", -40+index*133, 10-(mark_pos*40) );
					end
				
					
					frame:Show();
					table.insert(controller.kat_assignment_frames[mark],frame);
				else
					--I do, adjust content in that frame
					local uncolored_name = string.sub(tank,  11, strlen(tank));
					local r,g,b = KAT_hex2rgb(string.sub(tank, 5,11));
					
					local frame = controller.kat_assignment_frames[mark][index];
					frame.mark = mark;
					frame.colored_name = tank;
					frame.name:SetText(uncolored_name);
					frame.model:SetUnit(KAT_retrieve_unitid_from_name(uncolored_name));
					frame.model:SetCamera(0)
					frame.bg:SetTexture(r/255,g/255,b/255,0.75);
					frame.bg:SetAllPoints(true);
					
					frame:Show();
				end
				
			end

			--do I need to adjust frames pos/size at this mark?
			if table.getn(controller.assigned_tanks[mark])/3 > 1
			then
				--check if already smooshed
				if controller.kat_assignment_frames[mark][1]:GetHeight() > 19
				then --not smooshed yet
					for i=1, 3, 1
					do
						local tank_frame = controller.kat_assignment_frames[mark][i];
						
						--smoosh 
						tank_frame:SetHeight(19);
						tank_frame.highlight:SetHeight(19);
						tank_frame.name:SetPoint("CENTER",0, 0)
						
						--disable model view
						tank_frame.model:Hide();
					end
					
				end
			else
				--check if already enlarged and in charge
				if table.getn(controller.kat_assignment_frames[mark]) > 0
				then
					if controller.kat_assignment_frames[mark][1]:GetHeight() < 38
					then --not enlarged yet nor incharge
						for i=1, table.getn(controller.assigned_tanks[mark]), 1
						do
							local tank_frame = controller.kat_assignment_frames[mark][i];
							
							--enlarge
							tank_frame:SetHeight(38);
							tank_frame.highlight:SetHeight(38);
							tank_frame.name:SetPoint("CENTER",10, 0)
							
							--enable model view
							tank_frame.model:Show();
						end
					end
				end
			end
			
			--Do I have extra frames?
			local  i = table.getn(controller.kat_assignment_frames[mark]);
			while i > table.getn(controller.assigned_tanks[mark])
			do
				--I do, hide them and make them inactive
				local frame = controller.kat_assignment_frames[mark][i];
				frame.name:SetText("");
				frame.model:ClearModel();
				frame:Hide();
				
				i = i - 1;
			end
		end
	end 

	controller.post = 
	function()
		SendChatMessage(" -- Tank Assignments --", controller.post_location["channel"], nil, controller.post_location["option"]);
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
				
				SendChatMessage("{"..mark.."}: " ..tank_list, controller.post_location["channel"], nil, controller.post_location["option"]);
			end
		end
	end
	
	controller.set_post_location
	=
	function(_chara)
		chara = strlower(_chara);
		
		--check if its a number
		local asci_val = string.byte(_chara);
		if asci_val >48 and asci_val < 58
		then
			local id, name = GetChannelName(_chara);
			
			if name ~= nil
			then
				controller.post_location["channel"] = "CHANNEL";
				controller.post_location["option"] = _chara;
				controller.post_location["char"] = _chara;
				KatTankPostLabel:SetText(": "..name);
			else
				KatTankPostChannelEdit:SetText(controller.post_location["char"]);
				DEFAULT_CHAT_FRAME:AddMessage("KAT: post location " .. chara .. " is not an acceptable post location", 0.6,1.0,0.6);
			end
		else
			--check if I have an acceptable char
			if _chara == "r"
			then
				controller.post_location["channel"] = "RAID";
				controller.post_location["option"] = nil;
				KatTankPostLabel:SetText(": raid");
				controller.post_location["char"] = _chara;
			elseif _chara == "p"
			then
				controller.post_location["channel"] = "PARTY";
				controller.post_location["option"] = nil;
				KatTankPostLabel:SetText(": party");
				controller.post_location["char"] = _chara;
			elseif _chara == "o"
			then
				controller.post_location["channel"] = "OFFICER";
				controller.post_location["option"] = nil;
				KatTankPostLabel:SetText(": officer");
				controller.post_location["char"] = _chara;
			elseif _chara == "g"
			then
				controller.post_location["channel"] = "GUILD";
				controller.post_location["option"] = nil;
				KatTankPostLabel:SetText(": guild");
				controller.post_location["char"] = _chara;
			elseif c_hara == "s"
			then
				controller.post_location["channel"] = "SAY";
				controller.post_location["option"] = nil;
				KatTankPostLabel:SetText(": say");
				controller.post_location["char"] = _chara;
			else
				KatTankPostChannelEdit:SetText(controller.post_location["char"]);
				DEFAULT_CHAT_FRAME:AddMessage("KAT: post location " .. chara .. " is not an acceptable post location", 0.6,1.0,0.6);
			end
		end
	end
	
	controller.clear_mark
	=
	function(_mark)
		while table.getn(controller.assigned_tanks[_mark]) ~= 0
		do
			local tank = controller.assigned_tanks[_mark][1];
			controller.toggle_player(_mark, tank)
			KAT_network_message("KAT", "toggle_tank-".._mark..":"..tank.."-"..UnitName("player"), "RAID")
		end
		
		controller.update_marks(); --update views
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
		local empty = true;
		for _, mark in ipairs(controller.marks)
		do
			if table.getn(controller.assigned_tanks[mark]) > 0
			then
				empty = false;
				list[mark] = {};
				for ind, tank in ipairs(controller.assigned_tanks[mark])
				do
					table.insert(list[mark], tank);
				end
			end
		end
		
		if empty == true
		then
			return nil;
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
		
		controller.update_marks();
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
				controller.update_marks();
				
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
		
		controller.update_marks();
	end
		--HELPER FUNCS-----------------------------------------------------HF

		--HELPER FUNCS-----------------------------------------------------HF
	
	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	
	return controller;
end 