NAT_create_menu_controller = 
function(_postInputBoxObject, _postLabelObject, _viewBody)
	local controller = {};

	--VARIABLES-------------------------------------------------------------------------------------------------------V
	controller.setup_classes = function(obj)
		obj.Warrior = {};
		obj.Paladin = {};
		obj.Mage = {};
		obj.Shaman = {};
		obj.Druid = {};
		obj.Warlock = {};
		obj.Hunter = {};
		obj.Priest = {};
		obj.Rogue = {};
	end
	
	controller.tag = "";
	controller.useable_classes = {"Warrior", "Paladin", "Mage", "Shaman", "Druid", "Warlock", "Hunter", "Priest", "Rogue"};
	controller.assigned_players = {["skull"]={}, ["x"]={}, ["square"]={},["moon"]={},["triangle"]={},["diamond"]={},["circle"]={},["star"]={},["MT"]={}};
	controller.marks = {"skull", "x", "square", "moon", "triangle", "diamond", "circle", "star", "MT"};
	controller.available_players = {}; controller.setup_classes (controller.available_players);
	controller.observers = {};

	--currented focus
	controller.current_focus_mark = "";
	controller.current_menu_parent = nil;
	controller.NAT_assignment_frames = {[1]={}, [2]={}, [3]={},[4]={},[5]={},[6]={},[7]={},[8]={},[9]={}};
	controller.post_location = {["channel"]="RAID", ["option"]=nil, ["char"]="r"};
	
	--broadcasted datums 
	controller.toggle_command = ""; --network
	controller.add_player_command = ""; --observer command 
	controller.remove_player_command = ""; --observer command
	
	--xml references
	controller.postInputOption = _postInputBoxObject;
	controller.postLabel = _postLabelObject;
	controller.viewBody = _viewBody;
	
	--VARIABLES-------------------------------------------------------------------------------------------------------V

	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	--function to setup player list
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
				if not UnitIsGroupLeader("player") and not UnitIsGroupAssistant("player")
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

				--Am I in the list already? 
				for entry, list_name in ipairs(controller.assigned_players[controller.current_focus_mark])
				do
					if info.text == list_name
					then
						--remove from list
						table.remove(controller.assigned_players[controller.current_focus_mark], entry);
						controller.update_marks();
						
						--see if he is still assigned elsewhere
						local player_found = false;
						for _,mark in pairs(controller.marks)
						do
							for i=1, table.getn(controller.assigned_players[mark]), 1
							do
								if controller.assigned_players[mark][i]== info.text
								then
									player_found = true;
									break;
								end
							end
							
							if player_found == true
							then
								break;
							end
						end
						
						--player not found, remove from assigned list for healers
						if player_found == false
						then
							controller.notify_observers(controller.remove_player_command, {info.text});
							C_ChatInfo.SendAddonMessage("NAT", controller.toggle_command..controller.current_focus_mark..":"..string.sub(info.text, 11, strlen(info.text)).."-"..UnitName("player"), "RAID")
							controller.update_marks();
						end
						
						return;
					end
				end
				
				--add to list
				table.insert(controller.assigned_players[controller.current_focus_mark], info.text);
				controller.notify_observers(controller.add_player_command, {info.text});
				C_ChatInfo.SendAddonMessage("NAT", controller.toggle_command..controller.current_focus_mark..":"..string.sub(info.text, 11, strlen(info.text)).."-"..UnitName("player"), "RAID")
				controller.update_marks();
			end
			
			return info;
		end

		if UIDROPDOWNMENU_MENU_LEVEL== 1
		then
			local title = {};
			title.text = "players"
			title.isTitle = true;
			UIDropDownMenu_AddButton(title,1);
			
			
			local index = 1;
			for index, class_name in ipairs(controller.useable_classes)
			do
				local class = {};
				class.text = NAT_retrieve_class_color(class_name)..class_name;
				class.value = index;
				class.hasArrow = true;
				class.func = function() end;
				
				if table.getn(controller.available_players[class_name]) == 0
				then
					class.disabled = true;
					class.hasArrow = false;
					class.text = "|cff545454"..class_name
				end
				UIDropDownMenu_AddButton(class, 1);
			end
			
			local clear = {}
			clear.text = "|cffFF0000Clear";
			clear.value = index+1;
			clear.hasArrow = false;
			clear.func = 
			function() 
				if not UnitIsGroupLeader("player") and not UnitIsGroupAssistant("player")
				then
					DEFAULT_CHAT_FRAME:AddMessage("NAT: Can not use clear function without being the raid leader or having assist.", 0.6,1.0,0.6);
					return;
				end
			
				controller.clear_mark(controller.current_focus_mark);
			end
			UIDropDownMenu_AddButton(clear, 1)
			
		elseif UIDROPDOWNMENU_MENU_LEVEL == 2
		then
			local title = {};
			title.text = controller.tag;
			title.isTitle = true;
			UIDropDownMenu_AddButton(title, 2);
			
			for i, class_name in ipairs(controller.useable_classes)
			do
				if UIDROPDOWNMENU_MENU_VALUE == i
				then
					for _, name in ipairs(controller.available_players[class_name])
					do
					   UIDropDownMenu_AddButton(create_sub_info(name, NAT_retrieve_class_color(class_name)), 2);
					end
					break;
				end
			end
			
		end
		
	end

	--populate available player list
	controller.poll_for_players =
	function()
		--reset current list
		controller.setup_classes(controller.available_players);

		--setup available players
		local i =1;
		local temp_avail_players = {};
		for i=1, GetNumGroupMembers(), 1
		do
			local pname = UnitName("raid"..i);
			local class, classFileName = UnitClass("raid"..i);
			table.insert(controller.available_players[class], pname);
			table.insert(temp_avail_players, pname);
		end
		
		--see if any assigned player is no longer available
		local current_players = controller.get_current_unique_players();
		local players_to_remove = {};
		
		--check current players vs available players
		for _,current_player in ipairs(current_players)
		do
			local tfound = false;
			local unprefix_current_player = strsub(current_player, 11, strlen(current_player));
			for _,avail_player in ipairs(temp_avail_players)
			do
				if avail_player == unprefix_current_player
				then 
					tfound = true;
					break;
				end
			end 
			
			--not found, mark for removal
			if tfound == false
			then
				table.insert(players_to_remove, current_player);
			end 
			
		end
		
		for _, player_to_remove in ipairs(players_to_remove)
		do
			--remove all traces of players marked for removal from our controller's model list
			local prefix_player = "";
			for _, mark in ipairs(controller.marks)
			do
				for i=1, table.getn(controller.assigned_players[mark]), 1
				do
					--attempting to find player among assignments
					if controller.assigned_players[mark][i] == player_to_remove
					then
						table.remove(controller.assigned_players[mark], i); --remove player from assignment
						break;
					end
				end 
			end
			
			--inform observers that we removed a player
			controller.notify_observers(controller.remove_player_command, {player_to_remove});
		end
	end
	
	controller.update_marks =
	function()
		--set text to selected players
		for mark_pos, mark in ipairs(controller.marks)
		do
			for index, player in ipairs(controller.assigned_players[mark])
			do
				--do I have enough free frames at this mark?
				if 	index > table.getn(controller.NAT_assignment_frames[mark_pos])
				then
					-- I don't, add a frame to view
					local frame = NAT_create_player_frame("player_"..controller.tag.."_frame_"..mark.."_"..index, controller.viewBody, player);
					frame.mark = mark;
					frame.colored_name = player;
					frame:SetScript("OnClick", 
					function()
						if not UnitIsGroupLeader("player") and not UnitIsGroupAssistant("player") 
						then 
							DEFAULT_CHAT_FRAME:AddMessage("NAT: You need to be the raid leader OR have assist to make changes", 0.6,1.0,0.6);
							return;
						end
						
						C_ChatInfo.SendAddonMessage("NAT", controller.toggle_command..controller.clean_mark(frame.mark)..":"..frame.name:GetText().."-"..UnitName("player"), "RAID");
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
					local uncolored_name = string.sub(player,  11, strlen(player));
					local r,g,b = NAT_hex2rgb(string.sub(player, 5,11));
					
					local frame = controller.NAT_assignment_frames[mark_pos][index];
					frame.mark = mark;
					frame.colored_name = player;
					frame.name:SetText(uncolored_name);
					frame.model:SetUnit(NAT_retrieve_unitid_from_name(uncolored_name));
					frame.model:SetCamera(0)
					frame.bg:SetColorTexture(r/255,g/255,b/255,0.75);
					frame.bg:SetAllPoints(true);
					
					frame:Show();
				end
				
			end

			--do I need to adjust frames pos/size at this mark?
			if table.getn(controller.assigned_players[mark])/3 > 1
			then
				--check if already smooshed
				if controller.NAT_assignment_frames[mark_pos][1]:GetHeight() > 19
				then --not smooshed yet
					for i=1, 3, 1
					do
						local player_frame = controller.NAT_assignment_frames[mark_pos][i];
						
						--smoosh 
						player_frame:SetHeight(19);
						player_frame.highlight:SetHeight(19);
						player_frame.name:SetPoint("CENTER",0, 0)
						
						--disable model view
						player_frame.model:Hide();
					end
					
				end
			else
				--check if already enlarged and in charge
				if table.getn(controller.NAT_assignment_frames[mark_pos]) > 0
				then
					if controller.NAT_assignment_frames[mark_pos][1]:GetHeight() < 38
					then --not enlarged yet nor incharge
						for i=1, table.getn(controller.assigned_players[controller.marks[mark_pos]]), 1
						do
							local player_frame = controller.NAT_assignment_frames[mark_pos][i];
							
							--enlarge
							player_frame:SetHeight(38);
							player_frame.highlight:SetHeight(38);
							player_frame.name:SetPoint("CENTER",10, 0)
							
							--enable model view
							player_frame.model:Show();
						end
					end
				end
			end
			
			--Do I have extra frames?
			local  i = table.getn(controller.NAT_assignment_frames[mark_pos]);
			while i > table.getn(controller.assigned_players[mark])
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

	controller.post = 
	function()
		SendChatMessage(" -- "..controller.tag.." Assignments --", controller.post_location["channel"], nil, controller.post_location["option"]);
		for _, mark in ipairs(controller.marks)
		do
			if table.getn(controller.assigned_players[mark]) > 0
			then
				local player_list = "";
				for index, player in ipairs(controller.assigned_players[mark])
				do
					--if there was color applied to player. shitty server doesn't allow colored text in chat
					if strlen(player) > 10
					then
						player = strsub(player, 11, strlen(player));
					end
					--player  = player .. "|r";

					player_list = player_list .. player .. " ";
				end

				--if color applied to mark. shitty server doesn't allow colored text in chat
				local out_mark = mark;
				if strlen(out_mark) > 10
				then
					out_mark = strsub(out_mark, 11, strlen(out_mark));
				end
				
				SendChatMessage("[{"..out_mark.."}]: " ..player_list, controller.post_location["channel"], nil, controller.post_location["option"]);
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
				controller.postLabel:SetText(name);
			else
				controller.postInputOption:SetText(controller.post_location["char"]);
				DEFAULT_CHAT_FRAME:AddMessage("NAT: post location " .. chara .. " is not an acceptable post location", 0.6,1.0,0.6);
			end
		else
			--check if I have an acceptable char
			if _chara == "r"
			then
				controller.post_location["channel"] = "RAID";
				controller.post_location["option"] = nil;
				controller.postLabel:SetText("raid");
				controller.post_location["char"] = _chara;
			elseif _chara == "p"
			then
				controller.post_location["channel"] = "PARTY";
				controller.post_location["option"] = nil;
				controller.postLabel:SetText("party");
				controller.post_location["char"] = _chara;
			elseif _chara == "o"
			then
				controller.post_location["channel"] = "OFFICER";
				controller.post_location["option"] = nil;
				controller.postLabel:SetText("officer");
				controller.post_location["char"] = _chara;
			elseif _chara == "g"
			then
				controller.post_location["channel"] = "GUILD";
				controller.post_location["option"] = nil;
				controller.postLabel:SetText("guild");
				controller.post_location["char"] = _chara;
			elseif _chara == "s"
			then
				controller.post_location["channel"] = "SAY";
				controller.post_location["option"] = nil;
				controller.postLabel:SetText("say");
				controller.post_location["char"] = _chara;
			else
				controller.postInputOption:SetText(controller.post_location["char"]);
				DEFAULT_CHAT_FRAME:AddMessage("NAT: post location " .. chara .. " is not an acceptable post location", 0.6,1.0,0.6);
			end
		end
	end
	
	controller.clear_mark
	=
	function(_mark)
		while table.getn(controller.assigned_players[_mark]) ~= 0
		do
			local player = controller.assigned_players[_mark][1];
			controller.toggle_player(_mark, player)
			C_ChatInfo.SendAddonMessage("NAT", controller.toggle_command.._mark..":"..string.sub(player,11,strlen(player)).."-"..UnitName("player"), "RAID")
		end
		
		controller.update_marks(); --update views
	end
	
	controller.reset
	=
	function()
		--reset current assignments 
		for _, mark in ipairs(controller.marks)
		do
			controller.assigned_players[mark] = {};
		end
	end 
	
	--get list of assigned players
	controller.get_current_unique_players = 
	function()
		local list = {};
		for _,mark in ipairs(controller.marks)
		do
			for index, player in ipairs(controller.assigned_players[mark])
			do
				local player_exists = false;
				for _, uplayer in ipairs(list)
				do
					if uplayer == player 
					then
						player_exists = true;
						break;
					end
				end
				
				if player_exists == false
				then
					table.insert(list, player);
				end
			end
		end
		
		return list;
	end
	
	--get list of assigned players and their marks
	controller.get_current_assignments =
	function()
		local list = {};
		local empty = true;
		for _, mark in ipairs(controller.marks)
		do
			if table.getn(controller.assigned_players[mark]) > 0
			then
				empty = false;
				list[mark] = {};
				for ind, player in ipairs(controller.assigned_players[mark])
				do
					table.insert(list[mark], player);
				end
			end
		end
		
		if empty == true
		then
			return nil;
		end
		
		return list;
	end 
	
	controller.random_assign = 
	function(_player_targets)

		--get all applicable players
		local temp = {};
		for _, player in ipairs(controller.available_players.warrior)
		do
			--check if they have the HACHE PEES
			local unitid = NAT_retrieve_unitid_from_name(player);
			if unitid ~= nil
			then
				if UnitHealth(unitid) > 6800
				then
					--add them to list 
					table.insert(temp, NAT_retrieve_class_color("Warrior")..player);
				end
			end
		end
		
		--not enough players for each mark, assign what we can
		if _player_targets > table.getn(temp)
		then
			_player_targets = table.getn(temp);
		end
		
		for i = 1, _player_targets, 1
		do
			local mark = controller.marks[i];
			local player_index = math.random(1, table.getn(temp));
			controller.toggle_player(mark, temp[player_index]);
			
			table.remove(temp, player_index);
		end
	end
	
	--consume list of  assigned players and populate views/list
		--input: list of mark:player
	controller.ingest_players = 
	function(players)
		--reset current assignments 
		controller.reset();
		
		--consume assignments
		for _, player in ipairs(players)
		do
			local tuple = NAT_split(player, ":");
			local colored_player = NAT_retrieve_class_color(NAT_retrieve_player_class(tuple[2]))..tuple[2];
			table.insert(controller.assigned_players[tuple[1]], colored_player);
			controller.notify_observers(controller.add_player_command, {colored_player});
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
		for entry, list_name in ipairs(controller.assigned_players[_mark])
		do
			if _player == list_name
			then
				--remove from list
				table.remove(controller.assigned_players[_mark], entry);
				controller.update_marks();
				
				--see if he is still assigned elsewhere
				local player_found = false;
				for _,mark in pairs(controller.marks)
				do
					for i=1, table.getn(controller.assigned_players[mark]), 1
					do
						if controller.assigned_players[mark][i]== _player
						then
							player_found = true;
							break;
						end
					end
					
					if player_found == true
					then
						break;
					end
				end
				
				--player not found, remove from assigned list for healers
				if player_found == false
				then
					controller.notify_observers(controller.remove_player_command, {_player});
				end
				
				return;
			end
		end
		
		--add to list
		table.insert(controller.assigned_players[_mark], _player);
		controller.notify_observers(controller.add_player_command, {_player});
		
		controller.update_marks();
	end
		--HELPER FUNCS-----------------------------------------------------HF
	controller.clean_mark =
	function(_mark_text)
		return _mark_text;
	end
		--HELPER FUNCS-----------------------------------------------------HF
	
	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	
	return controller;
end 