-- purpose: Centralized input handling and rebinding
-- janin 12/10/25

local InputController = {}

-- Services
local CAS = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

function InputController:Init(Core)
	self.Core = Core

	-- Default Binds
	self.Binds = {
		["ToggleShiftLock"] = {
			["Inputs"] = { Enum.KeyCode.LeftControl, Enum.KeyCode.ButtonY },
		},
		["Aim"] = {
			["Inputs"] = { Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2 },
		},

		["Shoot"] = {
			["Inputs"] = {Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2}
		},
		["UpAction"] = {
					["Inputs"] = {Enum.KeyCode.Space, Enum.KeyCode.ButtonA}
				}
	
		-- Add more here
	}

	-- Callback table to store functions connected to actions
	self.Actions = {}
end



function  InputController:Start()
	self:LoadBinds()
end

function InputController:BindAction(ActionName, Callback)
	self.Actions[ActionName] = Callback
end


--registers and loads binds with
function InputController:LoadBinds()
	-- Register all binds with ContextActionService
	for actionName, config in pairs(self.Binds) do
		local function handleAction(name, state, inputObj)
			if self.Actions[name] then
				-- Pass the  (Begin, End, etc) to the listener
				self.Actions[name](state, inputObj)
			end
			return Enum.ContextActionResult.Pass --allows for other bound actions with the same input operate
		end
		CAS:BindAction(actionName, handleAction, false, unpack(config.Inputs))
	end
end

--changes the callback for a specific action.
function InputController:SetActionCallback(ActionName: string, callback)
	if not self.Binds[ActionName] then
		warn("bind for action doesn't exist")
		return
	end
	self.Actions[ActionName] = callback
end

--changes the bind for an action, this will be useful for settings later on
function InputController:SetBind(ActionName, NewInputs: {}, MobileButton:( ImageButton?)| TextButton?)
	CAS:UnbindAction(ActionName) --unbind previous action
	self.Binds[ActionName].Inputs = NewInputs
end

function InputController:AttachMobileButton(ActionName, MobileButton)
	--adds mobile button to action
end
return InputController
