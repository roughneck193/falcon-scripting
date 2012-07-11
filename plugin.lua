--[[

	Falcon Scripting Plugin
	by Ozzypig
	V1: October 2011
	V2: March 2012
	V3: June 2012
	V4: July 2012
	
]]

---------------------------------------

if not _G.fsp then _G.fsp = {} end
_G.fsp.version = 4
_G.fsp.releasedate = "July 2012"

pmo = PluginManager()
plugin = pmo:CreatePlugin()
mouse = plugin:GetMouse()
tb = plugin:CreateToolbar("Scripting")
sel = game:GetService("Selection")
sc = game:GetService("ScriptContext")
cp = game:GetService("ContentProvider")
debris = game:GetService("Debris")

coregui = game:GetService("CoreGui")
gui = Instance.new("ScreenGui", coregui)

scripts = {}
scripts.blank = ""
config = {sounds = true; tagprefix = true; boilerplate = true; timestamp = true; commands = true; syntax = true; errorgui = true;}

ignore = {}

sounds = {
	click = {sid="rbxasset://sounds\\switch.wav";v=.5;p=3};
	beep = {sid="http://roblox.com/asset/?id=10209668",v=.5;p=2};
	highbeep = {sid="http://roblox.com/asset/?id=10209668",v=.5;p=2.5};
}

for k, v in pairs(sounds) do
	cp:Preload(v.sid)
end

function thread(func) Spawn(func) end

function playSound(a)
	if not config.sounds then return end
	local s = Instance.new("Sound", game:GetService("SoundService"))
	s.SoundId = a.sid or ""
	s.Volume = a.v or 1
	s.Pitch = a.p or 1
	s:Play()
	game:GetService("Debris"):AddItem(s, .6)
end

function indexString(text)
	local use_dot = true
	if tonumber(text:sub(1, 1)) then
		use_dot = false
	elseif text:find("[^%w_]") then
		use_dot = false
	end
	if use_dot then
		return "." .. text
	else
		text = text:gsub("\\", "\\\\"):gsub("\"","\\\"")
		return "[\"" .. text .. "\"]"
	end
end

function countLines(t, scr)
	local unique = true
	for k, v in pairs(t) do
		if v == scr.Source then unique = false end
	end
	local _, lines = scr.Source:gsub("\n", "\n")
	return lines + 1, unique
end

function getError(scr)
	local func, err = loadstring(scr.Source)
	if err then
		local cut = err:match("\:(%d+\:.*)")
		err = "line " .. cut or err
		line = tonumber(cut) or 1
		return {scr=scr; msg=err; line=line}
	end
end

function commas(x)
	local str = tostring(x):reverse()
	local str2 = ""
	for i = 1, str:len() do
		str2 = str2 .. str:sub(i, i)
		if i % 3 == 0 then
			str2 = str2 .. ","
		end
	end
	if str2:sub(str2:len()) == "," then
		str2 = str2:sub(1, str2:len() - 1)
	end
	return str2:reverse()
end

function getTag(scr)
	return scr.Source:match("[\r\n]%-%-%!(.-)[\r\n]+") or scr.Source:match("^%-%-%!(.-)[\r\n]+")
end

function getAll(object, class)
	local objects = {}
	if object:IsA(class) then
		objects[#objects + 1] = v
	end
	for k, v in pairs(object:GetChildren()) do
		if v:IsA(class) then
			objects[#objects + 1] = v
		end
		for k2, v2 in pairs(getAll(v, class)) do
			objects[#objects + 1] = v2
		end
	end
	return objects
end

function getScriptsLines(t, obj)
	local c = 0
	local lines = 0
	local uniquelines = 0
	for k, v in pairs(getAll(obj,"BaseScript")) do
		local l, u = countLines(t, v)
		t[#t+1] = v.Source
		lines = lines + l
		if u then
			uniquelines = uniquelines + l
		end
		c = c + 1
	end
	return lines, uniquelines, c
end

function getScriptsErrors(obj)
	local c = 0
	local errors = {}
	for k, v in pairs(getAll(obj,"BaseScript")) do
		errors[#errors + 1] = getError(v)
		c = c + 1
	end
	return errors, c
end

function isLeapYear(year)
	return (year % 400 == 0) and (not (year % 100 == 0) or (year % 4 == 0))
end

days_per_month = {31,28,31,30,31,30,31,31,30,31,30,31}

function timestamp()
	local posix_time_local = tick()
	local year = math.floor(posix_time_local / 60 / 60 / 24 / 365.24)
	local current_year = year+1970
	days_per_month[2] = 28 + ((isLeapYear(current_year) and 1) or 0)
	local day_of_year = math.floor((posix_time_local / 60 / 60 / 24) - year*365.24)
	local day_of_month = day_of_year
	month = nil
	for i, v in pairs(days_per_month) do
		if(day_of_month > v) then
			day_of_month = day_of_month - v
		else
			month = i
			break
		end
	end
	local second_of_day = math.floor(posix_time_local % 86400)
	local hour_of_day = math.floor(second_of_day / 60 / 60)
	local hour_formatted = (hour_of_day + 1) % 12 - 1
	local m = hour_of_day > 12 and "PM" or "AM"
	local minute_of_day = math.floor((second_of_day / 60 / 60 - hour_of_day)*60)
	local second_of_minute = math.floor((((second_of_day / 60 / 60 - hour_of_day)*60) - minute_of_day)*60)
	if minute_of_day < 10 then
		minute_of_day = "0" .. minute_of_day
	end
	return month .. "/" .. day_of_month .. "/" .. (current_year - 2000) .. " " .. hour_formatted .. ":" .. minute_of_day .. " " .. m
end

function newScript(name, parent)
	local auto_parent_set = false
	if not parent then parent = workspace auto_parent_set = true end
	local s = Instance.new("Script")
	s.Source = "\n\n"

	if config.boilerplate then
		if parent:IsA("BasePart") then
			s.Source = scripts.touchscript
			local cd, dialog
			for k, v in pairs(parent:GetChildren()) do
				if v:IsA("ClickDetector") then cd = v end
				if v:IsA("Dialog") then dialog = v end
				if cd and dialog then return end
			end
			if cd then
				s.Source = scripts.clickdetector:gsub("%%clickdetector%%", indexString(cd.Name))
			elseif dialog then
				s.Source = scripts.dialog:gsub("%%dialog%%", indexString(dialog.Name))
			end
			if parent:IsA("FlagStand") then
				s.Source = scripts.flagstand
			elseif parent:IsA("Seat") then
				s.Source = scripts.seat
			elseif parent:IsA("VehicleSeat") then
				s.Source = scripts.vehicleseat
			elseif parent:IsA("SkateboardPlatform") then
				s.Source = scripts.skateboardplatform
			end
		elseif parent:IsA("Players") then
			s.Source = scripts.playerscript
			parent = workspace
		elseif parent:IsA("HopperBin") then
			s.Source = scripts.hopperbin
		elseif parent:IsA("Tool") then
			s.Source = scripts.tool
		elseif parent:IsA("Workspace") and not auto_parent_set then
			s.Source = scripts.workspace
		elseif parent:IsA("ScreenGui") or parent:IsA("GuiMain") or parent:IsA("BillboardGui") then
			s.Source = scripts.gui
		elseif parent:IsA("Frame") then
			s.Source = "frame = script.Parent\n\n\n"
		elseif parent:IsA("TextButton") or parent:IsA("ImageButton") then
			s.Source = "button = script.Parent\n\n\n"
		elseif parent:IsA("TextLabel") or parent:IsA("ImageLabel") then
			s.Source = "label = script.Parent\n\n\n"
		elseif parent:IsA("Model") and not parent:IsA("Workspace") then
			s.Source = "model = script.Parent\n\n\n\n"
			local human
			for k, v in pairs(parent:GetChildren()) do
				if v:IsA("Humanoid") then human = v break end
			end
			if human then s.Source = "figure = script.Parent\nhuman = figure" .. indexString(human.Name) .. "\n\n\n" end
		end
	end
	
	local src = s.Source
	s.Source = ""
	if config.tagprefix then s.Source = s.Source .. "--!\n\n" end
	s.Source = s.Source .. src
	if config.timestamp then s.Source = s.Source .. "--" .. timestamp() .. "\n" end

	local id = 1
	if parent:findFirstChild(name) then id = 2 end
	while parent:findFirstChild(name .. id) do id = id + 1 end
	s.Name = name
	s.Parent = parent

	if id ~= 1 then s.Name = s.Name .. id end

	print("+" .. s:GetFullName())

	return s
end

button_newscript = tb:CreateButton("", "Create a new script", "script.png")
button_newscript.Click:connect(function (...)
	playSound(sounds.click)
	local sel_ = sel:Get()
	if #sel_ == 0 then
	  local scr = newScript("Script")
		sel:Set{scr}
	else
		local a = {}
		for k, v in pairs(sel_) do
			a[#a + 1] = newScript("Script", v)
		end
		sel:Set(a)
	end
end)

button_syntax = tb:CreateButton("", "Check for script syntax errors", "script_check.png")
button_syntax.Click:connect(function (...)
	playSound(sounds.click)
	local selection = sel:Get()
	local inmsg = " in " .. (#selection > 0 and "selection" or "game")
	local search = #selection > 0 and selection or {
		game.Workspace,
		game.Lighting,
		game.StarterGui,
		game.StarterPack
	}
	local checked = 0
	local errors = {}
	for k, v in pairs(search) do
		local e, c = getScriptsErrors(v)
		for k2, v2 in pairs(e) do
			errors[#errors + 1] = v2
		end
		checked = checked + c
	end
	if #errors > 0 then
		print("Error" .. (#errors > 1 and "s" or "") .. ": " .. #errors)
		for i = 1, #errors do
			local v = errors[i]
			print("[" .. i .. "] " .. v.scr:GetFullName())
			print(v.msg)
		end
	else
		print("No syntax errors found" .. inmsg .. " (checked " .. checked .. " scripts).")
	end
end)

button_linecount = tb:CreateButton("", "Count lines of code in your game", "script_lines.png")
button_linecount.Click:connect(function ()
	playSound(sounds.click)
	local selection = sel:Get()
	local inmsg = " in " .. (#selection > 0 and "selection" or "game")
	local search = #selection > 0 and selection or {
		game.Workspace,
		game.Lighting,
		game.StarterGui,
		game.StarterPack
	}
	local lines = 0
	local uniquelines = 0
	local checked = 0
	local t = {}
	for k, v in pairs(search) do
		local l, u, c = getScriptsLines(t, v)
		lines = lines + l
		uniquelines = uniquelines + u
		checked = checked + c
	end
	if checked > 1 then
		print("There are " .. commas(lines) .. " lines (" .. commas(uniquelines) .. " from uniuqe sources)" .. inmsg .. " (checked " .. checked .. " script" .. (checked > 1 and "s" or "") .. ").")
	else
		print("No scripts to check!")
	end
end)

button_clr = tb:CreateButton("", "Clear the output", "clr.png")
button_clr.Click:connect(function ()
	playSound(sounds.click)
	for i = 1, 250 do
		print(string.char(9))
		if i % 25 == 0 then wait() end
	end
	playSound(sounds.click)
end)

function processCommands(script)
	local post_actions = {}
	local cmd, pre, term
	while true do
		local s, e, pre, cmd, term = script.Source:find("(%-%-%[%[)(#.-)(%]%])")
		local m = 1
		if not s then
			s, e, pre, cmd, term = script.Source:find("(%-%-)(#.-)(\n+)")
			m = 2
			if not s then
				s, e, pre, cmd = script.Source:find("(%-%-)(#.-)$")
				term = ""
			end
		end
		if s then
			print("#" .. script:GetFullName())
			local replace = "*"
			local comment = true
			if cmd:sub(1, 1) == "#" then
				cmd = cmd:sub(2):lower()
				local s2, e2, space = cmd:find("(%s+)")
				local cmd_name = cmd
				if s2 then
					cmd_name = cmd:sub(1, s2 - 1)
					cmd = cmd:sub(e2 + 1)
				end
				local words = {}
				for w in string.gmatch(cmd, "(%a*)") do
					table.insert(words, w)
				end
				if cmd_name == "hello" then
					replace = "Hello, world!"
				elseif cmd_name == "clear" then
					table.insert(post_actions, function (script) script.Source = "\n\n" end)
				elseif cmd_name == "words" then
					replace = table.concat(words, ", ")
				elseif cmd_name == "now" then
					replace = timestamp()
				elseif cmd_name == "hash" then
					replace = script:GetHash()
				elseif cmd_name == "local" then
					table.insert(post_actions, function (script)
						if not script:IsA("BaseScript") then return end
						local s = Instance.new("LocalScript")
						s.Source = script.Source
						s.Disabled = script.Disabled
						s.Archivable = script.Archivable
						s.Parent = script.Parent
						s.Name = script.Name
						for k, v in pairs(script:GetChildren()) do v.Parent = s end
						script:Destroy()
						sel:Set{s}
					end)
					replace = ""
					comment = false
				elseif cmd_name == "script" or cmd_name == "server" then
					table.insert(post_actions, function (script)
						if not script:IsA("BaseScript") then return end
						local s = Instance.new("Script")
						s.Source = script.Source
						s.Disabled = script.Disabled
						s.Archivable = script.Archivable
						s.Parent = script.Parent
						for k, v in pairs(script:GetChildren()) do v.Parent = s end
						script:Destroy()
						sel:Set{s}
					end)
					replace = ""
					comment = false
				elseif cmd_name == "flatten" then
					replace = ""
					comment = false
					table.insert(post_actions, function (script)
						script.Source = script.Source:gsub("%-%-.+\n", ""):gsub("\n", " "):gsub("\r", " "):gsub("\t", " "):gsub(" +", " ")
					end)
				elseif cmd_name == "obfuscate" then
					if words[1] == "weak" then
						replace = ""
						comment = false
						table.insert(post_actions, function (script)
							local src = script.Source
							local str = ""
							for i = 1, src:len() do
								str = str .. "\\" .. string.byte(src:sub(i, i))
							end
							str = "loadstring(\"" .. str .. "\")()"
							script.Source = str
						end)
					elseif words[1] == "strong" then
						replace = ""
						comment = false
						table.insert(post_actions, function (script)
							local src = script.Source
							local func = loadstring(src)
							if func then
								src = string.dump(func)
								local str = ""
								for i = 1, src:len() do
									str = str .. "\\" .. string.byte(src:sub(i, i))
								end
								str = "loadstring(\"" .. str .. "\")()"
								script.Source = str
							end
						end)
					else
						replace = "Unknown strength option \"" .. tostring(words[1]) .. "\", use #obfuscate weak OR #obfuscate strong."
					end
				elseif cmd_name == "lines" then
					replace = countLines({},script) .. " lines"
				elseif cmd_name == "tag" then
					replace = "This script's tag is !" .. (getTag(script) or "<none>") .. ""
				elseif cmd_name == "sync" then
					local tag = getTag(script)
					if tag and tag ~= "" then
						table.insert(post_actions, function (script)
							local scripts = {}
							local services = {game.Workspace, game.Lighting, game.StarterGui, game.StarterPack, game.Players}
							for k, v in pairs(services) do
								for k2, v2 in pairs(getAll(v, "Script")) do
									scripts[#scripts + 1] = v2
								end
							end
							for k, v in pairs(scripts) do
								local t = getTag(v)
								if t and t:lower() == tag:lower() then
									v.Source = script.Source
								end
							end
							print("Sync'd " .. #scripts .. " script" .. (#scripts > 1 and "s" or "") .. " with tag !" .. tag .. "")
						end)
						replace = ""
						comment = false
					else
						if tag then
							replace = "This script does not have a tag; set it by adding --!derp to the top (where \"derp\" is the tag)"
						else
							replace = "This script's tag is empty; set it by adding --!derp to the top (where \"derp\" is the tag)"
						end
					end
				elseif cmd_name == "nocomments" then
					table.insert(post_actions, function (script)
						local src, count = script.Source:gsub("(%-%-[^%[]-[\n\r]+)","")
						script.Source = src
						print("Removed " .. count .. " comment" .. (count > 1 and "s" or "") .. ".")
					end)
					replace = ""
					comment = false
				elseif cmd_name == "syntax" then
					local e = getError(script)
					if e then
						replace = "-> " .. e.msg
					else
						replace = ""
						comment = false
					end
				elseif cmd_name == "index" then
					if #sel:Get() == 0 then print("Select something...") end
					while #sel:Get() == 0 do wait() end
					local o = sel:Get()[1]
					local parents = {}
					local str = ""
					while o ~= game do
						str = indexString(o.Name) .. str
						o = o.Parent
					end
					str = "game" .. str
					replace = str
				elseif cmd_name == "help" or cmd_name == "" then
					m = 1
					replace = [[Commands Help:
#hello				Replaces with "Hello, world!".
#help					Replaces with this message.
#clear				Clears the source of a script.
#now					Replaces with a timestamp.
#hash					Replaces with the script's hash.
#index				Type the command and select an object. Replaces with an absolute indexing of that object (ie, game.Workspace.Model.Part).
#local				Changes the script into a LocalScript.
#script				Changes the script into a Script. (can also use #server)
#nocomments			Removes single-line comments from a script.
#flatten				Makes the entire script one line.
#obfuscate <o>		Obfuscates the script. <o> must be "weak" or "strong"
#lines				Gives the number of lines in a script.
#syntax				Checks the syntax of the script for any errors.
#sync					Replaces the source code of all scripts with the same tag with the one in which #sync was used.
						Use #synchelp for more info.
#synchelp			Gives instructions on how to use the syncing system.
#tag					Echos back the script's tag (if it has one).
#about				Replaces with information on the Falcon Scripting Plugin]]
				elseif cmd_name == "synchelp" or cmd_name == "" then
					m = 1
					replace = [[Sync Help:
The syncing system uses the tag system to sync the sources of scripts together that are the same. First, set
the tag of a script by using --![tag]. For example:
 --!button
Add that to all the scripts that should have the same source. Now, when you change one of those scripts, and
you want to change them all, type the #sync command. This will syncronize all the scripts' sources from the one
you edited.
To check if you set the tag of a script correctly, use #tag.]]
				elseif cmd_name == "about" then
					m = 1
					replace = "Falcon Scripting Plugin V" .. _G.fsp.version .. " (" .. _G.fsp.releasedate .. ") by Ozzypig - http://ozzypig.co.cc/roblox.html#falcon\n\n" .. (_G.fsp.art or "")
				else
					replace = "Unknown command \"" .. cmd_name .. "\", use #help to get a list"
				end
			end
			local src = script.Source:sub(1, s - 1)
			if comment then if m == 1 then src = src .. "--[[" elseif m == 2 then src = src .. "--" end end
			src = src .. replace
			if comment then if m == 1 then src = src .. "]]" .. term elseif m == 2 then src = src .. term end end
			src = src .. script.Source:sub(e + 1)
			script.Source = src
		else break end
	end
	wait()
	for k, v in pairs(post_actions) do
		if not script.Parent then break end
		v(script)
	end
end

function apply(obj, t) for k, v in pairs(t) do obj[k] = v end end

function showError(script, e)
	print("Error: ")
	print(e.msg)
	playSound(sounds.click)
	while gui:FindFirstChild("ErrorFrame") do gui.ErrorFrame:Destroy() end
	if not config.errorgui then return end
	current_error = script
	local b = Instance.new("TextButton", gui)
	apply(b, {Name = "ErrorFrame"; AutoButtonColor = false; Position = UDim2.new(0.5, -150, 0.5, -75); Size = UDim2.new(0, 300, 0, 150); BackgroundColor3 = Color3.new(0, 0, 0); BorderColor3 = Color3.new(0.5, 0.5, 0.5); Text = "";})
	b.MouseButton1Down:connect(function () playSound(sounds.click); b:Destroy() end)
	b.MouseButton2Down:connect(function ()
		if b:FindFirstChild("ContextMenu") then b.ContextMenu:Destroy() return end
		playSound(sounds.click);
		local f = Instance.new("TextButton", b)
		f.MouseButton2Down:connect(function ()
			f:Destroy()
		end)
		playSound(sounds.click)
		local h = 0
		local i = 0
		apply(f, {Name = "ContextMenu"; AutoButtonColor = false; BackgroundColor3 = Color3.new(0, 0, 0); BorderColor3 = Color3.new(1, 0, 0); Text = ""; Size = UDim2.new(0, 300, 0, h - 1); Position = UDim2.new(.5, -150, 0.5, h * -.5)})
		for k, v in pairs({
			["Select script"] = function (s)
				sel:Set{s}
			end;
			["Ignore errors"] = function (s)
				ignore[s] = true;
			end;
		}) do
			i = i + 1
			local b = Instance.new("TextButton", f)
			apply(b, {AutoButtonColor = false; Position = UDim2.new(0, 0, 0, (i - 1) * 25 - 1); Size = UDim2.new(1, 0, 0, 25); TextColor3 = Color3.new(0.35, 0, 0); BackgroundColor3 = Color3.new(0, 0, 0); TextStrokeColor3 = Color3.new(1, 0, 0); TextStrokeTransparency = 0; BorderColor3 = Color3.new(1, 0, 0); Font = "ArialBold"; FontSize = "Size18"; Text = k;})
			b.MouseEnter:connect(function ()
				b.TextStrokeColor3 = Color3.new(1, .5, 0)
				b.BorderColor3 = Color3.new(1, .5, 0)
				end)
			b.MouseLeave:connect(function ()
				b.TextStrokeColor3 = Color3.new(1, 0, 0)
				b.BorderColor3 = Color3.new(1, 0, 0)
			end)
			b.MouseButton1Down:connect(function ()
				playSound(sounds.click);
				v(script)
				f:Destroy()
			end)
			h = h + 25
		end
	end)
	b.BackgroundTransparency = .25
	local t = Instance.new("TextLabel", b)
	apply(t, {Position = UDim2.new(0, 0, 0, 0); Size = UDim2.new(1, 0, 0, -18); BackgroundColor3 = Color3.new(0, 0, 0); TextColor3 = Color3.new(1, 1, 1); TextXAlignment = "Left"; TextYAlignment = "Center"; TextStrokeColor3 = Color3.new(0, 0, 0); TextStrokeTransparency = 0; TextWrap = true; Font = "Arial"; FontSize = "Size14"; BorderSizePixel = 0; BackgroundTransparency = .5; Text = "Syntax Error in: " .. script:GetFullName();})
	t.MouseEnter:connect(function ()
		t.TextWrap = false
	end)
	t.MouseLeave:connect(function ()
		t.TextWrap = true
	end)
	local d = Instance.new("TextLabel", b)
	apply(d, { Position = UDim2.new(0, 5, 0, 5); Text = e.msg; Font = "ArialBold"; FontSize = "Size14"; TextXAlignment = "Left"; TextYAlignment = "Top"; Size = UDim2.new(1, -10, 1, -10); BackgroundTransparency = 1; TextStrokeColor3 = Color3.new(0, 0, 0); TextStrokeTransparency = 0; TextColor3 = Color3.new(1, 1, 1); TextWrap = true; })
	do local d = Instance.new("TextLabel", b)
		apply(d, {Position = UDim2.new(0, 5, 1, -5); Text = e.msg; Font = "ArialBold"; FontSize = "Size12"; TextXAlignment = "Left"; TextYAlignment = "Bottom"; TextColor3 = Color3.new(.75, .75, .75); TextStrokeColor3 = Color3.new(0, 0, 0); TextStrokeTransparency = 0; Text = "Click to dismiss; right-click for more options"; })
	end
end

function onScriptChange(script)
	if current_error == script and gui:FindFirstChild("ErrorFrame") then
		gui.ErrorFrame:Destroy(); current_error = nil
		local e = getError(script)
		if not e then
			print("Syntax error resolved!")
		end
	end
	
	if config.commands then processCommands(script) end
	
	if config.syntax then
		local e = getError(script)
		if e and not ignore[script] then
			showError(script, e)
		end
	end
end

conns = {}

function foundScript(c)
	conns[c] = c.Changed:connect(function (p)
		if p == "Source" then
			onScriptChange(c)
		elseif p == "Parent" and not c.Parent and conns[c] then
			conns[c]:disconnect()
		end
	end)
end

function recurseScripts(m, s)
	s = s or {}
	for k, v in pairs(m:GetChildren()) do
		if v:IsA("BaseScript") then
			s[#s + 1] = v
		end
		recurseScripts(v, s)
	end
	return s
end

for k, v in pairs({game.Workspace;game.Lighting;game.StarterGui;game.StarterPack;}) do
	for k2, v2 in pairs(recurseScripts(v)) do
		foundScript(v2)
	end
	v.DescendantAdded:connect(function (c)
		if c:IsA("BaseScript") then
			foundScript(c)
		end
	end)
	v.DescendantRemoving:connect(function (c)
		if conns[c] then
			conns[c]:disconnect()
			conns[c] = nil
		end
	end)
end

print("The Falcon is flying!")

--Load configuration
while not _G.fsp.config do wait() end
config = _G.fsp.config
--Load boilerplate code
while not _G.fsp.bpcode do wait() end
scripts = _G.fsp.bpcode
