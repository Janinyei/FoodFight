local RunService = game:GetService("RunService")

local Core = {}
Core._modules = {}
Core._initialized = false
Core._started = false

function Core:Get(moduleName: string)
	local module = self._modules[moduleName]
	if not module then
		error(("Module '%s' not found."):format(moduleName))
	end
	return module
end

function Core:Init(ModulesToLoad: Folder)
	if self._initialized then
		warn("[Core] Already initialized")
		return
	end

	-- Gather ALL modules into a single table at once
	self.SortedModules = {}

	-- Helper to collect modules from any folder
	local function collectModules(folder)
		if not folder then
			return
		end
		for _, module in folder:GetDescendants() do
			if module:IsA("ModuleScript") then
				table.insert(self.SortedModules, {
					module = module,
					priority = module:GetAttribute("Priority") or 0,
					name = module.Name,
				})
			end
		end
	end

	-- Collect from both folders
	collectModules(script:FindFirstChild("SharedModules"))
	collectModules(ModulesToLoad)

	-- Single sort operation
	table.sort(self.SortedModules, function(a, b)
		return a.priority > b.priority or (a.priority == b.priority and a.name < b.name)
	end)

	print(self.SortedModules)
	-- Load modules into cache
	for i, data in ipairs(self.SortedModules) do
		-- Load
		local success, result = pcall(require, data.module)
		if success then
			self._modules[data.name] = result
		else
			warn(string.format("[Core] Failed to load '%s': %s", data.name, result))
		end
	end
	--Initialize in priority order

	for i, data in ipairs(self.SortedModules) do
		local LoadedModule = self._modules[data.name]
		if LoadedModule then
			if typeof(LoadedModule) == "table" and LoadedModule.Init then
				local initSuccess, err = pcall(LoadedModule.Init, LoadedModule, self)
				if not initSuccess then
					warn(string.format("[Core] Init error in '%s': %s", data.name, err))
				end
			end
		end
	end

	self._initialized = true
end

function Core:Start()
	if not self._initialized then
		warn("[Core] Must call Init() before Start()")
		return
	end

	if self._started then
		return
	end

	--[[for name, module in pairs(self._modules) do
		if type(module) == "table" and module.Start then
			task.spawn(function()
				local success, err = pcall(module.Start, module, self)
				if not success then
					warn(string.format("[Core] Start error in '%s': %s", name, err))
				end
			end)
		end
	end]]


	for i, data in ipairs(self.SortedModules) do 
		local LoadedModule = self._modules[data.name]
			if LoadedModule then
				if typeof(LoadedModule) == "table" and LoadedModule.Start then
					local startSuccess, err = pcall(LoadedModule.Start, LoadedModule, self)
					if not startSuccess then
						warn(string.format("[Core] Start error in '%s': %s", data.name, err))
					end
				end
			end
	end



	self._started = true
end

return Core
