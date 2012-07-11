--[[

	Boilerplate Code for Falcon Scripting Plugin
	by Ozzypig
	
This is ready-to-edit code that you can use for making things in your games.
	
]]

scripts = {}

scripts.blank = ""

scripts.touchscript = [[
button = script.Parent

function onTouch(other)
	local human = other.Parent:FindFirstChild("Humanoid")
	if not human then return end
	local player = game.Players:GetPlayerFromCharacter(other.Parent)
	if not player then return end
end

button.Touched:connect(onTouch)

]]

scripts.seat = [[
seat = script.Parent

function onSit(player, character)
	if not player then return end
	
end

function onGetUp(player, character)
	if not player then return end
	
end

seat.ChildAdded:connect(function (c)
	if c:IsA("Weld") and c.Name == "SeatWeld" then
		local char = c.Part1.Parent
		sitter = char
		onSit(game.Players:GetPlayerFromCharacter(char), char)
	end
end)
seat.ChildRemoved:connect(function (c)
	if c:IsA("Weld") and c.Name == "SeatWeld" then
		local char = c.Part1.Parent
		sitter = nil
		onGetUp(game.Players:GetPlayerFromCharacter(char), char)
	end
end)

]]

scripts.vehicleseat = [[
seat = script.Parent

function onStop()
	
end

function onForward()
	
end

function onBackward()
	
end

function onStraight()
	
end

function onRight()
	
end

function onLeft()
	
end

function onSit(player, character)
	
end

function onGetUp(player, character)
	
end

seat.Changed:connect(function (p)
	if p == "Throttle" then
		if seat.Throttle == 0 then onStop()
		elseif seat.Throttle == 1 then onForward()
		elseif seat.Throttle == -1 then onBackward() end
	elseif p == "Steer" then
		if seat.Steer == 0 then onStraight()
		elseif seat.Steer == 1 then onRight()
		elseif seat.Steer == -1 then onLeft() end
	end
end)

function isSeatWeld(w) return w:IsA("Weld") and w.Name == "SeatWeld" and w.Part0 and w.Part1 end

seat.ChildAdded:connect(function (c)
	if not isSeatWeld(c) then return end
	local char = c.Part1.Parent
	local plr = game.Players:GetPlayerFromCharacter(char)
	if not plr then return end
	sitter = plr
	onSit(plr, char)
end)
seat.ChildRemoved:connect(function (c)
	if not isSeatWeld(c) then return end
	local char = c.Part1.Parent
	if not char then return end
	local plr = game.Players:GetPlayerFromCharacter(char)
	if not plr then return end
	sitter = nil
	onGetUp(plr, char)
end)
for k, v in pairs(seat:GetChildren()) do
	if isSeatWeld(v) then
		local char = c.Part1.Parent
		local plr = game.Players:GetPlayerFromCharacter(char)
		if not plr then return end
		sitter = plr
		onSit(plr, char)
	end
end

]]

scripts.skateboardplatform = [[
board = script.Parent
model = board.Parent

function onLeft()
	
end

function onStraight()
	
end

function onRight()
	
end

function onBackward()
	
end

function onStop()
	
end

function onForward()
	
end

function onMount(humanoid, controller)
	
end

function onDismount(board)
	
end

function onSpacePress()
	
end

function onSpaceRelease()
	
end

function onEquipped(h, c)
	c:BindButton(Enum.Button.Jump, "")
	c:BindButton(Enum.Button.Dismount, "")
	c.ButtonChanged:connect(function (b)
		if b.Name == "Jump" then
			if c:GetButton(b) then onSpacePress() else onSpaceRelease() end
		end
	end)
	c.AxisChanged:connect(function (...)
		local s = board.Steer
		local t = board.Throttle
		board.Steer = c.Steer
		board.Throttle = c.Throttle
		if s ~= board.Steer then
			if c.Steer == -1 then onLeft()
			elseif c.Steer == 0 then onStraight()
			elseif c.Steer == 1 then onRight() end
		end
		if t ~= board.Throttle then
			if c.Throttle == -1 then onBackward()
			elseif c.Throttle == 0 then onStop()
			elseif c.Throttle == 1 then onForward() end
		end
	end)
	onMount(h, c)
end

board.Equipped:connect(onEquipped)
board.Unequipped:connect(onDismount)
if board.Controller then
	onEquipped(board.ControllingHumanoid, board.Controller)
end

]]

scripts.dialog = [[
brick = script.Parent
dialog = brick%dialog%

function onDialogChoiceSelected(player, choice)
end

dialog.DialogChoiceSelected:connect(onDialogChoiceSelected)

]]

scripts.flagstand = [[
flagstand = script.Parent

function onFlagCaptured(player)
	local teamcolor = player.TeamColor
end

flagstand.FlagCaptured:connect(onFlagCaptured)

]]

scripts.clickdetector = [[
brick = script.Parent
cd = button%clickdetector%

function onMouseClick(player)
	if not player then return end
	
end

cd.MouseClick:connect(onMouseClick)

]]

scripts.gui = [[
gui = script.Parent
playergui = gui.Parent
player = playergui.Parent

]]

scripts.playerscript = [[
function onPlayerDied(player, character)
	
end

function onPlayerSpawned(player, character)
	while not character:FindFirstChild("Humanoid") do wait() end
	character.Humanoid.Died:connect(function () onPlayerDied(player, character) end)
end

function onPlayerChatted(player, message, recipient)
	
end

function onPlayerEntered(player)
	player.CharacterAdded:connect(function (char) onPlayerSpawned(player, char) end)
	player.Chatted:connect(function (msg, rec) onPlayerChatted(player, msg, rec) end)
	
	
end

game.Players.PlayerAdded:connect(onPlayerEntered)

]]
scripts.hopperbin = [[
bin = script.Parent
backpack = bin.Parent
player = backpack.Parent
while not player.Character do wait() end
character = player.Character
keys = {}

function onButton1Down(mouse)
	local target = mouse.Target
end

function onButton1Up(mouse)
	
end

function onKeyDown(key)
	
end

function onKeyUp(key)
	
end

function onSelected(mouse)
	
end

function onDeselected()
	
end

bin.Selected:connect(function (mouse, ...)
	mouse.Button1Down:connect(function () holding = true onButton1Down(mouse) end)
	mouse.Button1Up:connect(function () holding = nil onButton1Up(mouse) end)
	mouse.KeyDown:connect(function (key) keys[key] = true onKeyDown(key) end)
	mouse.KeyUp:connect(function (key) keys[key] = nil onKeyUp(key) end)
	selected = true onSelected(mouse, ...)
end)
bin.Deselected:connect(function (...) selected = nil onDeselected(...) end)

]]

scripts.tool = [[
tool = script.Parent
handle = tool.Handle
keys = {}

function getPlayer()
	return tool.Parent:IsA("Backpack") and tool.Parent.Parent.Parent or game.Players:GetPlayerFromCharacter(tool.Parent)
end

function onHandleTouched(other)
	local human = other.Parent:FindFirstChild("Humanoid")
	if not human then return end
	local player = game.Players:GetPlayerFromCharacter(other.Parent)
	if not player then return end
end

function onActivated()
end

function onDeactivated()
end

function onKeyDown(key)
end

function onKeyUp(key)
end

function onEquipped()
end

function onUnequipped()
end

tool.Equipped:connect(function (m)
	m.KeyDown:connect(function (k) keys[k] = true onKeyDown(k) end)
	m.KeyUp:connect(function (k) keys[k] = nil onKeyUp(k) end)
	equipped = true onEquipped(m)
end)
tool.Unequipped:connect(function () equipped = false onUnequipped() end)
tool.Activated:connect(function () holding = true onActivated() end)
tool.Deactivated:connect(function () holding = false onDeactivated() end)
handle.Touched:connect(function (...) onHandleTouched(...) end)

]]

scripts.workspace = [[
function onChildAdded(child)
	
end

workspace.ChildAdded:connect(onChildAdded)

]]

while not _G.fsp do wait() end
_G.fsp.bpcode = scripts
