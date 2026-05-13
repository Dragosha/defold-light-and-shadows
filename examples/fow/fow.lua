-- A module for preparing a low-resolution texture for the fog-of-war effect. 
-- This texture is passed to the fragment shader in the render script and used as a mask.
-- See: https://defold.com/ref/stable/resource-lua/#resource.set_texture:path-table-buffer
-- R channel is fog-of-war mask
-- G channel for units
-- B chahhel for solid objects 

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
local random = math.random

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

    local channels = buffer_info.channels
    for index = start, toend, channels do
        tstream[index + 0] = fmax(tstream[index + 0], r)
        -- tstream[index + 1] = fmin(255, tstream[index + 0] + g * p)
        -- tstream[index + 2] = fmin(255, tstream[index + 0] + b * p)
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
        local err = dx - diameter
        while (x >= y) do
            fill_line(posx - x, posx + x, posy + y, r)
            fill_line(posx - y, posx + y, posy + x, r)
            fill_line(posx - x, posx + x, posy - y, r)
            fill_line(posx - y, posx + y, posy - x, r)

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

-- A really dirty function for drawing a gradient circle.
local function draw_grad(posx, posy, diameter, r)
    local width = buffer_info.width
    local channels = buffer_info.channels
    local radius = math.floor(diameter / 2)
    local top = clamp(posy - radius, 1, buffer_info.height)
    local bottom = clamp(posy + radius, 1, buffer_info.height)
    local left = clamp(posx - radius, 1, width)
    local right = clamp(posx + radius, 1, width)

    for y = top, bottom, 1 do
        for x = left, right, 1 do
            local dist = math.sqrt((x - posx)*(x - posx) + (y - posy)*(y - posy))
            local p =  1 - dist / (radius)
            if dist < radius then p = p * 2 end
            if p > 1 then p = 1 end
            local index = (y-1) * width * channels + (x-1) * channels + 1
            tstream[index] = fmax(tstream[index], r*p)
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

    -- Fill the buffer stream with zero values
    tstream = buffer.get_stream(tbuffer, name)
    local index = 1
    for i=1,MAP_WIDTH * MAP_HEIGHT * coef * coef do
            tstream[index + 0] = 0
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


function fow.get(x, y)
    local index = buffer_index(x, y)
    return tstream[index + 0]
end

function fow.set_r(x, y, value)
    local index = buffer_index(x, y)
    tstream[index] = value
end
function fow.set_g(x, y, value)
    local index = buffer_index(x, y)
    tstream[index + 1] = value
    changes = true
end
function fow.set_b(x, y, value)
    local index = buffer_index(x, y)
    tstream[index + 2] = value
    changes = true
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
    -- draw_filled_circle(x * coef, y * coef, (diameter) * coef, 255, 0, 0, 255)
    draw_grad(x * coef, y * coef, diameter * coef, 255)
	changes = true
end

function fow.update(self, dt)
    self.fow_dt = (self.fow_dt or 0) + dt
    if self.fow_dt > .1 then
    	if changes and buffer_info and resource_path then
    		resource.set_texture( resource_path, header, buffer_info.buffer )
    		changes = false
            return true
    	end
        self.fow_dt = 0
    end
    return false
end


function fow.set_texture(_resource_path)
    if header and buffer_info and _resource_path then
        resource.set_texture( _resource_path, header, buffer_info.buffer )
    end
end

function fow.final(self)
	resource_path = nil
	buffer_info = nil
	constants.fog_of_war_handle = nil
end



return fow