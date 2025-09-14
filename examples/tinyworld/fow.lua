local constants = require "light_and_shadows.constants"

local fow = {}

local resource_path
local header
local coef = 1
local buffer_info
local changes = false
local tstream

local temp
local fmax = math.max
local fmin = math.min
local function clamp(x, min, max)
    return x < min and min or (x > max and max or x)
end

local function buffer_index(x, y)
    x = x < 1 and 1 or (x > buffer_info.width and buffer_info.width or x)
    y = y < 1 and 1 or (y > buffer_info.height and buffer_info.height or y)
    return (y-1) * buffer_info.width * buffer_info.channels + (x-1) * buffer_info.channels + 1
end

local function fill_line(fromx, tox, y, r, g, b, a)

    if fromx > tox then
        fromx, tox = tox, fromx
    end

    fromx = fmax(0, fromx)
    tox = fmin(buffer_info.width, tox)

    local start = buffer_index(fromx, y)
    local toend = buffer_index(tox, y)

    for index = start, toend, buffer_info.channels do
        tstream[index + 0] = fmax(tstream[index + 0], r)
        -- tstream[index + 1] = g
        -- tstream[index + 2] = b
        -- index = index + 4
    end
end

local function draw_filled_circle(posx, posy, diameter, r, g, b, a)

    if diameter > 0 then
        local radius = diameter / 2
        local x = radius - 1
        local y = 0
        local dx = 1
        local dy = 1
        local err = dx - (radius *2)
        while (x >= y) do
            fill_line(posx - x, posx + x, posy + y, r, g, b, a)
            fill_line(posx - y, posx + y, posy + x, r, g, b, a)
            fill_line(posx - x, posx + x, posy - y, r, g, b, a)
            fill_line(posx - y, posx + y, posy - x, r, g, b, a)

            if (err <= 0) then
                y = y + 1
                err = err + dy
                dy = dy + 2
            end

            if (err > 0) then
                x = x - 1
                dx = dx + 2
                err = err+ dx - radius *2
            end
        end
    end
end

function fow.init(self, MAP_WIDTH, MAP_HEIGHT, TILE_SIZE, _resource_path)

    local channels = 3
    local name = hash("rgb")
    local tbuffer = buffer.create(MAP_WIDTH * MAP_HEIGHT * coef * coef, { {name=name, type=buffer.VALUE_TYPE_UINT8, count=channels} } )

    buffer_info = {
        buffer = tbuffer,
        width = MAP_WIDTH * coef,
        height = MAP_HEIGHT * coef,
        channels = channels,
        premultiply_alpha = true
  	}

    -- Fill the buffer stream with some values
    tstream = buffer.get_stream(tbuffer, name)
    local index = 1
    for i=1,MAP_WIDTH * MAP_HEIGHT * coef * coef do
            tstream[index + 0] = 2
            tstream[index + 1] = 0
            tstream[index + 2] = 0
            index = index + channels
    end

    resource_path =    _resource_path
    local my_texture_info = resource.get_texture_info(resource_path)
    -- pprint(my_texture_info)
    header = { width=MAP_WIDTH * coef, height=MAP_HEIGHT * coef, type=graphics.TEXTURE_TYPE_2D, format=graphics.TEXTURE_FORMAT_RGB, num_mip_maps=1 }
    resource.set_texture( resource_path, header, buffer_info.buffer )
    constants.fog_of_war_handle = my_texture_info.handle
    constants.map = vmath.vector4(MAP_WIDTH, MAP_HEIGHT, TILE_SIZE, 0)
end


function fow.draw_in(x, y, diameter)
	local power = 0
	timer.delay(1/30, true, function (self, handle, time_elapsed)
		power = power + 16
		if power > 255 then
			power = 255
			timer.cancel(handle)
		end
		draw_filled_circle(x * coef, y * coef, diameter * coef, power, 0, 0, 255)
		changes = true
	end)
end

function fow.draw(x, y, diameter)
    draw_filled_circle(x * coef, y * coef, (diameter+4) * coef, 32, 0, 0, 0)
    draw_filled_circle(x * coef, y * coef, (diameter+2) * coef, 64, 0, 0, 0)
	draw_filled_circle(x * coef, y * coef, diameter * coef, 128, 0, 0, 16)
    draw_filled_circle(x * coef, y * coef, (diameter-2) * coef, 255, 0, 0, 255)
	changes = true
end

function fow.update(self, dt)
	if changes and buffer_info and resource_path then
		resource.set_texture( resource_path, header, buffer_info.buffer )
		changes = false
	end
end


function fow.final(self)
	resource_path = nil
	buffer_info = nil
	constants.fog_of_war_handle = nil
end



return fow