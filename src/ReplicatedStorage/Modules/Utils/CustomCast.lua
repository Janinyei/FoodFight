--librium 6/25/25
--edited 12/21/25

local CustomCast = {}
local CastVisuals = require(script.Parent.CastVisuals)
local Config = require(script.Parent.Config)

function CustomCast:Cast(
	Origin: Vector3,
	Direction: Vector3,
	Params: RaycastParams,
	color: Color3?,
	visualDuration: number?
): RaycastResult
	local result = workspace:Raycast(Origin, Direction, Params)
	local Visual = CastVisuals.new(color, workspace)

	Visual:Raycast(Origin, Direction, Params)

	if visualDuration then
		task.delay(visualDuration, function()
			Visual:Hide()
		end)
	end

	return result
end

--returns a table of the raycasts that occur within the cylindrical cast

function CustomCast:CylindricalCast(
	Origin: Vector3,
	Direction: Vector3,
	Params: RaycastParams,
	radius: number,
	rayCount: number,
	color: Color3?,
	visualDuration: number?
): { RaycastResult }
	local Results = {}

	local MiddleRay = self:Cast(Origin, Direction, Params, color, visualDuration)

	if MiddleRay then
		table.insert(Results, MiddleRay)
	end

	for i = 1, rayCount do
		local angle = i * (2 * math.pi / rayCount)
		local offset = angle

		local xOffset = math.cos(angle) * radius
		local yOffset = math.sin(angle) * radius

		local rightVec = Direction:Cross(Vector3.yAxis).Unit
		local upVec = rightVec:Cross(Direction).Unit

		local newOrigin: Vector3 = Origin + rightVec * xOffset + upVec * yOffset
		local rayResult = self:Cast(newOrigin, Direction, Params, color, visualDuration)

		--	print(math.deg(angle))

		if rayResult then
			table.insert(Results, rayResult)
		end
	end

	return Results
end

return CustomCast
