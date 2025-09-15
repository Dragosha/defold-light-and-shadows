local map = {}

map.world = {}
map.width = 8
map.height = 8
map.bounds = {left = 0, bottom = 0, right = 0, top = 0}
map.tile_size = 16
map.cache = {}

map.diagonals = false

map.empty = hash("empty")
map.solid = hash("solid")
map.props = hash("props")
map.unit = hash("unit")
map.out = hash("out")

map.mark = {}
map.enemy_spawn = {}

function map.init(w, h, tile_size)
	map.cache = {}
	map.world = {}
	for i = 1, w*h, 1 do
		map.world[i] = map.empty
	end
	map.width = w
	map.height = h
	map.tile_size = tile_size or 16
end

function map.set(x, y, value)
	if x < 1 or x > map.width or y < 1 or y > map.height then return end
	local index = (y - 1) * map.width + x
	map.world[index] = value

end

function map.get(x, y)
	if x < 1 or x > map.width or y < 1 or y > map.height then return map.out end
	local index = (y - 1) * map.width + x
	return map.world[index]
end


----------------------------------------------

map.result = {

	SOLVED = hash("solved"),
	NO_SOLUTION = hash("no_solution"),
	SAME = hash("same")

}

---Find path
function map.find_path(start_x, start_y, end_x, end_y, fn)
	local size = 0
	local total_cost = 0
	local path =  {}
	local max_cost = 100

	if start_x == end_x and start_y == end_y then
		return map.result.SAME, size, total_cost, path
	end

	local near_size = 0
	local nears = {}
	local node

	local function check(x, y, deep)
		if deep <= max_cost and x > 0 and x <= map.width and y > 0 and y <= map.height then
			local index = (y - 1) * map.width + x
			local value = map.world[index]
			-- print(x, y, "=", value, t[index])

			local ok = false
			if fn then
				ok = fn(value)
			else
				ok = value == map.empty
			end

			local ti = nears[index]
			if (ok or deep == 0) and (not ti or ti.deep > deep) then
				if not ti then near_size = near_size + 1 end
				nears[index] = {x = x, y = y, deep = deep}

				if x == end_x and y == end_y then
					node = nears[index]
				else
					check(x - 1, y, deep + 1)
					check(x + 1, y, deep + 1)
					check(x, y + 1, deep + 1)
					check(x, y - 1, deep + 1)
				end
			end
		end
	end

	check(start_x, start_y, 0)

	if node then
		return map.find_path_in_nears(nears, start_x, start_y, end_x, end_y, node)
	else
		return map.result.NO_SOLUTION, size, total_cost, path
	end
end

function map.find_path_in_nears(nears, start_x, start_y, end_x, end_y, end_node)
	assert(nears)
	local size = 0
	local total_cost = 0
	local path =  {}
	local node = end_node

	if not node then
		for __, value in pairs(nears) do
			if value.x == end_x and value.y == end_y then
				node = value
				break
			end
		end
	end

	if not node then
		return map.result.NO_SOLUTION, size, total_cost, path
	end

	if start_x == end_x and start_y == end_y then
		return map.result.SAME, size, total_cost, path
	end

	repeat
		table.insert(path, {x = node.x, y = node.y})
		size = size + 1

		local current = node
		local x, y = node.x, node.y
		local h = math.random() < 0.5 and 1 or -1
		local temp = nears[(y - 1) * map.width + x + h]
		if temp and temp.deep < node.deep and math.abs(x - temp.x) <= 1 then node = temp end

		temp = nears[(y - 1) * map.width + x - h]
		if temp and temp.deep < node.deep and math.abs(x - temp.x) <= 1 then node = temp end

		temp = nears[(y - 1 + h) * map.width + x]
		if temp and temp.deep < node.deep and math.abs(y - temp.y) <= 1 then node = temp end

		temp = nears[(y - 1 - h) * map.width + x]
		if temp and temp.deep < node.deep and math.abs(y - temp.y) <= 1 then node = temp end

		if map.diagonals then
			temp = nears[(y - 1 - h) * map.width + x + h]
			if temp and temp.deep < node.deep then node = temp end

			temp = nears[(y - 1 - h) * map.width + x - h]
			if temp and temp.deep < node.deep then node = temp end

			temp = nears[(y - 1 + h) * map.width + x + h]
			if temp and temp.deep < node.deep then node = temp end

			temp = nears[(y - 1 + h) * map.width + x + h]
			if temp and temp.deep < node.deep then node = temp end
		end

	until node.x == start_x and node.y == start_y or current == node

	local invers_path = {{x = start_x, y = start_y}}
	size = size + 1

	for i = size, 1, -1 do
		table.insert(invers_path, path[i])
	end

	return map.result.SOLVED, size, total_cost, invers_path
end


----------------------------------------------
function map.is_empty(value) return value == map.empty end
function map.is_empty_or_unit(value) return value == map.empty or value == map.unit end
function map.is_empty_or_unit_or_props(value) return value == map.empty or value == map.unit or value == map.props end
----------------------------------------------
function map.find_nears(start_x, start_y, max_cost, fn)

	-- local key = "" .. start_x .. start_y .. max_cost
	-- local value = map.cache[key]
	-- if value then
	-- 	return value.near_result, value.near_size, value.nears
	-- end

	local near_result = map.result.NO_SOLUTION
	local near_size = 0
	local nears = {}

	local function check(x, y, deep)
		if deep <= max_cost and x > 0 and x <= map.width and y > 0 and y <= map.height then
			local index = (y - 1) * map.width + x
			local value = map.world[index]

			local ti = nears[index]

			local ok = false
			if fn then 
				ok = fn(value)
			else 
				ok = value == map.empty or value == map.unit or value == map.props
			end

			if (ok or deep == 0) and (not ti or ti.deep > deep) then
				if not ti then near_size = near_size + 1 end
				if deep > 0 then nears[index] = { x = x, y = y, deep = deep } end
				-- print("^^^ added, deep:", deep)
				check(x - 1, y, deep + 1)
				check(x + 1, y, deep + 1)
				check(x, y + 1, deep + 1)
				check(x, y - 1, deep + 1)
			end
		end
	end

	check(start_x, start_y, 0)
	if near_size > 0 then near_result = map.result.SOLVED end

	-- map.cache[key] = {near_result = near_result, near_size = near_size, nears = nears}
	return near_result, near_size, nears

end

local function pos_xy(x, y)
    return (x -.5 - map.width/2) * map.tile_size, (y - map.height/2 - .5) * map.tile_size
end

-- x, y in world coord
function map.get_closest_empty_neighbor(ix, iy, x, y)

	local variants = {{0, 0}, {-1, 0}, {1, 0}, {0, -1}, {0, 1}, {-1, -1}, {-1, 1}, {1, -1}, {1, 1}}

	local return_x = ix
	local return_y = iy
	local dist = math.huge

	for __, v in ipairs(variants) do
		local dx = ix + v[1]
		local dy = iy + v[2]
		local value = map.get(dx, dy)
		if value == map.empty then
			local cx, cy = pos_xy(dx, dy)
			local d = (cx - x)*(cx - x) + (cy - y)*(cy - y)
			if d <= dist then 
				dist = d
				return_x = dx
				return_y = dy
			end
		end

	end

	return
		return_x,
		return_y
end

function map.get_random_near_cell(ix, iy)
	local variants = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}}
	local v = variants[math.random(1, #variants)]
	return 
		ix + v[1],
		iy + v[2]
end

function map.get_closest_empty_cell(ix, iy, x, y)
	local variants = {{0, 0}, {-1, 0}, {1, 0}, {0, -1}, {0, 1}, {-1, -1}, {-1, 1}, {1, -1}, {1, 1}}

	local return_x = ix
	local return_y = iy
	local dist = math.huge

	for __, v in ipairs(variants) do
		local dx = ix + v[1]
		local dy = iy + v[2]
		local value = map.get(dx, dy)
		if value == map.empty then
			local d = (dx - x)*(dx - x) + (dy - y)*(dy - y)
			if d < dist then 
				dist = d
				return_x = dx
				return_y = dy
			end
		end

	end

	return
		return_x,
		return_y
end

function map.is_neighbor(ix, iy, tx, ty)
	local variants = {{0, 0}, {-1, 0}, {1, 0}, {0, -1}, {0, 1}}
	for __, v in ipairs(variants) do
		local dx = ix + v[1]
		local dy = iy + v[2]
		if dx == tx and dy == ty then
			return true
		end
	end

	return false
end

function map.is_neighbor_strict(ix, iy, tx, ty)
	local variants = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}}
	for __, v in ipairs(variants) do
		local dx = ix + v[1]
		local dy = iy + v[2]
		if dx == tx and dy == ty then
			return true
		end
	end

	return false
end

function map.find_nears_units(start_x, start_y, max_cost, callback, fn)
	local near_result = map.result.NO_SOLUTION
	local near_size = 0
	local nears = {}

	local function check(x, y, deep)
		if deep <= max_cost and x > 0 and x <= map.width and y > 0 and y <= map.height then
			local index = (y - 1) * map.width + x
			local value = map.world[index]
			-- print(x, y, "=", value, t[index])

			local ti = nears[index]
			local ok = false
			if fn then
				ok = fn(value)
			else
				ok = value == map.empty or value == map.unit
			end

			if (ok or deep == 0) and (not ti or ti.deep > deep) then
				if not ti then near_size = near_size + 1 end
				local node = {x = x, y = y, deep = deep}
				if value == map.unit and callback and not ti then
					callback(node)
				end
				nears[index] = node
				-- print("^^^ added, deep:", deep)
				check(x - 1, y, deep + 1)
				check(x + 1, y, deep + 1)
				check(x, y + 1, deep + 1)
				check(x, y - 1, deep + 1)
			end
		end
	end

	check(start_x, start_y, 0)
	if near_size > 0 then near_result = map.result.SOLVED end
	return near_result, near_size, nears
end

function map.pos_xy_vec(x, y, h)
    return vmath.vector3((x -.5 - map.width/2) * map.tile_size,  h or 0, (y - map.height/2 - .5) * map.tile_size)
end


return map