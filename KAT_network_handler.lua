	--[[
				@Author: moth<milaninavid@gmail.com>
				Title: Network handler
				Description: Handles most of the networking logic between clients
				Definitions:
					-Message prefix: KAT
					-Data is sent via Command-message-sender with the prefix KAT
	--]]

function KAT_create_network_handler(_tankc, _healerc, _interruptc)
	local controller = {};
	
	--VARIABLES---------------------------------------------------------------------V
	controller.master = nil;
	controller.tank_controller = _tankc;
	controller.healer_controller = _healerc;
	controller.interrupt_controller = _interruptc;
	controller.state = -1;
	--VARIABLES---------------------------------------------------------------------V
	
	--FUNCTIONS---------------------------------------------------------------------F
		-----------------------------REQUESTS-------------------------------REQ
	controller.request_master
	=
	function()
		if controller.state ~= 1
		then
			DEFAULT_CHAT_FRAME:AddMessage("KAT: Can't request for master without being setup first.", 0.6,1.0,0.6);
			return;
		end
		
		if UnitInRaid("player") == nil
		then
			return;
		end
	
		if  IsRaidOfficer()  or IsRaidLeader() 
		then
			SendAddonMessage("KAT", "request_master-"..UnitName("player").."-"..UnitName("player"), "RAID");
			controller.master = UnitName("player");
			KatMasterLabel:SetText("Master: " .. UnitName("player"));
			DEFAULT_CHAT_FRAME:AddMessage("KAT: You are now the current master and setup", 0.6,1.0,0.6);
		end
	end

	controller.request_setup
	=
	function()
		if controller.state == 1
		then
			DEFAULT_CHAT_FRAME:AddMessage("KAT: Already setup.", 0.6,1.0,0.6);
			return;
		end
		
		if UnitInRaid("player") == nil
		then
			return;
		end
		
		controller.state = 0; --waiting for setup
		SendAddonMessage("KAT", "request_setup-"..UnitName("player").."-"..UnitName("player"), "RAID");
		
		--Set timed event to take request master if im not setup in 5 seconds
		local func = 
		function()
			if controller.master == nil 
			then
				controller.state = 1;
				controller.request_master();
			end 
		end
		KAT_set_alarm(5, func);
	end
		----------------------END OF REQUESTS-------------------------REQ
		
		------------------------------RETURNS--------------------------------RET
	
	
		
	controller.get_master
	= 
	function()
		return controller.master;
	end

	controller.return_setup
	=
	function(message)
		--let the master list holder deal with informing the person asking for info
		if controller.master == UnitName("player") and UnitName("player") ~= message
		then
			--Expected args: player name
				--Expected return:  whisper with current tanks,heals, and interrupts
		
			--retrieve current tanks 
			local current_tanks = controller.tank_controller.get_current_assignments();
			--retrieve current healers
			local current_healers = controller.healer_controller.get_current_assignments();
			--retrieve current interrupters 
			local current_interrupters = controller.interrupt_controller.get_current_assignments();
			
			--encode data
			--------------------------------------
			-- space denotes new player or change of state
			-- states are defined by the following keywords: master, tank, heal, interrupt. anything following these keywords other than other states will be players
			-- players are defined by their mark:name.  IE: skull:Katcheese
			-- 
		
			local data = "master " ..UnitName("player").. " tank";
			for mark, list in pairs(current_tanks)
			do
				for _, tank in ipairs(list)
				do
					data = data .. " ".. mark ..":".. tank ;
				end
			end
			
			data = data .. " heal";
			for mark, list in pairs(current_healers)
			do
				for _, healer in ipairs(list)
				do
					data = data .. " "..mark..":".. healer;
				end
			end
			
			data = data .. " interrupt";
			for mark, list in pairs(current_interrupters)
			do
				for _, interrupt in ipairs(list)
				do
					data = data .. " " .. mark..":"..interrupt;
				end
			end
			
			--send it out
			SendAddonMessage("KAT",  "setup-"..data.."-"..UnitName("player"), "WHISPER", message);
		end
	end
		----------------------END OF RETURNS-------------------------RET
	
		--------------------RESPONSE HANDELING--------------------RH
	controller.toggle_tank
	=
	function(message)
		local args = KAT_split(message, ":"); --split mark and player
		
		controller.tank_controller.toggle_player(args[1], args[2]);
	end
	
	controller.toggle_healer
	=
	function(message)
		local args = KAT_split(message, ":"); -- split mark and player 
		controller.healer_controller.toggle_player(args[1],args[2]);
	end
	
	controller.toggle_interrupter
	=
	function(message)
		local args = KAT_split(message, ":"); -- split mark and player 
		controller.interrupt_controller.toggle_player(args[1],args[2]);
	end
	
	controller.setup_kat
	=
	function(message)
		controller.state = 1;
	
		--Expected args: whisper with current tanks,heals, and interrupt
			--Expected return: none
			
			--decode message
				--expected encoding
				--------------------------------------
				-- space denotes new player or change of state
				-- states are defined by the following keywords: master, tank, heal, interrupt. anything following these keywords other than other states will be players
				-- players are defined by their mark:name.  IE: skull:Katcheese
				-- note: dont remove mark from player. let the other controllers handle that as its too specific to their logic to make sense to do it here
		local split_message = KAT_split(message, " ");
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
					KatMasterLabel:SetText("Master: " .. str);
				elseif state == 1 --this is a tank i've found 
				then
					table.insert(tanks, str);
				elseif state == 2 --this is a healer i've found 
				then
					table.insert(healers, str);
				elseif state == 3 --this is a interrupter i've found
				then
					table.insert(interrupters, str);
				end 
			end 
		end
		
		--send tanks to tank controller
		controller.tank_controller.ingest_players(tanks);
		--send healers to healer controller
		controller.healer_controller.ingest_players(healers);
		--send interrupters to interrupt controller 
		controller.interrupt_controller.ingest_players(interrupters);
		
		DEFAULT_CHAT_FRAME:AddMessage("KAT: You are now setup.", 0.6,1.0,0.6);
	end

	controller.update
	=
	function()
		
	end
	
		-------------------------------HELPER-------------------------------HEL
	controller.extract_command_and_message
	=
	function(_message)
		--I give all of 0 shits about client side performance as its a 10 year old game
		local split = KAT_split(_message, "-");
		local command = split[1];
		local message = split[2];
		local sender = split[3];
		
		return command, message, sender;
	end
		------------------------END OF HELPER-------------------------HEL
	
	--FUNCTIONS---------------------------------------------------------------------F
	
	return controller;
end