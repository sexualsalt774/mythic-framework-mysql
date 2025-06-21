_aptData = {
	{
		name = "Boring Tower",
		invEntity = 13,
		coords = vector3(-481.83, -690.74, 33.21),
		heading = 96.566,
		length = 8.4,
		width = 4.0,
		options = {
			heading = 0,
			--debugPoly=true,
			minZ = 32.21,
			maxZ = 36.21
		},
		interior = {
			wakeup = {
				--153.7180, -1005.8624, -99.0000, 8.1633
				x = 153.7180,
				y = -1005.8624,
				z = -99.00,
				h = 68.261,
			},
			spawn = {
				x = 153.7180,
				y = -1005.8624,
				z = -99.00,
				h = 243.706
			},
			locations = {
				exit = {
					--151.3471, -1007.9624, -99.0000, 172.6153
					coords = vector3(151.3471, -1007.9624, -99.0000),
					length = 1.0,
					width = 1.0,
					options = {
						heading = 69,
						debugPoly=true,
						minZ = -100.0,
						maxZ = -98.0
					},
				},
				wardrobe = {
					coords = vector3(351.89, -205.34, 54.23),
					length = 0.4,
					width = 2.0,
					options = {
						heading = 339,
						--debugPoly=true,
						minZ = 53.23,
						maxZ = 56.23
					},
				},
				stash = {
					coords = vector3(348.69, -208.74, 54.23),
					length = 2.4,
					width = 1.0,
					options = {
						heading = 339,
						--debugPoly=true,
						minZ = 53.23,
						maxZ = 54.63
					},
				},
				logout = {
					coords = vector3(346.02, -207.23, 54.23),
					length = 2.0,
					width = 2.8,
					options = {
						heading = 338,
						--debugPoly=true,
						minZ = 51.83,
						maxZ = 54.03
					},
				},
			},
		},
	},
}

function Startup()
	local aptIds = {}

	for k, v in ipairs(_aptData) do
		v.id = k
		GlobalState[string.format("Apartment:%s", k)] = v
		table.insert(aptIds, k)
	end

	GlobalState["Apartments"] = aptIds
end
