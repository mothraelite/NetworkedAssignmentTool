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
			table.remove(alarms, i);
			i = i -1;
			alarm.func();
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