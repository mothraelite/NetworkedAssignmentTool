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
		for i=1, GetNumRaidMembers(), 1
		do
			local pname = UnitName("raid"..i);
			local class, classFileName = UnitClass("raid"..i);

			if class == "Warrior"
			then
				table.insert(controller.available_interrupts.warrior, pname);
			elseif class == "Rogue"
			then
				table.insert(controller.available_interrupts.rogue, pname);
			elseif class == "Shaman"
			then
				table.insert(controller.available_interrupts.shaman, pname);
			elseif class == "Mage"
			then
				table.insert(controller.available_interrupts.mage, pname);
			end
			
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
	end 

	controller.update_marks 
	=
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

		--set text to selected interrupts
		local key = 1;
		for _, mark in ipairs(controller.marks)
		do
			local text = " ";
			for index, tank in ipairs(controller.assigned_interrupts[mark])
			do
				text = text .. tank .. "  ";
			end

			kat_assignment_labels[key]:SetText(text);
			key = key + 1;
		end
	end 

	controller.post
	= 
	function()
		SendChatMessage(" -- Interrupt Assignments --", "RAID", nil);
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
				
				SendChatMessage("{"..mark.."}: " ..interrupt_list, "RAID", nil);
			end
		end
	end
	
	controller.notify_observers 
	= 
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
		for entry, list_name in ipairs(controller.assigned_interrupts[_mark])
		do
			if _player == list_name
			then
				--remove from list
				table.remove(controller.assigned_interrupts[_mark], entry);

				return;
			end
		end
		
		--add to list
		table.insert(controller.assigned_interrupts[_mark], _player);
	end
	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	
	return controller;
end 