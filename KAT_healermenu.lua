KAT_create_healer_menu_controller = 
function()
	local controller = {};

	--VARIABLES-------------------------------------------------------------------------------------------------------V
	controller.setup_classes = function(obj)
		obj.paladin = {};
		obj.shaman = {};
		obj.druid = {};
		obj.priest = {};
	end

	controller.assigned_tanks = {};
	controller.available_healers = {}; controller.setup_classes (controller.available_healers);
	controller.assigned_healers = {};

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
						controller.update_marks();
						
						return;
					end
				end
				
				--add to list
				table.insert(controller.assigned_healers[controller.current_focus_mark], info.text);
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
			druids.text = "|cffFF7D0ADruid";
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
			paladins.text = "|cffF58CBAPaladin";
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
			priests.text = "|cffFFFFFFPriest";
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
			shamans.text = "|cff0070DEShaman";
			shamans.value = 4;
			shamans.hasArrow = true;
			shamans.func = function()  end;
			
			if table.getn(controller.available_healers.shaman) == 0
			then
				shamans.disabled = true;
				shamans.hasArrow = false;
				shamans.text = "|cff545454Shaman";
			end
			
			UIDropDownMenu_AddButton(title, 1);
			UIDropDownMenu_AddButton(druids, 1);
			UIDropDownMenu_AddButton(paladins, 1);
			UIDropDownMenu_AddButton(priests, 1);
			UIDropDownMenu_AddButton(shamans, 1);
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
					UIDropDownMenu_AddButton(create_sub_info(name,"|cffFF7D0A"), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE== 2 --paladins
			then
				for i, name in ipairs(controller.available_healers.paladin)
				do
					UIDropDownMenu_AddButton(create_sub_info(name, "|cffF58CBA"), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 3 --priest
			then
				for i, name in ipairs(controller.available_healers.priest)
				do
					UIDropDownMenu_AddButton(create_sub_info(name,"|cffFFFFFF"), 2);
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 4 --shaman
			then
				for i, name in ipairs(controller.available_healers.shaman)
				do
					UIDropDownMenu_AddButton(create_sub_info(name,"|cff0070DE"), 2);
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
		for i=1, GetNumRaidMembers(), 1
		do
			local pname = UnitName("raid"..i);
			local class, classFileName = UnitClass("raid"..i);

			if class == "Druid"
			then
				table.insert(controller.available_healers.druid, pname);
			elseif class == "Priest"
			then
				table.insert(controller.available_healers.priest, pname)
			elseif class == "Paladin"
			then
				table.insert(controller.available_healers.paladin, pname);
			elseif class == "Shaman"
			then
				table.insert(controller.available_healers.shaman, pname);
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
		for _, mark in ipairs(controller.assigned_tanks)
		do
			local text = " ";
			for index, tank in ipairs(controller.assigned_healers[mark])
			do
				text = text .. tank .. "  ";
			end

			kat_assignment_labels[key]:SetText(text);
			key = key + 1;
		end
	end 

	controller.post = 
	function()
		SendChatMessage(" -- Healing Assignments --", "RAID", nil);
		for _, mark in ipairs(controller.assigned_tanks)
		do
			SendChatMessage(mark..": none", "RAID", nil);
			if table.getn(controller.assigned_healers[mark]) > 0
			then
				local healer_list = "";
				for index, healer in ipairs(controller.assigned_healers[mark])
				do
					--if there was color applied. shitty server doesn't allow colored text in chat
					if strlen(healer) > 10
					then
						healer = strsub(healer, 11, strlen(healer));
					end
				
					healer_list = healer_list .. healer .. " ";
				end
				
				if strlen(mark) > 10
				then
					mark = strsub(mark, 11, strlen(mark)) ;
				end
				
				SendChatMessage(mark..": " ..healer_list, "RAID", nil);
			else
				SendChatMessage(mark..": none", "RAID", nil);
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
			end
		end
		
		for i=8, table.getn(controller.assigned_tanks)+1, -1
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
			end
		end
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
	--FUNCTIONS-------------------------------------------------------------------------------------------------------F
	
	return controller;
end 