--Purpose:  Reusable generic module for VFX handling
--janin 11/8/25

local VFXController = {}

function VFXController:Init(Core)
	self.VFXEvent = Core:Get("SharedRemotes"):GetEvent("VFXEvent")
	self.VFXModules = {}
	self.ActiveEffects = {}
end

function VFXController:PlayEffect(vfxData) -- all roads lead to OOP 💔
	-- Generic VFX playing logic
	local vfxModule = self.VFXModules[vfxData.Name]
	if vfxModule then
		return vfxModule:Play(vfxData)
	end
end

function VFXController:RegisterEffect(name: string, module: table)
	-- Allow external modules to register effects
	if name and module then
		self.VFXModules[name] = module
    else
        warn("could not register effect")
	end
end

function VFXController:ReplicateEffect(vfxData: table?)
	self.VFXEvent:Fire(true, vfxData)
end

return VFXController
