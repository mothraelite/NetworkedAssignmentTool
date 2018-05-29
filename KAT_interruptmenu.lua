KAT_create_interrupt_menu_controller = 
function()
	local controller = {};

	--VARIABLES-------------------------------------------------------------------------------------------------------V
	controller.setup_classes = function(obj)
		obj.warrior = {};
		obj.mage = {};
		obj.shaman = {};
		obj.rogue = {};
	end

	controller.assigned_interrupts = {["skull"]={}, ["x"]={}, ["square"]={},["moon"]={},["triangle"]={},["diamond"]={},["circle"]={},["star"]={}};
	controller.marks = {"skull", "x", "square", "moon", "triangle", "diamond", "circle", "star"};
	controller.available_interrupts = {}; controller.setup_classes (controller.available_interrupts);
	controller.observers = {};

	--currented focus
	controller.current_focus_mark = "";
	controller.current_menu_parent = nil;
	controller.kat_assignment_frames = {["skull"]={}, ["x"]={}, ["square"]={},["moon"]={},["triangle"]={},["diamond"]={},["circle"]={},["star"]={},["MT"]={}};
	controller.post_location = {["channel"]="RAID", ["option"]=nil, ["char"]="r"};
	--VARIABLES-------------------------------------------------------------------------------------------------------V

	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	--function to setup interrupt list
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
				for entry, list_name in ipairs(controller.assigned_interrupts[controller.current_focus_mark])
				do
					if info.text == list_name
					then
						--remove from list
						table.remove(controller.assigned_interrupts[controller.current_focus_mark], entry);
						SendAddonMessage("KAT", "toggle_interrupt-"..controller.current_focus_mark..":"..info.text.."-"..UnitName("player"), "RAID")
						controller.update_marks();
						
						return;
					end
				end
				
				--add to list
				table.insert(controller.assigned_interrupts[controller.current_focus_mark], info.text);
				SendAddonMessage("KAT", "toggle_interrupt-"..controller.current_focus_mark..":"..info.text.."-"..UnitName("player"), "RAID")
				controller.update_marks();
			end
			
			return info;
		end

		if UIDROPDOWNMENU_MENU_LEVEL== 1
		then
			local title = {};
			title.text = "Interrupts"
			title.isTitle = true;
		
			local warriors = {};
			warriors.text = "|cffC79C6EWarrior";
			warriors.value = 1;
			warriors.hasArrow = true;
			warriors.func = function() end;
			
			if table.getn(controller.available_interrupts.warrior) == 0
			then
				warriors.disabled = true;
				warriors.hasArrow = false;
				warriors.text = "|cff545454Warrior";
			end
			
			local mage = {};
			mage.text = "|cff69CCF0Mage";
			mage.value = 2;
			mage.hasArrow = true;
			mage.func = function()  end;
			
			if table.getn(controller.available_interrupts.mage) == 0
			then
				mage.disabled = true;
				mage.hasArrow = false;
				mage.text = "|cff545454Mage";
			end
			
			local rogue= {};
			rogue.text = "|cffFFF569Rogue";
			rogue.value = 3;
			rogue.hasArrow = true;
			rogue.func = function()  end;
			
			if table.getn(controller.available_interrupts.rogue) == 0
			then
				rogue.disabled = true;
				rogue.hasArrow = false;
				rogue.text = "|cff545454Rogue";
			end
			
			local shamans = {};
			shamans.text = "|cff0070DEShaman";
			shamans.value = 4;
			shamans.hasArrow = true;
			shamans.func = function()  end;
			
			if table.getn(controller.available_interrupts.shaman) == 0
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
				if not IsRaidLeader() and not IsRaidOfficer()
				then
					DEFAULT_CHAT_FRAME:AddMessage("KAT: Can not use clear function without being the raid leader or having assist.", 0.6,1.0,0.6);
					return;
				end
			
				controller.clear_mark(controller.current_focus_mark);
			end
			
			UIDropDownMenu_AddButton(title,1);
			UIDropDownMenu_AddButton(warriors, 1);
			UIDropDownMenu_AddButton(mage, 1);
			UIDropDownMenu_AddButton(rogue, 1);
			UIDropDownMenu_AddButton(shamans, 1);
			UIDropDownMenu_AddButton(clear, 1);
		elseif UIDROPDOWNMENU_MENU_LEVEL == 2
		then
			local title = {};
			title.text = "Players"
			title.isTitle = true;
			UIDropDownMenu_AddButton(title, 2);
		
			if UIDROPDOWNMENU_MENU_VALUE == 1 -- warriors
			then
				for i, name in ipairs(controller.available_interrupts.warrior)
				do
				   UIDropDownMenu_AddButton(create_sub_info(name,"|cffC79C6E"), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 2 --mage 
			then
				for i, name in ipairs(controller.available_interrupts.mage)
				do
					UIDropDownMenu_AddButton(create_sub_info(name, "|cff69CCF0"), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 3 --rogue
			then
				for i, name in ipairs(controller.available_interrupts.rogue)
				do
					UIDropDownMenu_AddButton(create_sub_info(name,"|cffFFF569"), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 4 --shaman
			then
				for i, name in ipairs(controller.available_interrupts.shaman)
				do
					UIDropDownMenu_AddButton(create_sub_info(name,"|cff0070DE"), 2);
				end
			end
		end
	end

	--populate available interrupts list
	controller.poll_for_interrupts =
	function()
		--reset current list
		controller.setup_classes(controller.available_interrupts);

		--lets see what we got in the raid
		local i = 1;
		local temp_avail_int = {};
		for i=1, GetNumRaidMembers(), 1
		do
			local pname = UnitName("raid"..i);
			local class, classFileName = UnitClass("raid"..i);

			if class == "Warrior"
			then
				table.insert(controller.available_interrupts.warrior, pname);
				table.insert(temp_avail_int, pname);
			elseif class == "Rogue"
			then
				table.insert(controller.available_interrupts.rogue, pname);
				table.insert(temp_avail_int, pname);
			elseif class == "Shaman"
			then
				table.insert(controller.available_interrupts.shaman, pname);
				table.insert(temp_avail_int, pname);
			elseif class == "Mage"
			then
				table.insert(controller.available_interrupts.mage, pname);
				table.insert(temp_avail_int, pname);
			end
			
		end
		
		--see if any assigned interrupt is no longer available
		local current_interrupters = controller.retrieve_current_unique_players();
		local int_to_remove = {};
		
		--check current tanks vs available tanks
		for _,current_int in ipairs(current_interrupters)
		do
			local tfound = false;
			local unprefix_int_tank = strsub(current_int, 11, strlen(current_int));
			for _,avail_int in ipairs(temp_avail_int)
			do
				if avail_int == unprefix_current_int
				then 
					tfound = true;
					break;
				end
			end 
			
			--not found, mark for removal
			if tfound == false
			then
				table.insert(int_to_remove, current_int);
			end 
			
		end
		
		for _, to_remove in ipairs(int_to_remove)
		do
			--remove all traces of tanks marked for removal from our controller's model list
			local prefix_int = "";
			for _, mark in ipairs(controller.marks)
			do
				for i=1, table.getn(controller.assigned_interrupts[mark]), 1
				do
					--attempting to find tank among assignments
					if controller.assigned_interrupts[mark][i] == to_remove
					then
						table.remove(controller.assigned_interrupts[mark], i); --remove tank from assignment
						break;
					end
				end 
			end
			
			--inform observers that we removed a tank
			controller.notify_observers("remove_interrupter", {to_remove});
		end
	end
	
	controller.retrieve_current_unique_players 
	=
	function()
		local list = {};
		for _,mark in ipairs(controller.marks)
		do
			for index, interrupt in ipairs(controller.assigned_interrupts[mark])
			do
				local interrupt_exists = false;
				for _, uinterrupt in ipairs(list)
				do
					if uinterrupt == interrupt
					then
						interrupt_exists = true;
						break;
					end
				end
				
				if interrupt_exists == false
				then
					table.insert(list, interrupt);
				end
			end
		end
		
		return list;
	end
	
	--get list of assigned interrupts and their marks
	controller.get_current_assignments 
	=
	function()
		local list = {};
		local empty = true;
		for _, mark in ipairs(controller.marks)
		do
			if table.getn(controller.assigned_interrupts[mark]) > 0
			then
				empty = false;
				list[mark] = {};
				for ind, interrupter in ipairs(controller.assigned_interrupts[mark])
				do
					table.insert(list[mark], interrupter);
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
		while table.getn(controller.assigned_interrupts[_mark]) ~= 0
		do
			local interrupter = controller.assigned_interrupts[_mark][1];
			controller.toggle_player(_mark, interrupter)
			SendAddonMessage("KAT", "toggle_interrupt-".._mark..":"..interrupter.."-"..UnitName("player"), "RAID")
		end
		
		controller.update_marks(); --update views
	end
	
	controller.reset
	=
	function()
		--reset current assignments 
		for _, mark in ipairs(controller.marks)
		do
			controller.assigned_interrupts[mark] = {};
		end
	end 
	
	--consume list of  assigned tanks and populate views/list
		--input: list of mark:interrupter
	controller.ingest_players 
	= 
	function(interrupters)
		--reset current assignments 
		controller.reset();
		
		--consume assignments
		for _, interrupter in ipairs(interrupters)
		do
			local tuple = KAT_split(interrupter, ":");
			table.insert(controller.assigned_interrupts[tuple[1]], tuple[2]);
		end 
		
		controller.update_marks();
	end 

	controller.update_marks 
	=
	function()
		--set text to selected tanks
		for mark_pos, mark in ipairs(controller.marks)
		do
			for index, interrupt in ipairs(controller.assigned_interrupts[mark])
			do
				--do I have enough free frames at this mark?
				if 	index > table.getn(controller.kat_assignment_frames[mark])
				then
					-- I don't, add a frame to view
					local frame = KAT_create_player_frame("tank_player_frame_"..mark.."_"..index, KAT_interrupt_body, interrupt);
					frame.mark = mark;
					frame.colored_name = interrupt;
					frame:SetScript("OnClick", 
					function(self, button, down)
						if not IsRaidLeader() and not IsRaidOfficer() 
						then 
							DEFAULT_CHAT_FRAME:AddMessage("KAT: You need to be the raid leader OR have assist to make changes", 0.6,1.0,0.6);
							return;
						end
						if button == "RightButton" 
						then 
							SendAddonMessage("KAT", "toggle_interrupt-"..self.mark..":"..self.colored_name.."-"..UnitName("player"), "RAID");
							controller.toggle_player(self.mark, self.colored_name);  
						end 
					end);
					
					if index > 3
					then
						frame:SetPoint("TOPLEFT", -40+index%3*133, 10-(mark_pos*40)-19);
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
					local uncolored_name = string.sub(interrupt,  11, strlen(interrupt));
					local r,g,b = KAT_hex2rgb(string.sub(interrupt, 5,11));
					
					local frame = controller.kat_assignment_frames[mark][index];
					frame.mark = mark;
					frame.colored_name = interrupt;
					frame.name:SetText(uncolored_name);
					frame.model:SetUnit(KAT_retrieve_unitid_from_name(uncolored_name));
					frame.model:SetCamera(0)
					frame.bg:SetTexture(r/255,g/255,b/255,0.75);
					frame.bg:SetAllPoints(true);
					
					frame:Show();
				end
				
			end

			--do I need to adjust frames pos/size at this mark?
			if table.getn(controller.assigned_interrupts[mark])/3 > 1
			then
				--check if already smooshed
				if controller.kat_assignment_frames[mark][1]:GetHeight() > 19
				then --not smooshed yet
					for i=1, 3, 1
					do
						local interrupt_frame = controller.kat_assignment_frames[mark][i];
						
						--smoosh 
						interrupt_frame:SetHeight(19);
						interrupt_frame.highlight:SetHeight(19);
						interrupt_frame.name:SetPoint("CENTER",0, 0)
						
						--disable model view
						interrupt_frame.model:Hide();
					end
					
				end
			else
				--check if already enlarged and in charge
				if table.getn(controller.kat_assignment_frames[mark]) > 0
				then
					if controller.kat_assignment_frames[mark][1]:GetHeight() < 38
					then --not enlarged yet nor incharge
						for i=1, table.getn(controller.assigned_interrupts[mark]), 1
						do
							local interrupt_frame = controller.kat_assignment_frames[mark][i];
							
							--enlarge
							interrupt_frame:SetHeight(38);
							interrupt_frame.highlight:SetHeight(38);
							interrupt_frame.name:SetPoint("CENTER",10, 0)
							
							--enable model view
							interrupt_frame.model:Show();
						end
					end
				end
			end
			
			--Do I have extra frames?
			local  i = table.getn(controller.kat_assignment_frames[mark]);
			while i > table.getn(controller.assigned_interrupts[mark])
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
				KatInterruptPostLabel:SetText(": "..name);
			else
				KatInterruptPostChannelEdit:SetText(controller.post_location["char"]);
				DEFAULT_CHAT_FRAME:AddMessage("KAT: post location " .. chara .. " is not an acceptable post location", 0.6,1.0,0.6);
			end
		else
			--check if I have an acceptable char
			if _chara == "r"
			then
				controller.post_location["channel"] = "RAID";
				controller.post_location["option"] = nil;
				KatInterruptPostLabel:SetText(": raid");
				controller.post_location["char"] = _chara;
			elseif _chara == "p"
			then
				controller.post_location["channel"] = "PARTY";
				controller.post_location["option"] = nil;
				KatInterruptPostLabel:SetText(": party");
				controller.post_location["char"] = _chara;
			elseif _chara == "o"
			then
				controller.post_location["channel"] = "OFFICER";
				controller.post_location["option"] = nil;
				KatInterruptPostLabel:SetText(": officer");
				controller.post_location["char"] = _chara;
			elseif _chara == "g"
			then
				controller.post_location["channel"] = "GUILD";
				controller.post_location["option"] = nil;
				KatInterruptPostLabel:SetText(": guild");
				controller.post_location["char"] = _chara;
			elseif c_hara == "s"
			then
				controller.post_location["channel"] = "SAY";
				controller.post_location["option"] = nil;
				KatInterruptPostLabel:SetText(": say");
				controller.post_location["char"] = _chara;
			else
				KatInterruptPostChannelEdit:SetText(controller.post_location["char"]);
				DEFAULT_CHAT_FRAME:AddMessage("KAT: post location " .. chara .. " is not an acceptable post location", 0.6,1.0,0.6);
			end
		end
	end
	
	controller.post
	= 
	function()
		SendChatMessage(" -- Interrupt Assignments --", controller.post_location["channel"], nil, controller.post_location["option"]);
		for _, mark in ipairs(controller.marks)
		do
			if table.getn(controller.assigned_interrupts[mark]) > 0
			then
				local interrupt_list = "";
				for index, interrupt in ipairs(controller.assigned_interrupts[mark])
				do
					--if there was color applied. shitty server doesn't allow colored text in chat
					if strlen(interrupt) > 10
					then
						interrupt = strsub(interrupt, 11, strlen(interrupt));
					end
				
					interrupt_list = interrupt_list .. interrupt .. " ";
				end
				
				if mark == "x"
				then
					mark = "Cross";
				end
				
				SendChatMessage("{"..mark.."}: " ..interrupt_list, controller.post_location["channel"], nil, controller.post_location["option"]);
			end
		end
	end
	
	controller.notify_observers 
	= 
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

	controller.toggle_player
	=
	function(_mark, _player)
		--Am I in the list already? 
		for entry, list_name in ipairs(controller.assigned_interrupts[_mark])
		do
			if _player == list_name
			then
				--remove from list
				table.remove(controller.assigned_interrupts[_mark], entry);
				controller.update_marks();
				return;
			end
		end
		
		--add to list
		table.insert(controller.assigned_interrupts[_mark], _player);
		controller.update_marks();
	end
	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	
	return controller;
end 