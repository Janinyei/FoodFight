local ComboManager = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local COMBO_TIMEOUT_SECONDS = 3

local function getMultiplier(comboCount: number): number
	if comboCount >= 10 then
		return 2
	end
	if comboCount >= 5 then
		return 1.5
	end
	if comboCount >= 3 then
		return 1.2
	end
	return 1
end

function ComboManager:Init()
	self.ComboData = {}
	self._heartbeatConn = nil
end

function ComboManager:Start()
	for _, player in Players:GetPlayers() do
		self.ComboData[player] = {
			Count = 0,
			LastHitTime = 0,
		}
	end

	Players.PlayerAdded:Connect(function(player)
		self.ComboData[player] = {
			Count = 0,
			LastHitTime = 0,
		}
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.ComboData[player] = nil
	end)

	self._heartbeatConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for player, data in pairs(self.ComboData) do
			if data.Count > 0 and (now - data.LastHitTime) >= COMBO_TIMEOUT_SECONDS then
				self:Reset(player, "timeout")
			end
		end
	end)
end

function ComboManager:Reset(player: Player, reason: string?)
	local data = self.ComboData[player]
	if not data then
		return
	end
	if data.Count > 0 then
		--print("[Combo] reset", player.Name, reason or "unknown", "count", data.Count)
	end
	data.Count = 0
	data.LastHitTime = 0
end

function ComboManager:Increment(player: Player)
	local data = self.ComboData[player]
	if not data then
		self.ComboData[player] = {
			Count = 0,
			LastHitTime = 0,
		}
		data = self.ComboData[player]
	end

	data.Count += 1
	data.LastHitTime = os.clock()

	local mult = getMultiplier(data.Count)
	--print("[Combo] progress", player.Name, "count", data.Count, "mult", mult)

	return data.Count, mult
end

function ComboManager:Get(player: Player)
	local data = self.ComboData[player]
	if not data then
		return 0, 1
	end
	return data.Count, getMultiplier(data.Count)
end

return ComboManager

