local alarms = {};
function KAT_set_alarm(_time, _function)
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

function KAT_update_alarms()
	for i=1, table.getn(alarms), 1
	do
		local alarm = alarms[i];
		alarm.time = alarm.time - 1;
		if alarm.time <= 0
		then
			alarm.func();
			table.remove(alarms, i);
			i = i -1;
		end
	end 
end

function KAT_split(_string,_seperator)
   local t, ll
   t={}
   ll=0
   if(#_string == 1) then
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

function KAT_hex2rgb(_hex)
    return tonumber("0x".._hex:sub(1,2)), tonumber("0x".._hex:sub(3,4)), tonumber("0x".._hex:sub(5,6))
end

function KAT_create_player_frame(_button_name, _parent_frame, _player_name)
	local uncolored_name = string.sub(_player_name, 11, strlen(_player_name));
	local r,g,b = KAT_hex2rgb(string.sub(_player_name, 5, 11));

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
	frame:RegisterForClicks("AnyUp");
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
	frame:SetScript("OnUpdate", 
	function()
		if UnitInRaid("player")
		then
			local funit_id = KAT_retrieve_unitid_from_name(frame.name:GetText());
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
	
	frame.bg = frame:CreateTexture(nil, "ARTWORK");
	frame.bg:SetPoint("CENTER",0,0);
	frame.bg:SetWidth(125);
	frame.bg:SetHeight(33);
	frame.bg:SetTexture(r/255,g/255,b/255,0.75);
	frame.bg:SetAllPoints(true);
	
	local uid = KAT_retrieve_unitid_from_name(uncolored_name);
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
	
	return frame;
end

function KAT_retrieve_unitid_from_name(_name)
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