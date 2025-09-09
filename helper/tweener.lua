local UPDATE_FREQUENCY = sys.get_config_int("tweener.UPDATE_FREQUENCY", 60)

local M = {}

---@class hash
---@class constant
---@class vector

local TYPE_TABLE = "table"
local TYPE_USERDATA = "userdata"


---@param easing number[]|vector @The array of easing values, Example: {0, 0.5, 1, 2, 1}. Must have at least two elements.
---@return easing_function @The easing function
local function get_custom_easing(easing)
	local sample_count = #easing
	if sample_count < 2 then
		error("Easing table must have at least two elements.")
	end

	return function(t, b, c, d)
		if d == 0 then
			error("Division by zero: 'd' must not be zero.")
		end

		local time_progress = t / d
		if time_progress >= 1 then
			return (c + b) * easing[sample_count]
		end
		if time_progress <= 0 then
			return b * easing[1]
		end

		local sample_index = sample_count - 1
		local index1 = math.floor(time_progress * sample_index)
		local index2 = math.min(index1 + 1, sample_index)

		local diff = (time_progress - index1 * (1 / sample_index)) * sample_index
		local progress = easing[index1 + 1] * (1.0 - diff) + easing[index2 + 1] * diff

		return c * progress + b
	end
end


---@param easing_function easing_function
---@param from number
---@param to number
---@param time number
---@param callback fun(value: number, is_end: boolean)
---@param update_delta_time number|nil @Default is 1/60, the time between updates
---@return hash @The created timer id
function M.tween(easing_function, from, to, time, callback, update_delta_time)
	update_delta_time = update_delta_time or (1 / UPDATE_FREQUENCY)

	-- Acquire the easing function
	easing_function = M.DEFOLD_EASINGS[easing_function] or easing_function
	local easing_type = type(easing_function)
	if easing_type == TYPE_USERDATA or easing_type == TYPE_TABLE then
		easing_function = get_custom_easing(easing_function --[[@as vector]])
	end

	local time_elapsed = 0
	local latest_time = socket.gettime()

	local timer_id = timer.delay(update_delta_time, true, function(_, handle, dt)
		local current_time = socket.gettime()
		time_elapsed = time_elapsed + (current_time - latest_time)
		latest_time = current_time

		if time_elapsed >= time then
			timer.cancel(handle)
			callback(easing_function(time, from, to - from, time), true)
			return
		end

		callback(easing_function(time_elapsed, from, to - from, time), false)
	end)

	return timer_id
end


---@param easing_function easing_function
---@param from number
---@param to number
---@param time number
---@param time_elapsed number @current time [0 .. t - from]
---@return number @The result of easing
function M.ease(easing_function, from, to, time, time_elapsed)
	if time == 0 then
		return to
	end

	easing_function = M.DEFOLD_EASINGS[easing_function] or easing_function
	local easing_type = type(easing_function)
	if easing_type == TYPE_USERDATA or easing_type == TYPE_TABLE then
		easing_function = get_custom_easing(easing_function --[[@as vector]])
	end
	return easing_function(time_elapsed, from, to - from, time)
end


--
-- Adapted from
-- Tweener's easing functions (Penner's Easing Equations)
-- and http://code.google.com/p/tweener/ (jstweener javascript version)
--

--[[
Disclaimer for Robert Penner's Easing Equations license:

TERMS OF USE - EASING EQUATIONS

Open source under the BSD License.

Copyright © 2001 Robert Penner
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
	* Neither the name of the author nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUsineSS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

-- For all easing functions:
-- t = elapsed time
-- b = begin
-- c = change == ending - beginning
-- d = duration (total time)

local pi = math.pi
local abs = math.abs
local cos = math.cos
local pow = math.pow
local sin = math.sin
local sqrt = math.sqrt
local asin	= math.asin

local function linear(t, b, c, d)
	return c * t / d + b
end

local function inquad(t, b, c, d)
	t = t / d
	return c * pow(t, 2) + b
end

local function outquad(t, b, c, d)
	t = t / d
	return -c * t * (t - 2) + b
end

local function inoutquad(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(t, 2) + b
	else
		return -c / 2 * ((t - 1) * (t - 3) - 1) + b
	end
end

local function outinquad(t, b, c, d)
	if t < d / 2 then
		return outquad (t * 2, b, c / 2, d)
	else
		return inquad((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function incubic(t, b, c, d)
	t = t / d
	return c * pow(t, 3) + b
end

local function outcubic(t, b, c, d)
	t = t / d - 1
	return c * (pow(t, 3) + 1) + b
end

local function inoutcubic(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * t * t * t + b
	else
		t = t - 2
		return c / 2 * (t * t * t + 2) + b
	end
end

local function outincubic(t, b, c, d)
	if t < d / 2 then
		return outcubic(t * 2, b, c / 2, d)
	else
		return incubic((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inquart(t, b, c, d)
	t = t / d
	return c * pow(t, 4) + b
end

local function outquart(t, b, c, d)
	t = t / d - 1
	return -c * (pow(t, 4) - 1) + b
end

local function inoutquart(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(t, 4) + b
	else
		t = t - 2
		return -c / 2 * (pow(t, 4) - 2) + b
	end
end

local function outinquart(t, b, c, d)
	if t < d / 2 then
		return outquart(t * 2, b, c / 2, d)
	else
		return inquart((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inquint(t, b, c, d)
	t = t / d
	return c * pow(t, 5) + b
end

local function outquint(t, b, c, d)
	t = t / d - 1
	return c * (pow(t, 5) + 1) + b
end

local function inoutquint(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(t, 5) + b
	else
		t = t - 2
		return c / 2 * (pow(t, 5) + 2) + b
	end
end

local function outinquint(t, b, c, d)
	if t < d / 2 then
		return outquint(t * 2, b, c / 2, d)
	else
		return inquint((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function insine(t, b, c, d)
	return -c * cos(t / d * (pi / 2)) + c + b
end

local function outsine(t, b, c, d)
	return c * sin(t / d * (pi / 2)) + b
end

local function inoutsine(t, b, c, d)
	return -c / 2 * (cos(pi * t / d) - 1) + b
end

local function outinsine(t, b, c, d)
	if t < d / 2 then
		return outsine(t * 2, b, c / 2, d)
	else
		return insine((t * 2) -d, b + c / 2, c / 2, d)
	end
end

local function inexpo(t, b, c, d)
	if t == 0 then
		return b
	else
		return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
	end
end

local function outexpo(t, b, c, d)
	local epsilon = 0.00001 -- tolerance
	if math.abs(t - d) < epsilon then
		return b + c
	end
	return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
end

local function inoutexpo(t, b, c, d)
	if t == 0 then return b end
	if t == d then return b + c end

	t = t / d * 2
	if t < 1 then
		return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005
	else
		t = t - 1
		return c / 2 * 1.0005 * (-pow(2, -10 * t) + 2) + b
	end
end

local function outinexpo(t, b, c, d)
	if t < d / 2 then
		return outexpo(t * 2, b, c / 2, d)
	else
		return inexpo((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function incirc(t, b, c, d)
	t = t / d
	return(-c * (sqrt(1 - pow(t, 2)) - 1) + b)
end

local function outcirc(t, b, c, d)
	t = t / d - 1
	return(c * sqrt(1 - pow(t, 2)) + b)
end

local function inoutcirc(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return -c / 2 * (sqrt(1 - t * t) - 1) + b
	else
		t = t - 2
		return c / 2 * (sqrt(1 - t * t) + 1) + b
	end
end

local function outincirc(t, b, c, d)
	if t < d / 2 then
		return outcirc(t * 2, b, c / 2, d)
	else
		return incirc((t * 2) - d, b + c / 2, c / 2, d)
	end
end

local function inelastic(t, b, c, d, a, p)
	if t == 0 then return b end

	t = t / d
	if t == 1 then
		return b + c
	end

	if not p then
		p = d * 0.
	end

	local s
	if not a or a < abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * pi) * asin(c/a)
	end

	t = t - 1
	return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end

-- a: amplitud
-- p: period
local function outelastic(t, b, c, d, a, p)
	if t == 0 then
		return b
	end

	t = t / d
	if t == 1 then
		return b + c
	end

	if not p then
		p = d * 0.3
	end

	local s
	if not a or a < abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * pi) * asin(c/a)
	end

	return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
end

-- p = period
-- a = amplitud
local function inoutelastic(t, b, c, d, a, p)
	if t == 0 then return b end

	t = t / d * 2

	if t == 2 then return b + c end

	if not p then p = d * (0.3 * 1.5) end
	if not a then a = 0 end

	local s

	if not a or a < abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * pi) * asin(c / a)
	end

	if t < 1 then
		t = t - 1
		return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
	else
		t = t - 1
		return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p ) * 0.5 + c + b
	end
end

-- a: amplitud
-- p: period
local function outinelastic(t, b, c, d, a, p)
	if t < d / 2 then
		return outelastic(t * 2, b, c / 2, d, a, p)
	else
		return inelastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
	end
end

local function inback(t, b, c, d, s)
	if not s then s = 1.70158 end
	t = t / d
	return c * t * t * ((s + 1) * t - s) + b
end

local function outback(t, b, c, d, s)
	if not s then s = 1.70158 end
	t = t / d - 1
	return c * (t * t * ((s + 1) * t + s) + 1) + b
end

local function inoutback(t, b, c, d, s)
	if not s then s = 1.70158 end
	s = s * 1.525
	t = t / d * 2
	if t < 1 then
		return c / 2 * (t * t * ((s + 1) * t - s)) + b
	else
		t = t - 2
		return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
	end
end

local function outinback(t, b, c, d, s)
	if t < d / 2 then
		return outback(t * 2, b, c / 2, d, s)
	else
		return inback((t * 2) - d, b + c / 2, c / 2, d, s)
	end
end

local function outbounce(t, b, c, d)
	t = t / d
	if t < 1 / 2.75 then
		return c * (7.5625 * t * t) + b
	elseif t < 2 / 2.75 then
		t = t - (1.5 / 2.75)
		return c * (7.5625 * t * t + 0.75) + b
	elseif t < 2.5 / 2.75 then
		t = t - (2.25 / 2.75)
		return c * (7.5625 * t * t + 0.9375) + b
	else
		t = t - (2.625 / 2.75)
		return c * (7.5625 * t * t + 0.984375) + b
	end
end

local function inbounce(t, b, c, d)
	return c - outbounce(d - t, 0, c, d) + b
end

local function inoutbounce(t, b, c, d)
	if t < d / 2 then
		return inbounce(t * 2, 0, c, d) * 0.5 + b
	else
		return outbounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
	end
end

local function outinbounce(t, b, c, d)
	if t < d / 2 then
		return outbounce(t * 2, b, c / 2, d)
	else
		return inbounce((t * 2) - d, b + c / 2, c / 2, d)
	end
end

M.linear = linear
M.inquad = inquad
M.outquad = outquad
M.inoutquad = inoutquad
M.outinquad = outinquad
M.incubic = incubic
M.outcubic = outcubic
M.inoutcubic = inoutcubic
M.outincubic = outincubic
M.inquart = inquart
M.outquart = outquart
M.inoutquart = inoutquart
M.outinquart = outinquart
M.inquint = inquint
M.outquint = outquint
M.inoutquint = inoutquint
M.outinquint = outinquint
M.insine = insine
M.outsine = outsine
M.inoutsine = inoutsine
M.outinsine = outinsine
M.inexpo = inexpo
M.outexpo = outexpo
M.inoutexpo = inoutexpo
M.outinexpo = outinexpo
M.incirc = incirc
M.outcirc = outcirc
M.inoutcirc = inoutcirc
M.outincirc = outincirc
M.inelastic = inelastic
M.outelastic = outelastic
M.inoutelastic = inoutelastic
M.outinelastic = outinelastic
M.inback = inback
M.outback = outback
M.inoutback = inoutback
M.outinback = outinback
M.inbounce = inbounce
M.outbounce = outbounce
M.inoutbounce = inoutbounce
M.outinbounce = outinbounce

-- The constants from go.EASING_* and gui.EASING_* are the same
M.DEFOLD_EASINGS = {
	[go.EASING_INBACK] = inback,
	[go.EASING_INBOUNCE] = inbounce,
	[go.EASING_INCIRC] = incirc,
	[go.EASING_INCUBIC] = incubic,
	[go.EASING_INELASTIC] = inelastic,
	[go.EASING_INEXPO] = inexpo,
	[go.EASING_INOUTBACK] = inoutback,
	[go.EASING_INOUTBOUNCE] = inoutbounce,
	[go.EASING_INOUTCIRC] = inoutcirc,
	[go.EASING_INOUTCUBIC] = inoutcubic,
	[go.EASING_INOUTELASTIC] = inoutelastic,
	[go.EASING_INOUTEXPO] = inoutexpo,
	[go.EASING_INOUTQUAD] = inoutquad,
	[go.EASING_INOUTQUART] = inoutquart,
	[go.EASING_INOUTQUINT] = inoutquint,
	[go.EASING_INOUTSINE] = inoutsine,
	[go.EASING_INQUAD] = inquad,
	[go.EASING_INQUART] = inquart,
	[go.EASING_INQUINT] = inquint,
	[go.EASING_INSINE] = insine,
	[go.EASING_LINEAR] = linear,
	[go.EASING_OUTBACK] = outback,
	[go.EASING_OUTBOUNCE] = outbounce,
	[go.EASING_OUTCIRC] = outcirc,
	[go.EASING_OUTCUBIC] = outcubic,
	[go.EASING_OUTELASTIC] = outelastic,
	[go.EASING_OUTEXPO] = outexpo,
	[go.EASING_OUTINBACK] = outinback,
	[go.EASING_OUTINBOUNCE] = outinbounce,
	[go.EASING_OUTINCIRC] = outincirc,
	[go.EASING_OUTINCUBIC] = outincubic,
	[go.EASING_OUTINELASTIC] = outinelastic,
	[go.EASING_OUTINEXPO] = outinexpo,
	[go.EASING_OUTINQUAD] = outinquad,
	[go.EASING_OUTINQUART] = outinquart,
	[go.EASING_OUTINQUINT] = outinquint,
	[go.EASING_OUTINSINE] = outinsine,
	[go.EASING_OUTQUAD] = outquad,
	[go.EASING_OUTQUART] = outquart,
	[go.EASING_OUTQUINT] = outquint,
	[go.EASING_OUTSINE] = outsine
}

return M
