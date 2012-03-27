--[[

	Script Plugin
	by Ozzypig
	V1: October 2011
	V2: March 2012

]]

---------------------------------------

pmo = PluginManager()
plugin = pmo:CreatePlugin()
mouse = plugin:GetMouse()
tb = plugin:CreateToolbar("Script Bar")
sel = game:GetService("Selection")
sc = game:GetService("ScriptContext")

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

function countLines(scr)
	assert(scr, "no script to count lines for")
	local _, lines = scr.Source:gsub("\n", "\n")
	return lines
end

function getError(scr)
	local func, err = loadstring(scr.Source)
	if err then
		local cut = err:match("\:(%d+\:.*)")
		err = "line " .. cut or err
		return {scr = scr; msg = err }
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

function getScriptsLines(obj)
	local lines = 0
	for k, v in pairs(getAll(obj,"Script")) do
		lines = lines + countLines(v)
	end
	for k, v in pairs(getAll(obj,"LocalScript")) do
		lines = lines + countLines(v)
	end
	return lines
end

function getScriptsErrors(obj)
	local errors = {}
	for k, v in pairs(getAll(obj,"Script")) do
		errors[#errors + 1] = getError(v)
	end
	for k, v in pairs(getAll(obj,"LocalScript")) do
		errors[#errors + 1] = getError(v)
	end
	return errors
end

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
	local selection = sel:Get()
	local inmsg = " in " .. (#selection > 0 and "selection" or "game")
	local search = #selection > 0 and selection or {
		game.Workspace,
		game.Lighting,
		game.StarterGui,
		game.StarterPack
	}
	local errors = {}
	for k, v in pairs(search) do
		for k2, v2 in pairs(getScriptsErrors(v)) do
			errors[#errors + 1] = v2
		end
	end
	if #errors > 0 then
		print("error(s): " .. #errors)
		for k, v in pairs(errors) do
			print("-> " .. v.scr:GetFullName())
			print(v.msg)
		end
	else
		print("No syntax errors found" .. inmsg .. ". :)")
	end
end)

button_linecount = tb:CreateButton("", "Count lines of code in your game", "script_lines.png")
button_linecount.Click:connect(function ()
	local selection = sel:Get()
	local inmsg = " in " .. (#selection > 0 and "selection" or "game")
	local search = #selection > 0 and selection or {
		game.Workspace,
		game.Lighting,
		game.StarterGui,
		game.StarterPack
	}
	local lines = 0
	for k, v in pairs(search) do
		lines = lines + getScriptsLines(v)
	end
	print("There are " .. commas(lines) .. " lines" .. inmsg .. ".")
end)

button_obfuscate = tb:CreateButton("", "Obfuscate the script", "obfuscate.png")
button_obfuscate.Click:connect(function ()
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
	local selection = sel:Get()
	local scr = selection[1]
	if not scr then return end
	if not scr:IsA("BaseScript") then return end

	src = scr.Source

	local new = Instance.new("Script", scr.Parent)
	new.Name = scr.Name
	new.Disabled = true
	local success = false
	new.Source = src:gsub("%-%-.+\n", ""):gsub("\n", " "):gsub("\t", " "):gsub("  ", " ")
	sel:Set{new}
	print("+" .. new:GetFullName())
end)

button_clr = tb:CreateButton("", "Clear the output", "clr.png")
button_clr.Click:connect(function ()
	for i = 1, 250 do
		print(string.char(9))
		if i % 25 == 0 then wait() end
	end
end)

function onScriptChange(script)
	local post_actions = {}
	while true do
		local s, e = script.Source:find("%-%-%[%[#.-%]%]")
		if s then
			print("#" .. script:GetFullName())
			local cmd = script.Source:match("%-%-%[%[(#.-)%]%]")
			local replace
			local comment = true
			if cmd:sub(1, 1) == "#" then
				--it's a command
				cmd = cmd:sub(2):lower()
				--get command name
				local s2, e2 = cmd:find(" ")
				local cmd_name = cmd
				if s2 then
					cmd_name = cmd:sub(1, s2 - 1)
					cmd = cmd:sub(e2 + 1)
				end
				if cmd_name == "hello" then
					replace = "hello world"
				elseif cmd_name == "local" then
					table.insert(post_actions, function (script)
						if script:IsA("LocalScript") then return end
						local s = Instance.new("LocalScript")
						s.Source = script.Source
						s.Disabled = script.Disabled
						s.Archivable = script.Archivable
						s.Parent = script.Parent
						script:Destroy()
						sel:Set{s}
					end)
				elseif cmd_name == "server" then
					table.insert(post_actions, function (script)
						if script:IsA("Script") then return end
						local s = Instance.new("Script")
						s.Source = script.Source
						s.Disabled = script.Disabled
						s.Archivable = script.Archivable
						s.Parent = script.Parent
						script:Destroy()
						sel:Set{s}
					end)
				elseif cmd_name == "numlines" then
					replace = countLines(script)
					comment = false
				end
			end
			local src = script.Source:sub(1, s - 1)
			if comment then src = src .. "--[[" end
			src = src .. (replace or "*")
			if comment then src = src .. "]]" end
			src = src .. script.Source:sub(e + 1)
			script.Source = src
		else break end
	end
	wait()
	for k, v in pairs(post_actions) do
		if not script.Parent then break end
		v(script)
	end
	
	local e = getError(script)
	if e then
		print("error: ")
		print(e.msg)
		while gui:FindFirstChild("ErrorFrame") do gui.ErrorFrame:Destroy() end
		local b = Instance.new("TextButton", gui)
		b.Name = "ErrorFrame"
		b.AutoButtonColor = false
		b.Position = UDim2.new(0.5, -150, 0.5, -75)
		b.Size = UDim2.new(0, 300, 0, 150)
		b.BackgroundColor3 = Color3.new(0, 0, 0)
		b.BorderColor3 = Color3.new(0.5, 0.5, 0.5)
		b.Text = ""
		b.MouseButton1Down:connect(function () b:Destroy() end)
		local t = Instance.new("TextLabel", b)
		t.Position = UDim2.new(0, 25, 0, 25)
		t.TextColor3 = Color3.new(1, 1, 1)
		t.TextXAlignment = "Left"
		t.TextYAlignment = "Bottom"
		t.Text = "SYNTAX ERROR: " .. script:GetFullName()
		local d = Instance.new("TextLabel", b)
		d.Position = UDim2.new(0, 25, 0, 30)
		d.Text = e.msg
		d.TextXAlignment = "Left"
		d.TextYAlignment = "Top"
		d.Size = UDim2.new(1, -50, 1, -35)
		d.BackgroundTransparency = 1
		d.TextColor3 = Color3.new(1, 1, 1)
		d.TextWrap = true
	end
end

game.DescendantAdded:connect(function (c)
	if c:IsA("Script") or c:IsA("LocalScript") then
		c.Changed:connect(function ()
			onScriptChange(c)
		end)
	end
end)

print("Script Plugin running")
