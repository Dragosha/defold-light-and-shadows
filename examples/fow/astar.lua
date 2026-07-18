local DIAGONAL_COST = 1.4142135623730951 -- math.sqrt(2)

local function heuristic(ax, ay, bx, by)
    -- (octile)
    local dx, dy = math.abs(ax - bx), math.abs(ay - by)
    return (dx + dy) + (DIAGONAL_COST - 2) * math.min(dx, dy)
end

local M = {}

--
local NEIGHBORS8 = {
    {dx=-1, dy= 0, cost = 1}, {dx=1, dy= 0, cost = 1},
    {dx= 0, dy=-1, cost = 1}, {dx=0, dy= 1, cost = 1},
    {dx=-1, dy=-1, cost = DIAGONAL_COST}, {dx=1, dy=-1, cost = DIAGONAL_COST},
    {dx=-1, dy= 1, cost = DIAGONAL_COST}, {dx=1, dy= 1, cost = DIAGONAL_COST},
}

local NEIGHBORS4 = {
    {dx=-1, dy= 0, cost = 1}, {dx=1, dy= 0, cost = 1},
    {dx= 0, dy=-1, cost = 1}, {dx=0, dy= 1, cost = 1}
}

M.diagonals = true

---A*
-- Example:
-- local world = {
--   {1,1,1,1},
--   {1,100,nil,1},
--   {1,1,1,1}
-- }
-- local path, cost = astar.a_star(world, {x=1,y=1}, {x=4,y=3})
-- for i,p in ipairs(path or {}) do print(p.x, p.y) end
---@param world table @world[y][x] = cost (>0); {0, nil/false} cell is blocked
---@param start table {x=.., y=..}
---@param goal table {x=.., y=..}
---@return table path { {x=.., y=..}, ...}, nil - path is not found 
---@return number cost of all path
function M.a_star(world, start, goal)
    local openSet = {}
    local cameFrom = {}
    local gScore = {}
    local fScore = {}
    local width, height = 0, 0

    -- Getting size of the map from dimention of array.
    height = #world
    if height > 0 then width = #world[1] end

    local function index(x, y)
        return y * 10000 + x -- inique key (world in bounds ~10000x10000)
    end

    local NEIGHBORS = M.diagonals and NEIGHBORS8 or NEIGHBORS4
    local function neighbors(x, y)
        local res = {}
        for i=1,#NEIGHBORS do
            local nx, ny = x + NEIGHBORS[i].dx, y + NEIGHBORS[i].dy
            if ny >= 1 and ny <= height and nx >= 1 and nx <= width then
                local cost = world[ny][nx]
                if cost and cost > 0 then
                    table.insert(res, {x=nx, y=ny, cost = NEIGHBORS[i].cost})
                end
            end

        end
        return res
    end

    local function lowest_fscore()
        local bestNode, bestScore
        for _, node in ipairs(openSet) do
            local key = index(node.x, node.y)
            local s = fScore[key] or math.huge
            if not bestScore or s < bestScore then
                bestScore = s
                bestNode = node
            end
        end
        return bestNode, bestScore
    end

    local function remove_from_open(node)
        for i, n in ipairs(openSet) do
            if n.x == node.x and n.y == node.y then
                table.remove(openSet, i)
                return
            end
        end
    end

    -- Init
    local startKey = index(start.x, start.y)
    gScore[startKey] = 0
    fScore[startKey] = heuristic(start.x, start.y, goal.x, goal.y)
    table.insert(openSet, {x=start.x, y=start.y})

    while #openSet > 0 do
        local current, cost = lowest_fscore()
        if current.x == goal.x and current.y == goal.y then
            -- Reconstruct the path
            local path = {}
            local cx, cy = current.x, current.y
            while true do
                table.insert(path, 1, {x=cx, y=cy})
                local key = index(cx, cy)
                if not cameFrom[key] then break end
                cx, cy = cameFrom[key].x, cameFrom[key].y
            end
            return path, cost
        end

        remove_from_open(current)
        local curKey = index(current.x, current.y)

        for _, nb in ipairs(neighbors(current.x, current.y)) do
            local nbKey = index(nb.x, nb.y)
            local stepCost = nb.cost * world[nb.y][nb.x]

            local tentative_g = (gScore[curKey] or math.huge) + stepCost
            if tentative_g < (gScore[nbKey] or math.huge) then
                cameFrom[nbKey] = {x=current.x, y=current.y}
                gScore[nbKey] = tentative_g
                fScore[nbKey] = tentative_g + heuristic(nb.x, nb.y, goal.x, goal.y)
                local alreadyOpen = false
                for _, n in ipairs(openSet) do
                    if n.x == nb.x and n.y == nb.y then
                        alreadyOpen = true
                        break
                    end
                end
                if not alreadyOpen then
                    table.insert(openSet, {x=nb.x, y=nb.y})
                end
            end
        end
    end

    return nil -- no solutions
end



-- Example:
-- local world = {
--   {1,1,5,1},
--   {1,100,0,1},
--   {1,1,1,10}
-- }
-- local cells = astar.find_nearest_cells(world, {x=2,y=2}, 5)
-- for i,c in ipairs(cells) do print(c.x, c.y, c.dist) end
-- Search for all the nearest cells with cost > 0 and <= max_cost
---@param world table
---@param start table {x=.., y=..}
---@param max_cost number
---@return table nearest cells { {x=.., y=.., dist=..}, ...}
function M.find_nearest_cells(world, start, max_cost)
    local width, height = 0, 0
    height = #world
    if height > 0 then width = #world[1] end

    local function index(x, y)
        return y * 10000 + x
    end

    local visited = {}
    local queue = {}

    local function push(node)
        table.insert(queue, node)
    end

    local function pop()
        local n = queue[1]
        table.remove(queue, 1)
        return n
    end

    push({x=start.x, y=start.y, dist=0})
    visited[index(start.x, start.y)] = true

    local result = {}

    local NEIGHBORS = M.diagonals and NEIGHBORS8 or NEIGHBORS4

    while #queue > 0 do
        local current = pop()
        local cx, cy, dist = current.x, current.y, current.dist

        if dist+1 <= max_cost then
            for i=1,#NEIGHBORS do
                local nx, ny = cx + NEIGHBORS[i].dx, cy + NEIGHBORS[i].dy
                if  nx >= 1 and nx <= width and ny >= 1 and ny <= height then
                    local key = index(nx, ny)
                    if not visited[key] then
                        visited[key] = true
                        -- Check cost
                        local cost = world[ny][nx]
                        if cost and cost > 0 and dist <= max_cost then
                            local t = {x=nx, y=ny, dist=dist + NEIGHBORS[i].cost}
                            table.insert(result, t)
                            push(t)
                        end
                    end
                end
            end
        end
    end

    return result
end



return M
