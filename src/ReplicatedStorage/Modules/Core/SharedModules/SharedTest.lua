local SharedTest = {}
local RunService = game:GetService("RunService")

function SharedTest:Init()
    print("SharedTest Init")

    if RunService:IsServer() then
        print("SharedTest Init Server")
    else
        print("SharedTest Init Client")
    end
end

function SharedTest:Start()
    if RunService:IsServer() then
        print("SharedTest Start Server")
    else
        print("SharedTest Start Client")
    end
end

return SharedTest