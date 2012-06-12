--[[

	Falcon Scripting Plugin
	by Ozzypig
	V1: October 2011
	V2: March 2012
	V3: June 2012

]]

---------------------------------------

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

scroll = 1

scripts = {}
scripts.blank = ""
scripts.touchscript = [[
button = script.Parent

function onTouch(part)
	
end

button.Touched:connect(onTouch)

]]

scripts.playerscript = [[
function onPlayerSpawned(player, character)
	
end

function onPlayerChatted(player, message, recipient)
	
end

function onPlayerEntered(player)
	player.CharacterAdded:connect(function (char) onPlayerSpawned(player, char) end)
	player.Chatted:connect(function (msg, rec) onPlayerChatted(player, msg, rec) end)
	
	
end

game.Players.PlayerAdded:connect(onPlayerEntered)

]]

ignore = {}

sounds = {
	click = {sid="rbxasset://sounds\\switch.wav";v=.5;p=3}
}

for k, v in pairs(sounds) do
	cp:Preload(v.sid)
end

function playSound(a)
	local s = Instance.new("Sound", workspace)
	s.SoundId = a.sid or ""
	s.Volume = a.v or 1
	s.Pitch = a.p or 1
	s.PlayOnRemove = true
	s:Remove()
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

function check_leap_year(year)
	if(year % 400 == 0) then
		return true
	else
		if(year % 100 == 0) then
			return false
		else
			if(year % 4 == 0) then
				return true
			end
		end
	end
	return false
end

days_per_month = {31,28,31,30,31,30,31,31,30,31,30,31}

function newScript(name, parent)
	parent = parent or workspace
	local s = Instance.new("Script")
	s.Source = "\n\n"

	if parent:IsA("BasePart") then
		s.Source = scripts.touchscript
	elseif parent:IsA("Players") then
		s.Source = scripts.playerscript
	elseif parent:IsA("ScreenGui") or parent:IsA("GuiMain") or parent:IsA("BillboardGui") then
		s.Source = "gui = script.Parent\n\n\n"
	elseif parent:IsA("Frame") then
		s.Source = "frame = script.Parent\n\n\n"
	elseif parent:IsA("TextButton") or parent:IsA("ImageButton") then
		s.Source = "button = script.Parent\n\n\n"
	elseif parent:IsA("TextLabel") or parent:IsA("ImageLabel") then
		s.Source = "label = script.Parent\n\n\n"
	end
	
	local posix_time_local = tick()
	local year = math.floor(posix_time_local / 60 / 60 / 24 / 365.24)
	local current_year = year+1970
	days_per_month[2] = 28 + ((check_leap_year(current_year) and 1) or 0)
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
	local hour_formatted = hour_of_day
	local minute_of_day = math.floor((second_of_day / 60 / 60 - hour_of_day)*60)
	local second_of_minute = math.floor((((second_of_day / 60 / 60 - hour_of_day)*60) - minute_of_day)*60)
	
	s.Source = s.Source .. "--" .. day_of_month .. "/" .. month .. "/" .. current_year .. " " .. hour_formatted .. ":" .. minute_of_day .. "\n"

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
	  local scr = newScript("Script", workspace)
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

button_obfuscate = tb:CreateButton("", "Obfuscate the script", "obfuscate.png")
button_obfuscate.Click:connect(function ()
	playSound(sounds.click)
	local selection = sel:Get()
	local scr = selection[1]
	if not scr then return end
	if not scr:IsA("BaseScript") then return end

	local src = false
	pcall(function ()
		src = scr.Source
	end)
	if not src then
		print("Could not read source of script! :(")
		return
	end

	local str = ""
	for i = 1, src:len() do
		str = str .. "\\" .. string.byte(src:sub(i, i))
	end
	str = "loadstring(\"" .. str .. "\")()"

	local new = Instance.new("Script", scr.Parent)
	new.Name = scr.Name
	new.Disabled = true
	local success = false
	pcall(function ()
		new.Source = str
	end)
	sel:Set{new}
	print("+" .. new:GetFullName())
end)

button_flatten = tb:CreateButton("", "Flatten script to one line (removing comments)", "script_flat.png")
button_flatten.Click:connect(function ()
	playSound(sounds.click)
	local selection = sel:Get()
	local scr = selection[1]
	if not scr then return end
	if not scr:IsA("BaseScript") then return end

	src = scr.Source

	local new = Instance.new("Script", scr.Parent)
	new.Name = scr.Name
	new.Disabled = true
	local success = false
	new.Source = src:gsub("%-%-.+\n", ""):gsub("\n", " "):gsub("\r", " "):gsub("\t", " "):gsub(" +", " ")
	sel:Set{new}
	print("+" .. new:GetFullName())
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
				--it's a command
				cmd = cmd:sub(2):lower()
				--get command name
				local s2, e2, space = cmd:find("(%s+)")
				local cmd_name = cmd
				if s2 then
					cmd_name = cmd:sub(1, s2 - 1)
					cmd = cmd:sub(e2 + 1)
				end
				local words = {}
				for w in string.gmatch(cmd, "(%a)") do
					table.insert(words, w)
				end
				if cmd_name == "hello" then
					replace = "Hello, world!"
				elseif cmd_name == "help" or cmd_name == "" then
					m = 1
					term = term .. "\n"
					replace = [[Commands Help:
#hello		Replaces with "Hello, world!".
#help			Replaces with this message.
#local		Changes the script into a LocalScript.
#script		Changes the script into a Script.
#server		Same as #script.
#nocomments	Removes single-line comments from a script.
#lines		Gives the number of lines in a script.
#syntax		Checks the syntax of the script for any errors.
#sync			Replaces the source code of all scripts with the same tag with the one in which #sync was used.
				Use #synchelp for more info.
#synchelp	Gives instructions on how to use the syncing system.
#tag			Echos back the script's tag (if it has one).]]
				elseif cmd_name == "synchelp" or cmd_name == "" then
					m = 1
					term = term .. "\n"
					replace = [[Sync Help:
The syncing system uses the tag system to sync the sources of scripts together that are the same. First, set
the tag of a script by using --![tag]. For example:
 --!button
Add that to all the scripts that should have the same source. Now, when you change one of those scripts, and
you want to change them all, type the #sync command. This will syncronize all the scripts' sources from the one
you edited.
To check if you set the tag of a script correctly, use #tag.]]
				elseif cmd_name == "local" then
					table.insert(post_actions, function (script)
						if not script:IsA("BaseScript") then return end
						local s = Instance.new("LocalScript")
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
				elseif cmd_name == "lines" then
					replace = countLines(script) .. " lines"
				elseif cmd_name == "tag" then
					replace = "This script's tag is !" .. (getTag(script) or "<none>") .. ""
				elseif cmd_name == "sync" then
					local tag = getTag(script)
					if tag then
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
						replace = "This script does not have a tag; set it by adding --!derp to the top (where derp is the tag)"
					end
				elseif cmd_name == "nocomments" then
					table.insert(post_actions, function (script)
						local src, count = script.Source:gsub("(%-%-.-[\n\r]+)","")
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
				else
					replace = "Unknown command \"" .. cmd_name .. "\", use #help to get a list"
				end
			end
			local src = script.Source:sub(1, s - 1)
			if comment then if m == 1 then src = src .. "--[[" elseif m == 2 then src = src .. "--" end end
			src = src .. replace
			if comment then if m == 1 then src = src .. "]]" elseif m == 2 then src = src .. term end end
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

function showError(script, e)
	print("Error: ")
	print(e.msg)
	while gui:FindFirstChild("ErrorFrame") do gui.ErrorFrame:Destroy() end
	current_error = script
	local b = Instance.new("TextButton", gui)
	b.Name = "ErrorFrame"
	b.AutoButtonColor = false
	b.Position = UDim2.new(0.5, -150, 0.5, -75)
	b.Size = UDim2.new(0, 300, 0, 150)
	b.BackgroundColor3 = Color3.new(0, 0, 0)
	b.BorderColor3 = Color3.new(0.5, 0.5, 0.5)
	b.Text = ""
	b.MouseButton1Down:connect(function () playSound(sounds.click); b:Destroy() end)
	b.MouseButton2Down:connect(function ()
		if b:FindFirstChild("ContextMenu") then b.ContextMenu:Destroy() return end
		playSound(sounds.click);
		local f = Instance.new("TextButton", b)
		f.Name = "ContextMenu"
		f.AutoButtonColor = false
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.BorderColor3 = Color3.new(1, 0, 0)
		f.Text = ""
		f.MouseButton2Down:connect(function ()
			f:Destroy()
		end)
		playSound(sounds.click)
		local h = 0
		local i = 0
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
			b.AutoButtonColor = false
			b.Position = UDim2.new(0, 0, 0, (i - 1) * 25 - 1)
			b.Size = UDim2.new(1, 0, 0, 25)
			b.TextColor3 = Color3.new(0.35, 0, 0)
			b.BackgroundColor3 = Color3.new(0, 0, 0)
			b.TextStrokeColor3 = Color3.new(1, 0, 0)
			b.MouseEnter:connect(function ()
				b.TextStrokeColor3 = Color3.new(1, .5, 0)
				b.BorderColor3 = Color3.new(1, .5, 0)
				end)
			b.MouseLeave:connect(function ()
				b.TextStrokeColor3 = Color3.new(1, 0, 0)
				b.BorderColor3 = Color3.new(1, 0, 0)
			end)
			b.TextStrokeTransparency = 0
			b.BorderColor3 = Color3.new(1, 0, 0)
			b.Font = "ArialBold"
			b.FontSize = "Size18"
			b.Text = k
			b.MouseButton1Down:connect(function ()
				playSound(sounds.click);
				v(script)
				f:Destroy()
			end)
			h = h + 25
		end
		f.Size = UDim2.new(0, 300, 0, h - 1)
		f.Position = UDim2.new(.5, -150, 0.5, h * -.5)
	end)
	b.BackgroundTransparency = .25
	local t = Instance.new("TextLabel", b)
	t.Position = UDim2.new(0, 0, 0, 0)
	t.Size = UDim2.new(1, 0, 0, -18)
	t.BackgroundColor3 = Color3.new(0, 0, 0)
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextXAlignment = "Left"
	t.TextYAlignment = "Center"
	t.TextStrokeColor3 = Color3.new(0, 0, 0)
	t.TextStrokeTransparency = 0
	t.TextWrap = true
	t.Font = "Arial"
	t.FontSize = "Size14"
	t.BorderSizePixel = 0
	t.BackgroundTransparency = .5
	t.Text = "Syntax Error in: " .. script:GetFullName()
	t.MouseEnter:connect(function ()
		t.TextWrap = false
	end)
	t.MouseLeave:connect(function ()
		t.TextWrap = true
	end)
	local d = Instance.new("TextLabel", b)
	d.Position = UDim2.new(0, 5, 0, 5)
	d.Text = e.msg
	d.Font = "ArialBold"
	d.FontSize = "Size14"
	d.TextXAlignment = "Left"
	d.TextYAlignment = "Top"
	d.Size = UDim2.new(1, -10, 1, -10)
	d.BackgroundTransparency = 1
	d.TextStrokeColor3 = Color3.new(0, 0, 0)
	d.TextStrokeTransparency = 0
	d.TextColor3 = Color3.new(1, 1, 1)
	d.TextWrap = true
	do
		local d = Instance.new("TextLabel", b)
		d.Position = UDim2.new(0, 5, 1, -5)
		d.Text = e.msg
		d.Font = "ArialBold"
		d.FontSize = "Size12"
		d.TextXAlignment = "Left"
		d.TextYAlignment = "Bottom"
		d.TextColor3 = Color3.new(.75, .75, .75)
		d.TextStrokeColor3 = Color3.new(0, 0, 0)
		d.TextStrokeTransparency = 0
		d.Text = "Click to dismiss; right-click for more options"
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
	if not script:IsDescendantOf(workspace) then return end
	
	processCommands(script)
	
	local e = getError(script)
	if e and not ignore[script] then
		showError(script, e)
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
end

game.DescendantAdded:connect(function (c)
	if c:IsA("Script") or c:IsA("LocalScript") then
		foundScript(c)
	end
end)

game.DescendantRemoving:connect(function (c)
	if conns[c] then
		conns[c]:disconnect()
		conns[c] = nil
	end
end)

print("The Faclon is flying!")
