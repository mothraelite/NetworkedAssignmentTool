NAT_create_healer_menu_controller = 
function()
	local controller = {};

	--VARIABLES-------------------------------------------------------------------------------------------------------V
	controller.setup_classes = function(obj)
		obj.paladin = {};
		obj.shaman = {};
		obj.druid = {};
		obj.priest = {};
	end

	controller.assigned_tanks = {[1]="Raid"};
	controller.available_healers = {}; controller.setup_classes (controller.available_healers);
	controller.assigned_healers = {["Raid"]={}};
	controller.observers = {};

	--currented focus
	controller.current_focus_mark = "";
	controller.current_menu_parent = nil;
	controller.NAT_assignment_frames = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={},[9]={}};
	controller.post_location = {["channel"]="RAID", ["option"]=nil,["char"]="r"};
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
				if not NAT_is_ready()
				then 
					DEFAULT_CHAT_FRAME:AddMessage("NAT: You are not setup yet. Wait for the go ahead or try to setup again. (Master might be offline)", 0.6,1.0,0.6);
					return;
				end
		   
				--check if i have permission to make changes
				if not IsRaidLeader() and not IsRaidOfficer()
				then
					--no permission, exit
					DEFAULT_CHAT_FRAME:AddMessage("NAT: You need to be the raid leader OR have assist to make changes", 0.6,1.0,0.6);
					return;
				end
		   
				--check if its setup
				if controller.current_focus_mark == ""
				then
					return;
				end
				
				if controller.assigned_healers[controller.current_focus_mark] == nil
				then
					return;
				end
				
				--Am I in the list already? 
				for entry, list_name in ipairs(controller.assigned_healers[controller.current_focus_mark])
				do
					if info.text == list_name
					then
						--remove from list
						table.remove(controller.assigned_healers[controller.current_focus_mark], entry);
						local tmark = controller.current_focus_mark
						if controller.current_focus_mark ~= "Raid"
						then
							tmark = string.sub(controller.current_focus_mark, 11, strlen(controller.current_focus_mark));
						end
						
						SendAddonMessage("NAT", "toggle_healer-"..tmark..":"..string.sub(info.text, 11, strlen(info.text)).."-"..UnitName("player"), "RAID")
						controller.update_marks();
						return;
					end
				end
				
				local tmark = controller.current_focus_mark
				if controller.current_focus_mark ~= "Raid"
				then
					tmark = string.sub(controller.current_focus_mark, 11, strlen(controller.current_focus_mark));
				end
				
				--add to list
				table.insert(controller.assigned_healers[controller.current_focus_mark], info.text);
				SendAddonMessage("NAT", "toggle_healer-"..tmark..":"..string.sub(info.text, 11, strlen(info.text)).."-"..UnitName("player"), "RAID")
				controller.update_marks();
				
			end
			
			return info;
		end

		if UIDROPDOWNMENU_MENU_LEVEL== 1
		then
			local title = {};
			title.text = "Healers"
			title.isTitle = true;
			
			local druids = {};
			druids.text = NAT_retrieve_class_color("Druid").."Druid";
			druids.value = 1;
			druids.hasArrow = true;
			druids.func = function()  end;
			
			if table.getn(controller.available_healers.druid) == 0
			then
				druids.disabled = true;
				druids.hasArrow = false;
				druids.text = "|cff545454Druid";
			end
			
			local paladins = {};
			paladins.text = NAT_retrieve_class_color("Paladin").."Paladin";
			paladins.value = 2;
			paladins.hasArrow = true;
			paladins.func = function()  end;
			
			if table.getn(controller.available_healers.paladin) == 0
			then
				paladins.disabled = true;
				paladins.hasArrow = false;
				paladins.text = "|cff545454Paladin";
			end
			
			local priests = {};
			priests.text = NAT_retrieve_class_color("Priest").."Priest";
			priests.value = 3;
			priests.hasArrow = true;
			priests.func = function()  end;
			
			if table.getn(controller.available_healers.priest) == 0
			then
				priests.disabled = true;
				priests.hasArrow = false;
				priests.text = "|cff545454Priest";
			end
			
			local shamans = {};
			shamans.text = NAT_retrieve_class_color("Shaman").."Shaman";
			shamans.value = 4;
			shamans.hasArrow = true;
			shamans.func = function()  end;
			
			if table.getn(controller.available_healers.shaman) == 0
			then
				shamans.disabled = true;
				shamans.hasArrow = false;
				shamans.text = "|cff545454Shaman";
			end
			
			local clear = {}
			clear.text = "|cffFF0000Clear";
			clear.value = 9;
			clear.hasArrow = false;
			clear.func = 
			function() 
				controller.clear_mark(controller.current_focus_mark);
			end
			
			UIDropDownMenu_AddButton(title, 1);
			UIDropDownMenu_AddButton(druids, 1);
			UIDropDownMenu_AddButton(paladins, 1);
			UIDropDownMenu_AddButton(priests, 1);
			UIDropDownMenu_AddButton(shamans, 1);
			UIDropDownMenu_AddButton(clear, 1);
		elseif UIDROPDOWNMENU_MENU_LEVEL == 2
		then
			local title = {};
			title.text = "Players"
			title.isTitle = true;
			UIDropDownMenu_AddButton(title, 2);
		
			if UIDROPDOWNMENU_MENU_VALUE == 1 --druids
			then
				for i, name in ipairs(controller.available_healers.druid)
				do
					UIDropDownMenu_AddButton(create_sub_info(name, NAT_retrieve_class_color("Druid")), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE== 2 --paladins
			then
				for i, name in ipairs(controller.available_healers.paladin)
				do
					UIDropDownMenu_AddButton(create_sub_info(name, NAT_retrieve_class_color("Paladin")), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 3 --priest
			then
				for i, name in ipairs(controller.available_healers.priest)
				do
					UIDropDownMenu_AddButton(create_sub_info(name, NAT_retrieve_class_color("Priest")), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 4 --shaman
			then
				for i, name in ipairs(controller.available_healers.shaman)
				do
					UIDropDownMenu_AddButton(create_sub_info(name, NAT_retrieve_class_color("Shaman")), 2);
				end
			end
		end
	end

	--populate available tank list
	controller.poll_for_healers =
	function()
		--reset current list
		controller.setup_classes(controller.available_healers);

		--lets see what we got in the raid
		local i = 1;
		local temp_avail_healers = {};
		for i=1, GetNumRaidMembers(), 1
		do
			local pname = UnitName("raid"..i);
			local class, classFileName = UnitClass("raid"..i);

			if class == "Druid"
			then
				table.insert(controller.available_healers.druid, pname);
				table.insert(temp_avail_healers, pname);
			elseif class == "Priest"
			then
				table.insert(controller.available_healers.priest, pname)
				table.insert(temp_avail_healers, pname);
			elseif class == "Paladin"
			then
				table.insert(controller.available_healers.paladin, pname);
				table.insert(temp_avail_healers, pname);
			elseif class == "Shaman"
			then
				table.insert(controller.available_healers.shaman, pname);
				table.insert(temp_avail_healers, pname);
			end
		end
		
		--see if any assigned tank is no longer available
		local current_healers = controller.retrieve_current_unique_players();
		local healers_to_remove = {};
		
		--check current tanks vs available tanks
		for _,current_healer in ipairs(current_healers)
		do
			local tfound = false;
			local unprefix_current_healer = strsub(current_healer, 11, strlen(current_healer));
			for _,avail_healer in ipairs(temp_avail_healers)
			do
				if avail_healer == unprefix_current_healer
				then 
					tfound = true;
					break;
				end
			end 
			
			--not found, mark for removal
			if tfound == false
			then
				table.insert(healers_to_remove, current_healer);
			end 
			
		end
		
		for _, healer_to_remove in ipairs(healers_to_remove)
		do
			--remove all traces of tanks marked for removal from our controller's model list
			local prefix_healer = "";
			for _, mark in ipairs(controller.assigned_tanks)
			do
				for i=1, table.getn(controller.assigned_healers[mark]), 1
				do
					--attempting to find tank among assignments
					if controller.assigned_healers[mark][i] == healer_to_remove
					then
						table.remove(controller.assigned_healers[mark], i); --remove tank from assignment
						break;
					end
				end 
			end
			
			--inform observers that we removed a tank
			controller.notify_observers("remove_healer", {healer_to_remove});
		end
	end
	
	controller.retrieve_current_unique_players =
	function()
		local list = {};
		for _,mark in ipairs(controller.assigned_tanks)
		do
			for index, healer in ipairs(controller.assigned_healers[mark])
			do
				local healer_exists = false;
				for _, uhealer in ipairs(list)
				do
					if uhealer == healer 
					then
						healer_exists = true;
						break;
					end
				end
				
				if healer_exists == false
				then
					table.insert(list, healer);
				end
			end
		end
		
		return list;
	end

	controller.update_marks =
	function()
		--set text to selected tanks
		for mark_pos, mark in ipairs(controller.assigned_tanks)
		do
			for index, healer in ipairs(controller.assigned_healers[mark])
			do
				--do I have enough free frames at this mark?
				if 	index > table.getn(controller.NAT_assignment_frames[mark_pos])
				then
					-- I don't, add a frame to view
					local frame = NAT_create_player_frame("healer_player_frame_"..mark.."_"..index, NAT_healer_body, healer);
					frame.mark = mark;
					frame.colored_name = healer;
					frame:SetScript("OnClick", 
					function()
						if not IsRaidLeader() and not IsRaidOfficer() 
						then 
							DEFAULT_CHAT_FRAME:AddMessage("NAT: You need to be the raid leader OR have assist to make changes", 0.6,1.0,0.6);
							return;
						end
						
						local tmark = frame.mark;
						if frame.mark ~= "Raid"
						then
							tmark = string.sub(frame.mark, 11, strlen(frame.mark));
						end
						
						SendAddonMessage("NAT", "toggle_healer-"..tmark..":"..frame.name:GetText().."-"..UnitName("player"), "RAID");
						controller.toggle_player(frame.mark, frame.colored_name);  
					end);
					
					if index > 3
					then
						frame:SetPoint("TOPLEFT", -40+NAT_mod(index,4)*133+133, 10-(mark_pos*40)-19);
						frame:SetHeight(19);
						frame.highlight:SetHeight(19);
						frame.name:SetPoint("CENTER",0,0);
						frame.model:Hide();
					else	
						frame:SetPoint("TOPLEFT", -40+index*133, 10-(mark_pos*40) );
					end
				
					
					frame:Show();
					table.insert(controller.NAT_assignment_frames[mark_pos],frame);
				else
					--I do, adjust content in that frame
					local uncolored_name = string.sub(healer,  11, strlen(healer));
					local r,g,b = NAT_hex2rgb(string.sub(healer, 5,11));
					
					local frame = controller.NAT_assignment_frames[mark_pos][index];
					frame.mark = mark;
					frame.colored_name = healer;
					frame.name:SetText(uncolored_name);
					frame.model:SetUnit(NAT_retrieve_unitid_from_name(uncolored_name));
					frame.model:SetCamera(0)
					frame.bg:SetTexture(r/255,g/255,b/255,0.75);
					frame.bg:SetAllPoints(true);
					
					frame:Show();
				end
				
			end

			--do I need to adjust frames pos/size at this mark?
			if table.getn(controller.assigned_healers[mark])/3 > 1
			then
				--check if already smooshed
				if controller.NAT_assignment_frames[mark_pos][1]:GetHeight() > 19
				then --not smooshed yet
					for i=1, 3, 1
					do
						local healer_frame = controller.NAT_assignment_frames[mark_pos][i];
						
						--smoosh 
						healer_frame:SetHeight(19);
						healer_frame.highlight:SetHeight(19);
						healer_frame.name:SetPoint("CENTER",0, 0)
						
						--disable model view
						healer_frame.model:Hide();
					end
					
				end
			else
				--check if already enlarged and in charge
				if table.getn(controller.NAT_assignment_frames[mark_pos]) > 0
				then
					if controller.NAT_assignment_frames[mark_pos][1]:GetHeight() < 38
					then --not enlarged yet nor incharge
						for i=1, table.getn(controller.assigned_healers[mark]), 1
						do
							local healer_frame = controller.NAT_assignment_frames[mark_pos][i];
							
							--enlarge
							healer_frame:SetHeight(38);
							healer_frame.highlight:SetHeight(38);
							healer_frame.name:SetPoint("CENTER",10, 0)
							
							--enable model view
							healer_frame.model:Show();
						end
					end
				end
			end
			
			--Do I have extra frames?
			local  i = table.getn(controller.NAT_assignment_frames[mark_pos]);
			while i > table.getn(controller.assigned_healers[mark])
			do
				--I do, hide them and make them inactive
				local frame = controller.NAT_assignment_frames[mark_pos][i];
				frame.name:SetText("");
				frame.model:ClearModel();
				frame:Hide();
				
				i = i - 1;
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
				NATHealPostLabel:SetText(": "..name);
			else
				NATHealerPostChannelEdit:SetText(controller.post_location["char"]);
				DEFAULT_CHAT_FRAME:AddMessage("NAT: post location " .. chara .. " is not an acceptable post location", 0.6,1.0,0.6);
			end
		else
			--check if I have an acceptable char
			if _chara == "r"
			then
				controller.post_location["channel"] = "RAID";
				controller.post_location["option"] = nil;
				NATHealPostLabel:SetText(": raid");
				controller.post_location["char"] = _chara;
			elseif _chara == "p"
			then
				controller.post_location["channel"] = "PARTY";
				controller.post_location["option"] = nil;
				NATHealPostLabel:SetText(": party");
				controller.post_location["char"] = _chara;
			elseif _chara == "o"
			then
				controller.post_location["channel"] = "OFFICER";
				controller.post_location["option"] = nil;
				NATHealPostLabel:SetText(": officer");
				controller.post_location["char"] = _chara;
			elseif _chara == "g"
			then
				controller.post_location["channel"] = "GUILD";
				controller.post_location["option"] = nil;
				NATHealPostLabel:SetText(": guild");
				controller.post_location["char"] = _chara;
			elseif _chara == "s"
			then
				controller.post_location["channel"] = "SAY";
				controller.post_location["option"] = nil;
				NATHealPostLabel:SetText(": say");
				controller.post_location["char"] = _chara;
			else
				NATHealerPostChannelEdit:SetText(controller.post_location["char"]);
				DEFAULT_CHAT_FRAME:AddMessage("NAT: post location " .. chara .. " is not an acceptable post location", 0.6,1.0,0.6);
			end
		end
	end

	controller.post = 
	function()
		SendChatMessage(" -- Healing Assignments --", controller.post_location["channel"], nil, controller.post_location["option"]);
		for _, mark in ipairs(controller.assigned_tanks)
		do
			if table.getn(controller.assigned_healers[mark]) > 0
			then
				local healer_list = "";
				for index, healer in ipairs(controller.assigned_healers[mark])
				do
					healer = healer .. "|r";
					healer_list = healer_list .. healer .. " ";
				end
				
				if mark == "Raid"
				then
					mark = "|cffFFD700" .. mark;
				end
				mark = "["..mark .. "|r".."]";
				SendChatMessage(mark..": " ..healer_list, controller.post_location["channel"], nil, controller.post_location["option"]);
			else
				if mark == "Raid"
				then
					mark = "|cffFFD700" .. mark;
				end
			
				mark = "["..mark .. "|r".."]";
				SendChatMessage(mark..": none", controller.post_location["channel"], nil, controller.post_location["option"]);
			end
		end
	end
	
	controller.add_tank = 
	function(ntank)
		--check if tank already exists
		for _, tank in ipairs(controller.assigned_tanks)
		do
			--already exists
			if tank == ntank
			then 
				return;
			end
		end 
		
		--add them to list
		table.insert(controller.assigned_tanks, ntank);
		controller.assigned_healers[ntank] = {};
		controller.update_assigned_tank_labels();
	end
	
	controller.remove_tank = 
	function(tank)
		for index, atank in ipairs(controller.assigned_tanks)
		do
			--found
			if tank == atank
			then
				--remove from assignment list
				controller.assigned_healers[atank] = nil;
				
				--remove from this list
				table.remove(controller.assigned_tanks, index);
				
				--update views
				controller.update_assigned_tank_labels();
				
				break;
			end
		end
	end
	
	--get list of assigned tanks and their marks
	controller.get_current_assignments =
	function()
		local list = {};
		local empty = true;
		for _, mark in ipairs(controller.assigned_tanks)
		do
			if table.getn(controller.assigned_healers[mark]) > 0
			then
				empty = false;
				list[mark] = {};
				for ind, healer in ipairs(controller.assigned_healers[mark])
				do
					table.insert(list[mark], healer);
				end
			end
		end
		
		if empty == true 
		then
			return nil;
		end
		
		return list;
	end 
	
	controller.clear_mark
	=
	function(_mark)
		while table.getn(controller.assigned_healers[_mark]) ~= 0
		do
			local healer = controller.assigned_healers[_mark][1]
			controller.toggle_player(_mark, healer)
			
			local tmark = _mark
			if _mark ~= "Raid"
			then
				tmark = string.sub(_mark, 11, strlen(_mark));
			end
			
			SendAddonMessage("NAT", "toggle_healer-".._mark..":"..string.sub(healer,11,strlen(healer)).."-"..UnitName("player"), "RAID")
		end
		
		controller.update_marks(); --update views
	end
	
	controller.reset
	=
	function()
		--reset current assignments 
		for _, mark in ipairs(controller.assigned_tanks)
		do
			controller.assigned_healers[mark] = {};
		end
	end 
	
	--consume list of  assigned tanks and populate views/list
		--input: list of mark:healer
	controller.ingest_players = 
	function(healers)
		--reset current assignments 
		controller.reset();
		
		--consume assignments
		for _, healer in ipairs(healers)
		do
			local tuple = NAT_split(healer, ":");
			if tuple[1] ~= "Raid"
			then
				tuple[1] = NAT_retrieve_class_color(NAT_retrieve_player_class(tuple[1]))..tuple[1];
			end 
			
			table.insert(controller.assigned_healers[tuple[1]], NAT_retrieve_class_color(NAT_retrieve_player_class(tuple[2]))..tuple[2]);
		end 
		
		controller.update_marks();
	end 
	
	controller.update_assigned_tank_labels = 
	function()
		--setup label names
			--shity work around because retrieving frames from primary frame is aids
		for i,tank in ipairs(controller.assigned_tanks)
		do
			if i == 1
			then 
				tank1_label:SetText(tank);
			elseif i == 2
			then
				tank2_label:SetText(tank);
			elseif i == 3
			then
				tank3_label:SetText(tank);
			elseif i == 4
			then 
				tank4_label:SetText(tank);
			elseif i == 5
			then 
				tank5_label:SetText(tank);
			elseif i == 6
			then 
				tank6_label:SetText(tank);
			elseif i == 7
			then 
				tank7_label:SetText(tank);
			elseif i == 8
			then 
				tank8_label:SetText(tank);
			elseif i == 9
			then 
				tank9_label:SetText(tank);
			end
		end
		
		for i=9, table.getn(controller.assigned_tanks)+1, -1
		do
			if i == 1
			then 
				tank1_label:SetText("");
			elseif i == 2
			then
				tank2_label:SetText("");
			elseif i == 3
			then
				tank3_label:SetText("");
			elseif i == 4
			then 
				tank4_label:SetText("");
			elseif i == 5
			then 
				tank5_label:SetText("");
			elseif i == 6
			then 
				tank6_label:SetText("");
			elseif i == 7
			then 
				tank7_label:SetText("");
			elseif i == 8
			then 
				tank8_label:SetText("");
			elseif i == 9
			then
				tank9_label:SetText("");
			end
			
			--hide frames from removed tanks
			for _, healer_frame in ipairs(controller.NAT_assignment_frames[i])
			do
				healer_frame:Hide();
			end
		end
		controller.update_marks();
	end
	
	controller.interpret_notification = 
	function(action, _arglist)
		if action == "add_tank"
		then
			if _arglist == nil
			then
				return;
			end 
			controller.add_tank(_arglist[1]);
		elseif action == "remove_tank"
		then
			if _arglist == nil
			then
				return;
			end 
		
			controller.remove_tank(_arglist[1]);
		end
	end
	
	controller.notify_observers = 
	function(_action, _arglist)
		for _, obs in ipairs(controller.observers)
		do
			--see if observer can ingest notifications
			if obs.interpret_notification ~= nil
			then
				obs.interpret_notification(_action, _arglist);
			end 
		end
	end
	
	controller.toggle_player =
	function(_mark, _player)
		--Am I in the list already? 
		for entry, list_name in ipairs(controller.assigned_healers[_mark])
		do
			if _player == list_name
			then
				--remove from list
				table.remove(controller.assigned_healers[_mark], entry);
				controller.update_marks();
				return;
			end
		end
		
		--add to list
		table.insert(controller.assigned_healers[_mark], _player);
		controller.update_marks();
	end
	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	
	return controller;
end 