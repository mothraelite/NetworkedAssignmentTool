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
	controller.state = -1; -- -1: not setup 0: trying to setup 1: setup
	controller.setup = {["tank"]=false,["healers"]=false,["interrupters"]=false,["master"]=false};
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
		
		--Set timed event to check if i get a full response in 3 seconds. 
		local func = 
		function()
			--did not get a full response or empty response.
			if not controller.setup["healers"] or not controller.setup["tanks"] or not controller.setup["interrupters"] or not controller.setup["master"]
			then
				--did i get a partial reply?
				if controller.setup["healers"] or controller.setup["tanks"] or controller.setup["interrupters"] or controller.setup["master"]
				then--partial reply, might be lagging on either end
					--wait 3 seconds and request again if needed
					local partial_setup =
					function()
						--still not setup
						if controller.state ~= 1
						then 
							--request again
								--reset state
							controller.reset_setup();
								--request
							controller.request_setup();
						end 
					end
					KAT_set_alarm(3, partial_setup);
				else  --no reply
					--ask if master is offline
					SendAddonMessage("KAT", "who_is_master-"..UnitName("player").."-"..UnitName("player"), "RAID");
					
					--fire function after 3 seconds if no response because no setup available in raid
					local no_setup = 
					function()
						if controller.state == 0
						then
							controller.reset_setup();
							
							if  IsRaidOfficer()  or IsRaidLeader() 
							then
								controller.state = 1;
								controller.request_master();
							else
								controller.state = -1;
								SendAddonMessage("KAT", "reset- -"..UnitName("player"), "RAID");
							end
						end
					end
					KAT_set_alarm(3, no_setup);
				end	
			end
		end
		KAT_set_alarm(3, func);
	end
		----------------------END OF REQUESTS-------------------------REQ
		
		------------------------------RETURNS--------------------------------RET
	
	controller.return_master
	=
	function(message)
		if controller.master ~= nil and controller.state == 1
		then	
			--is current master offline?
			local name, rank, sg, level, class, fileName, zone, online, isDead, role, isML = controller.get_raid_member_info(controller.master);
			if online ~= nil
			then
				SendAddonMessage("KAT", "master_is-"..controller.master.."-"..UnitName('player'), "WHISPER", message);
			else 
				controller.request_master();
				SendAddonMessage("KAT", "master_is-"..controller.master.."-"..UnitName('player'), "WHISPER", message);
			end
		end
	end

	controller.return_setup
	=
	function(message)
		--let the master list holder deal with informing the person asking for info
		if controller.master == UnitName("player") and UnitName("player") ~= message
		then
			--Expected args: player name
				--Expected return:  whisper with current master,tanks,heals, and interrupts
		
			--retrieve current tanks 
			local current_tanks = controller.tank_controller.get_current_assignments();
			--retrieve current healers
			local current_healers = controller.healer_controller.get_current_assignments();
			--retrieve current interrupters 
			local current_interrupters = controller.interrupt_controller.get_current_assignments();
			
			--encode data
			--------------------------------------
			-- space denotes new player 

			local tanks = "empty";
			if table.getn(current_tanks) > 0
			then
				tanks = "";
				for mark, list in pairs(current_tanks)
				do
					for ind, tank in ipairs(list)
					do
						tanks = tanks.." ".. mark ..":".. tank;
					end
				end
				tanks = string.sub(tanks, 2, strlen(tanks));
			end
			
			local healers = "empty";
			if table.getn(current_healers) > 0
			then 
				healers = "";
				for mark, list in pairs(current_healers)
				do
					for ind, healer in ipairs(list)
					do
						healers = healers.." "..mark..":".. healer;
					end
				end
				healers = string.sub(healers, 2, strlen(healers));
			end
			
			local interrupters = "empty";
			if table.getn(current_interrupters) > 0
			then 
				interrupters = "";
				for mark, list in pairs(current_interrupters)
				do
					for ind, interrupt in ipairs(list)
					do
						interrupters = interrupters.." "..mark..":"..interrupt;
					end
				end
				interrupters = string.sub(interrupters, 2, strlen(interrupters));
			end

			--send it out
			SendAddonMessage("KAT", "setup_master-"..UnitName("player").."-"..UnitName("player"), "WHISPER", message);
			SendAddonMessage("KAT", "setup_tanks-"..tanks.."-"..UnitName("player"), "WHISPER", message);
			SendAddonMessage("KAT", "setup_healers-"..healers.."-"..UnitName("player"), "WHISPER", message);
			SendAddonMessage("KAT", "setup_interrupters-"..interrupters.."-"..UnitName("player"), "WHISPER", message);
		end
	end
		----------------------END OF RETURNS-------------------------RET
	
		--------------------RESPONSE HANDELING--------------------RH
			--Toggle
			-------------------------------
			--
			--expected arg: mark:tank
			--return: nothing
			--whats it do? when other users send info about what they are doing (an assignment), we need to interpret it so we send it to their respective controllers here.
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
	
	controller.setup_master
	=
	function(message)
		controller.master = message;
		KatMasterLabel:SetText("Master: " .. message);
		controller.setup["master"] = true;
		if controller.setup["healers"] and controller.setup["tanks"] and controller.setup["interrupters"] and controller.setup["master"]
		then
			controller.state = 1;
			DEFAULT_CHAT_FRAME:AddMessage("KAT: You are now setup.", 0.6,1.0,0.6);
		end
	end
	
	controller.setup_tanks
	=
	function(message)
		if message ~= "empty"
		then
			local split_message = KAT_split(message, " ");
			local tanks = {};
			
			for i, str in ipairs(split_message)
			do
				table.insert(tanks,str);
			end
			
			--send tanks to tank controller
			controller.tank_controller.ingest_players(tanks);
		end	
		
		controller.setup["tanks"] = true;
		if controller.setup["healers"] and controller.setup["tanks"] and controller.setup["interrupters"] and controller.setup["master"]
		then
			controller.state = 1;
			DEFAULT_CHAT_FRAME:AddMessage("KAT: You are now setup.", 0.6,1.0,0.6);
		end
	end
	
	controller.setup_healers
	=
	function(message)
		if message ~= "empty"
		then
			local split_message = KAT_split(message, " ");
			local healers = {};
			
			for i, str in ipairs(split_message)
			do
				table.insert(healers,str);
			end
		
			--send tanks to heal controller
			controller.healer_controller.ingest_players(healers);
		end 
		
		controller.setup["healers"] = true;
		if controller.setup["healers"] and controller.setup["tanks"] and controller.setup["interrupters"] and controller.setup["master"]
		then
			controller.state = 1;
			DEFAULT_CHAT_FRAME:AddMessage("KAT: You are now setup.", 0.6,1.0,0.6);
		end
	end
	
	controller.setup_interrupters
	=
	function(message)
		if message ~= "empty"
		then 
			local split_message = KAT_split(message, " ");
			local interrupters = {};
			
			for i, str in ipairs(split_message)
			do
				table.insert(interrupters,str);
			end
		
			--send tanks to interrupt controller
			controller.interrupt_controller.ingest_players(interrupters);
		end
		
		controller.setup["interrupters"] = true;
		if controller.setup["healers"] and controller.setup["tanks"] and controller.setup["interrupters"] and controller.setup["master"]
		then
			controller.state = 1;
			DEFAULT_CHAT_FRAME:AddMessage("KAT: You are now setup.", 0.6,1.0,0.6);
		end
	end

	controller.update
	=
	function()
		
	end
	
		-------------------------------HELPER-------------------------------HEL
	controller.extract_command_and_message
	=
	function(_message)
		local split = KAT_split(_message, "-");
		local command = split[1];
		local message = split[2];
		local sender = split[3];
		
		return command, message, sender;
	end
	
	controller.reset_setup
	=
	function()
		controller.tank_controller.reset();
		controller.tank_controller.reset();
	
		controller.state = -1;
		controller.setup["healers"] = false;
		controller.setup["tanks"] = false;
		controller.setup["master"] = false;
		controller.setup["interrupters"] = false;
	end
	
	controller.get_raid_member_info
	=
	function(_name)
		--Vanilla API does not have a way to get info by name so here we are
		for i=1, GetNumRaidMembers(), 1
		do
			--player found. return shit
			if UnitName("raid"..i) == controller.name
			then
				return GetRaidRosterInfo(i);
			end
		end
		
		return nil;
	end
		------------------------END OF HELPER-------------------------HEL
	
	--FUNCTIONS---------------------------------------------------------------------F
	
	return controller;
end