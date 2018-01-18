function KAT_create_network_handler(_tankc, _healerc, _interruptc)
	--[[local controller = {};
	
	--VARIABLES---------------------------------------------------------------------V
	controller.master = nil;
	controller.tank_controller = _tankc;
	controller.healer_controller = _healerc;
	controller.interrupt_controller = _interruptc;
	--VARIABLES---------------------------------------------------------------------V
	
	--FUNCTIONS---------------------------------------------------------------------F
	controller.get_master()
	= 
	function()
		return controller.master;
	end
	
	controller.request_master()
	=
	function()
		if  IsRaidOfficer()
		then
			SendAddonMessage("KAT_request_master", UnitName("player"), "RAID");
			controller.master = UnitName("player");
		end
	end

	controller.request_setup()
	=
	function()
		controller.state = 0;
		SendAddonMessage("KAT_request_setup", UnitName("player"), "RAID");
	end

	controller.event_handler 
	=
	function(_kat_event, message)
		if _kat_event == "KAT_request_master"
		then
			controller.master = message;
		elseif _kat_event == "KAT_request_setup"
		then
			--let the master list holder deal with informing the person asking for info
			if controller.master == UnitName("player") and UnitName("player") ~= message
			then
				--Expected args: player name
				--Expected return: 3 whispers with current tanks,heals, and interrupts
			
				--retrieve current tanks 
				local current_tanks = controller.tank_controller.get_current_assignments();
				--retrieve current healers
				local current_healers = controller.healer_controller.get_current_assignments();
				--retrieve current interrupters 
				local current_interrupters = controller.interrupt_controller.get_current_assignments();
				
				--encode data
				local data = "master " ..UnitName("player").. " tank";
				for i, mark in ipairs(current_tanks)
				do
					for _, tank in ipairs(mark.assignments)
					do
						data = data .. " ".. mark.mark ..":".. tank ;
					end
				end
				
				data = data .. " heal";
				for i, mark in ipairs(current_healers)
				do
					for _, healer in ipairs(mark.assignments)
					do
						data = data .. " "..mark.mark..":".. healer;
					end
				end
				
				data = data .. " interrupt";
				for i, mark in ipairs(current_interrupters)
				do
					for _, interrupt in ipairs(mark.assignments)
					do
						data = data .. " " .. mark.mark..":"..interrupt;
					end
				end
				
				--send it out
				SendAddonMessage("KAT_setup",  data, "WHISPER", message);
			end
		elseif _kat_event == "KAT_setup"
		then
			--Expected args: 3 whispers with current tanks,heals, and interrupt
			--Expected return: none
			
			--decode message
			local split_message = split(message, " ");
			local state = -1; 
			local tanks = {};
			local healers = {};
			local interrupters = {};
			for i, str in ipairs(split_message)
			do
				-- find role
				if str == "master"
				then
					state = 0;
				elseif str == "tank"
				then
					state = 1;
				elseif str == "heal"
				then
					state = 2;
				elseif str == "interrupt"
				then
					state = 3;
				else
					--define player
					if state == 0 --master found
					then
						controller.master = str;
					elseif state == 1 --this is a tank i've found 
					then
						table.insert(tanks, str);
					elseif state == 2 --this is a healer i've found 
					then
						table.insert(healers, str);
					elseif state == 3 --this is a interrupter i've found
						table.insert(interrupters, str);
					end 
				end 
			end
			
			--send tanks to tank controller
			--send healers to healer controller
			--send interrupters to interrupt controller 
		elseif _kat_event == "KAT_add_healer"
		then
		
		elseif _kat_event == "KAT_remove_healer"
		then
		
		elseif _kat_event == "KAT_add_tank"
		then
		
		elseif _kat_event == "KAT_remove_tank"
		then
		
		elseif _kat_event == "KAT_add_interrupter"
		then
		
		elseif _kat_event == "KAT_remove_itnerrupter"
		then
		
		end
	end
	--FUNCTIONS---------------------------------------------------------------------F
	
	return controller;--]]
end