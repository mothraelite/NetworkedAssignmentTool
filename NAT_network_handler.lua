	--[[
				@Author: moth<milaninavid@gmail.com>
				Title: Network handler
				Description: Handles most of the networking logic between clients
				Definitions:
					-Message prefix: NAT
					-Data is sent via Command-message-sender with the prefix NAT
	--]]

function NAT_create_network_handler(_tankc, _healerc, _interruptc)
	local controller = {};
	
	--VARIABLES---------------------------------------------------------------------V
	controller.master = nil;
	controller.tank_controller = _tankc;
	controller.healer_controller = _healerc;
	controller.interrupt_controller = _interruptc;
	controller.state = -1; -- -1: not setup 0: trying to setup 1: setup 
	controller.response_state = 1; --0: network waiting for response 1: nothing going on || note: this is for non-setup related responses
	controller.setup = {["tanks"]=false,["healers"]=false,["interrupters"]=false,["master"]=false};
	--VARIABLES---------------------------------------------------------------------V
	
	--FUNCTIONS---------------------------------------------------------------------F
		-----------------------------REQUESTS-------------------------------REQ
	controller.request_master
	=
	function()
		if controller.state ~= 1
		then
			return;
		end
		
		if UnitInRaid("player") == nil
		then
			return;
		end
	
		if  IsRaidOfficer()  or IsRaidLeader() 
		then
			SendAddonMessage("NAT", "request_master-"..UnitName("player").."-"..UnitName("player"), "RAID");
			controller.master = UnitName("player");
			NATMasterLabel:SetText("Master: " .. UnitName("player"));
		end
	end

	controller.request_setup
	=
	function()
		if controller.state == 1
		then
			DEFAULT_CHAT_FRAME:AddMessage("NAT: Already setup.", 0.6,1.0,0.6);
			return;
		end
		
		if UnitInRaid("player") == nil
		then
			return;
		end
		
		controller.state = 0; --waiting for setup
		SendAddonMessage("NAT", "request_setup-"..UnitName("player").."-"..UnitName("player"), "RAID");
		
		--Set timed event to check if i get a full response in 2 seconds. 
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
					NAT_set_alarm(3, partial_setup);
				else  --no reply
					--fire function after 2 seconds if no response because no setup available in raid
					local no_setup = 
					function()
						if controller.state == 0
						then
							if IsRaidLeader() or IsRaidOfficer()
							then
								SendAddonMessage("NAT", "reset- -"..UnitName("player"), "RAID");
								controller.reset_setup();
							
								controller.setup["healers"] = true;
								controller.setup["tanks"] = true;
								controller.setup["interrupters"] = true;
								controller.setup["master"] = true;
								controller.state = 1;
								controller.request_master();
							else
								controller.request_setup();
							end
							
						end
					end
					NAT_set_alarm(2, no_setup);
				end	
			end
		end
		NAT_set_alarm(2, func);
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
				SendAddonMessage("NAT", "master_is-"..controller.master.."-"..UnitName('player'), "RAID");
			else 
				controller.request_master();
				SendAddonMessage("NAT", "master_is-"..controller.master.."-"..UnitName('player'), "RAID");
			end
		end
	end

	controller.return_setup
	=
	function(message)
		if controller.master ~= nil and controller.state == 1 and (IsRaidOfficer()  or IsRaidLeader())
		then	
			--is current master offline?
			local name, rank, sg, level, class, fileName, zone, online, isDead, role, isML = controller.get_raid_member_info(controller.master);
			if online == nil
			then
				controller.request_master();
			end
		end
	
		--let the master list holder deal with informing the person asking for info
		if controller.master == UnitName("player")
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
			if current_tanks ~= nil
			then
				tanks = "";
				for mark, list in pairs(current_tanks)
				do
					for ind, tank in ipairs(list)
					do
						tank = string.sub(tank, 11, strlen(tank));
						tanks = tanks.." ".. mark ..":".. tank;
					end
				end
				tanks = string.sub(tanks, 2, strlen(tanks));
			end
			
			local healers = "empty";
			if current_healers ~= nil
			then 
				healers = "";
				for mark, list in pairs(current_healers)
				do
					for ind, healer in ipairs(list)
					do
						local tmark = mark;
						if tmark ~= "Raid"
						then
							tmark = string.sub(tmark, 11, strlen(tmark));
						end 
					
						healer = string.sub(healer, 11, strlen(healer));
						healers = healers.." "..tmark..":".. healer;
					end
				end
				healers = string.sub(healers, 2, strlen(healers));
			end
			
			local interrupters = "empty";
			if current_interrupters ~= nil
			then 
				interrupters = "";
				for mark, list in pairs(current_interrupters)
				do
					for ind, interrupt in ipairs(list)
					do
						interrupt = string.sub(interrupt, 11, strlen(interrupt));
						interrupters = interrupters.." "..mark..":"..interrupt;
					end
				end
				interrupters = string.sub(interrupters, 2, strlen(interrupters));
			end

			--send it out
			SendAddonMessage("NAT", "setup_master-"..UnitName("player").."-"..UnitName("player"), "RAID");
			SendAddonMessage("NAT", "setup_tanks-"..tanks.."-"..UnitName("player"), "RAID");
			SendAddonMessage("NAT", "setup_healers-"..healers.."-"..UnitName("player"), "RAID");
			SendAddonMessage("NAT", "setup_interrupters-"..interrupters.."-"..UnitName("player"), "RAID");
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
		local args = NAT_split(message, ":"); --split mark and player
		args[2] = NAT_retrieve_class_color(NAT_retrieve_player_class(args[2])) .. args[2];
		controller.tank_controller.toggle_player(args[1], args[2]);
	end
	
	controller.toggle_healer
	=
	function(message)
		local args = NAT_split(message, ":"); -- split mark and player 
		if args[1] ~= "Raid"
		then 
			args[1] = NAT_retrieve_class_color(NAT_retrieve_player_class(args[1])) .. args[1];
		end
		
		args[2] = NAT_retrieve_class_color(NAT_retrieve_player_class(args[2])) .. args[2];
		controller.healer_controller.toggle_player(args[1],args[2]);
	end
	
	controller.toggle_interrupter
	=
	function(message)
		local args = NAT_split(message, ":"); -- split mark and player 
		args[2] = NAT_retrieve_class_color(NAT_retrieve_player_class(args[2])) .. args[2];
		controller.interrupt_controller.toggle_player(args[1],args[2]);
	end
	
	controller.setup_master
	=
	function(message)
		--unless im looking for a setup, dont do it
		if controller.state ~= 0
		then 
			return;
		end
	
		controller.master = message;
		NATMasterLabel:SetText("Master: " .. message);
		controller.setup["master"] = true;
		if controller.setup["healers"] and controller.setup["tanks"] and controller.setup["interrupters"] and controller.setup["master"]
		then
			controller.state = 1;
			DEFAULT_CHAT_FRAME:AddMessage("NAT: You are now setup.", 0.6,1.0,0.6);
		end
	end
	
	controller.setup_tanks
	=
	function(message)
		--unless im looking for a setup, dont do it
		if controller.state ~= 0
		then 
			return;
		end
	
		if message ~= "empty"
		then
			local split_message = NAT_split(message, " ");
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
			controller.state = 1; --controller.setup["healers"] and controller.setup["tanks"] and controller.setup["interrupters"] and controller.setup["master"]
			DEFAULT_CHAT_FRAME:AddMessage("NAT: You are now setup.", 0.6,1.0,0.6);
		end
	end
	
	controller.setup_healers
	=
	function(message)
		--unless im looking for a setup, dont do it
		if controller.state ~= 0
		then 
			return;
		end
	
		if message ~= "empty"
		then
			local split_message = NAT_split(message, " ");
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
			DEFAULT_CHAT_FRAME:AddMessage("NAT: You are now setup.", 0.6,1.0,0.6);
		end
	end
	
	controller.setup_interrupters
	=
	function(message)
		--unless im looking for a setup, dont do it
		if controller.state ~= 0
		then 
			return;
		end
	
		if message ~= "empty"
		then 
			local split_message = NAT_split(message, " ");
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
			DEFAULT_CHAT_FRAME:AddMessage("NAT: You are now setup.", 0.6,1.0,0.6);
		end
	end
		-------------------------------HELPER-------------------------------HEL
	controller.extract_command_and_message
	=
	function(_message)
		local split = NAT_split(_message, "-");
		local command = split[1];
		local message = split[2];
		local sender = split[3];
		return command, message, sender;
	end
	
	controller.reset_setup
	=
	function()
		controller.tank_controller.reset();
		controller.healer_controller.reset();
		controller.interrupt_controller.reset();
	
		controller.state = -1;
		controller.master = nil;
		NATMasterLabel:SetText("Master: None");
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

	--this update will happen every tick rather than when visible and every second.
	controller.update
	=
	function()

	end
	
	--FUNCTIONS---------------------------------------------------------------------F
	
	return controller;
end