local alarms = {};
function NAT_set_alarm(_time, _function)
	if _function == nil
	then
		return;
	end
	
	if _time <= 0
	then
		_function();
	else 
		local alarm = {};
		alarm.time = _time;
		alarm.func = _function;
		table.insert(alarms, alarm);
	end
end

function NAT_update_alarms()
	local size = table.getn(alarms);
	for i=1, table.getn(alarms), 1
	do
		local alarm = alarms[i];
		alarm.time = alarm.time - 1;
		if alarm.time <= 0
		then
			alarm.func();
			table.remove(alarms, i);
			i = i - 1
			size = table.getn(alarms);
		end
	end 
end

function NAT_split(_string,_seperator)
   local t, ll
   t={}
   ll=0
   if(string.len(_string) == 1) then
      return {_string}
   end
   while true do
      l = string.find(_string, _seperator, ll, true) -- find the next _seperator in the string
	  
      if l ~= nil then -- if "not not" found then..
         table.insert(t, string.sub(_string,ll,l-1)) -- Save it in our array.
         ll = l + 1 -- save just after where we found it for searching next time.
      else
         table.insert(t, string.sub(_string,ll)) -- Save what's left in our array.
         break -- Break at end, as it should be, according to the lua manual.
      end
   end
   
   return t
end


function NAT_tonumber(_val)
	local strlen = string.len(_val);
	local base = 1;
	local dec_val = 0;
	
	for i = strlen, 1, -1
	do
		local c = string.byte(string.sub(_val, i, i));
		if c >= string.byte('0') and c <= string.byte('9')
		then
			dec_val = dec_val + (c-48)*base;
			base = base * 16;
		elseif c >= string.byte('A') and c <= string.byte('F')
		then
			dec_val = dec_val + (c-55)*base;
			base = base * 16;
		end
	end
	
	return dec_val;
end

function NAT_retrieve_class_color(_class_name)
	if _class_name == "Paladin"
	then
		return "|cffF58CBA";
	elseif _class_name == "Warrior"
	then
		return "|cffC79C6E";
	elseif _class_name == "Mage"
	then
		return "|cff69CCF0";
	elseif _class_name == "Druid"
	then
		return "|cffFF7D0A";
	elseif _class_name == "Warlock"
	then
		return "|cff9482C9";
	elseif _class_name == "Hunter"
	then
		return "|cffABD473";
	elseif _class_name == "Priest"
	then
		return "|cffFFFFFF";
	elseif _class_name == "Rogue"
	then 
		return "|cffFFF569";
	elseif _class_name == "Shaman"
	then
		return "|cff0070DE";
	elseif _class_name == "Disabled"
	then
		return "|cff545454";
	end
	
	return "|cff00FF96";
end	

function NAT_retrieve_player_class(_name)
	return UnitClass(NAT_retrieve_unitid_from_name(_name));
end

function NAT_hex2rgb(_hex)
    return NAT_tonumber("0x"..string.sub(_hex,1,2)), NAT_tonumber("0x"..string.sub(_hex,3,4)), NAT_tonumber("0x"..string.sub(_hex,5,6));
end

function NAT_create_player_frame(_button_name, _parent_frame, _player_name)
	local uncolored_name = string.sub(_player_name, 11, strlen(_player_name));
	local r,g,b = NAT_hex2rgb(string.sub(_player_name, 5, 11));

	local backdrop = {
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
			tile="false",
			tileSize="8",
			edgeSize="4",
			insets={
				left="2",
				right="2",
				top="0",
				bottom="0"
			}
	}
	
	local frame = CreateFrame("Button", _button_name, _parent_frame);
	frame:EnableMouse();
	frame:RegisterForClicks("RightButtonDown");
	frame:SetWidth(130)
	frame:SetHeight(38)	
	frame:SetBackdrop(backdrop);

	frame.highlight = frame:CreateTexture(nil, "HIGHLIGHT");
	frame.highlight:SetWidth(130);
	frame.highlight:SetHeight(38);
	frame.highlight:SetTexture(0.8,0.2,0.2,0.5);
	frame.highlight:SetPoint("CENTER",0,0);
	frame:SetScript("OnEnter", function()frame.highlight:Show();end);
	frame:SetScript("OnLeave", function()frame.highlight:Hide();end);
	
	frame.bg = frame:CreateTexture(nil, "ARTWORK");
	frame.bg:SetPoint("CENTER",0,0);
	frame.bg:SetWidth(125);
	frame.bg:SetHeight(33);
	frame.bg:SetTexture(r/255,g/255,b/255,0.75);
	frame.bg:SetAllPoints(true);
	
	local uid = NAT_retrieve_unitid_from_name(uncolored_name);
	frame.model = CreateFrame("PlayerModel", nil, frame);
	frame.model.unit_id = uid;
	frame.model:SetWidth(35)
	frame.model:SetHeight(35)
	frame.model:SetUnit(uid);

		
	frame.model:SetPoint("TOPLEFT",frame,"TOPLEFT", 2, -1)
	frame.model:SetCamera(0)
	frame.model:SetFrameLevel(3);	
	
	frame.name = frame:CreateFontString(nil, "OVERLAY")
	frame.name:SetPoint("CENTER",10, 0)
	frame.name:SetFont("Fonts\\FRIZQT__.TTF", 14)
	frame.name:SetTextColor(0, 0, 0, 1)
	frame.name:SetShadowOffset(1,-1)
	frame.name:SetText(uncolored_name);

	frame:SetScript("OnUpdate", 
	function()
		if UnitInRaid("player")
		then
			local funit_id = NAT_retrieve_unitid_from_name(frame.name:GetText());
			if frame.model.unit_id ~= funit_id
			then
				frame.model:SetUnit(funit_id);
				frame.model.unit_id = funit_id;
			end
			
			if UnitInRaid(frame.model.unit_id)
			then
				local name, rank,sg,level,class, filename, zone, online, isdead, role, isml = GetRaidRosterInfo(tonumber(string.sub(frame.model.unit_id,5,5)));
				
				if not UnitIsVisible(funit_id) or online == nil
				then
					frame.model:SetModel("Interface\\Buttons\\talktomequestionmark.mdx")
					frame.model:SetModelScale(3.25)
					frame.model:SetPosition(0, 0, -1)
				end
			end
		end
	end);
	
	return frame;
end



function NAT_retrieve_unitid_from_name(_name)
	if UnitInRaid("player") ~= nil
	then
		for i=1, GetNumRaidMembers(), 1
		do
			local unit_id = "raid"..i;
			local pname = UnitName(unit_id);
			if pname == _name
			then
				return unit_id;
			end
		end
	end
	
	return nil;
end

function NAT_retrieve_mark_color(_mark)
	if _mark == "skull"
	then 
		return "|cffE3DAC9";
	elseif _mark == "x"
	then
		return "|cffFF0000";
	elseif _mark == "square"
	then
		return "|cff0070DE";
	elseif _mark == "moon"
	then
		return "|cffFFFFFF";
	elseif _mark == "triangle"
	then
		return "|cff228B22";
	elseif _mark == "diamond"
	then
		return "|cffA330C9";
	elseif _mark == "circle"
	then
		return "|cffFF7D0A";
	elseif _mark == "star"
	then
		return "|cffFFF569";
	elseif _mark == "MT"
	then
		return "|cffFFD700";
	end
	
	return "|cffC41F3B";
end

function NAT_mod(_a, _b)
	return _a - math.floor(_a/_b)*_b;
end