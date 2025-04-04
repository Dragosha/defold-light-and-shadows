-- Binding module. 
-- Setup your controllers here. Keyboard, mouse, gamepad, virtual_stick

local inputmapper = {}
local input 	= require "in.state"
local mapper	= require "in.mapper"
local triggers 	= require "in.triggers"
local virtual_stick = require 'helper.virtual_stick'

local h = {}
inputmapper.h = h
h.LEFT = hash("LEFT")
h.RIGHT = hash("RIGHT")
h.UP = hash("UP")
h.DOWN = hash("DOWN")
h.JUMP = hash("jump")
h.FIRE = hash("fire")
h.UNIT = hash("unit")
h.DEFAULT = hash("default")

function inputmapper.init(self, acquire, id)
	local i = input.create()
	mapper.bind(triggers.KEY_LEFT, h.LEFT, id)
	mapper.bind(triggers.KEY_RIGHT, h.RIGHT, id)
	mapper.bind(triggers.KEY_UP, h.UP, id)
	mapper.bind(triggers.KEY_DOWN, h.DOWN, id)
	mapper.bind(triggers.KEY_A, h.LEFT, id)
	mapper.bind(triggers.KEY_D, h.RIGHT, id)
	mapper.bind(triggers.KEY_W, h.UP, id)
	mapper.bind(triggers.KEY_S, h.DOWN, id)
	mapper.bind(triggers.KEY_SPACE, h.JUMP, id)
	mapper.bind(triggers.KEY_X, h.FIRE, id)
	mapper.bind(triggers.KEY_L, h.FIRE, id)
	mapper.bind(triggers.GAMEPAD_LPAD_LEFT, h.LEFT, id)
	mapper.bind(triggers.GAMEPAD_LPAD_RIGHT, h.RIGHT, id)
	mapper.bind(triggers.GAMEPAD_LPAD_UP, h.UP, id)
	mapper.bind(triggers.GAMEPAD_LPAD_DOWN, h.DOWN, id)
	mapper.bind(triggers.GAMEPAD_RPAD_DOWN, h.JUMP, id)
	mapper.bind(triggers.GAMEPAD_RPAD_LEFT, h.FIRE, id)
	-- mapper.bind(triggers.MOUSE_BUTTON_LEFT, h.FIRE, id)
	-- mapper.bind(triggers.MOUSE_BUTTON_RIGHT, h.DODGE, id)

	if acquire then 
		i.acquire() 
	end
	-- i.clear()
	return i
end

local map = {
	[hash("jump")] = h.JUMP,
	[hash("left")] = h.LEFT,
	[hash("right")] = h.RIGHT,
}


inputmapper.VIRTUAL = 3
inputmapper.GAMEPAD = 2
inputmapper.KEYBOARD = 1
inputmapper.input = 0
inputmapper.dx = 0
inputmapper.dy = 0
inputmapper.gamepad_active = false
	
function inputmapper.on_message(self, message_id, message, sender, fmap)
	
	local ret = false 
	-- VIRTUAL pad messages:
	if message_id == virtual_stick.ANALOG then
		-- update state of all directions in one message
		local threshold = 0.1
		message.pressed = message.x < -threshold
		message.released = not message.pressed 
		-- There is no repeat state at in.state module, so we can just turn on/off for each KEY
		self.input.on_input(h.LEFT, message)

		message.pressed = message.x > threshold
		message.released = not message.pressed
		self.input.on_input(h.RIGHT, message)

		message.pressed = message.y < -threshold
		message.released = not message.pressed
		self.input.on_input(h.DOWN, message)

		message.pressed = message.y > threshold
		message.released = not message.pressed
		self.input.on_input(h.UP, message)

		inputmapper.dx = math.abs(message.x)
		inputmapper.dy = math.abs(message.y)
		inputmapper.input = inputmapper.VIRTUAL

		--print(message.x,message.y,message.pressed,message.released)
		ret = true
	elseif message_id == virtual_stick.BUTTON then
		if map[message.id] then
			self.input.on_input(map[message.id], message)
		end
		if fmap[message.id] and message.released then
			fmap[message_id](self)
		end
		ret = true
	end
	return ret
end

function inputmapper.on_input(self, action_id, action, fmap)

	local mapped_action_id = mapper.on_input(action_id, self.hero_id)

	if not (action_id == triggers.MOUSE_BUTTON_LEFT) then 
		self.input.on_input(mapped_action_id, action)
		inputmapper.dx = 1
		inputmapper.dy = 1
		inputmapper.input = inputmapper.KEYBOARD
	end
	
	if triggers.is_gamepad(action_id) then
		inputmapper.gamepad_active = true
	else
		inputmapper.gamepad_active = false
	end
	local threshold = 0.45

	if  action_id == triggers.GAMEPAD_LSTICK_LEFT then
		action.pressed = action.value > threshold
		action.released = not action.pressed
		self.input.on_input(h.LEFT, action)
		inputmapper.dx = math.abs(action.value)
		inputmapper.input = inputmapper.VIRTUAL

	elseif  action_id == triggers.GAMEPAD_LSTICK_RIGHT then
		action.pressed = action.value > threshold
		action.released = not action.pressed
		self.input.on_input(h.RIGHT, action)
		inputmapper.dx = math.abs(action.value)
		inputmapper.input = inputmapper.VIRTUAL

	elseif  action_id == triggers.GAMEPAD_LSTICK_UP then
		action.pressed = action.value > threshold
		action.released = not action.pressed
		self.input.on_input(h.UP, action)
		inputmapper.dy = math.abs(action.value)
		inputmapper.input = inputmapper.VIRTUAL

	elseif  action_id == triggers.GAMEPAD_LSTICK_DOWN then
		action.pressed = action.value > threshold
		action.released = not action.pressed
		self.input.on_input(h.DOWN, action)
		inputmapper.dy = math.abs(action.value)
		inputmapper.input = inputmapper.VIRTUAL
	end

	if action.released and fmap[mapped_action_id] then
		fmap[mapped_action_id](self)
	end

end

function inputmapper.gamepad_lookat(self)
	if self.input.is_pressed(h.LEFT) or self.direction == -1 then
		self.look_at.x = self.position.x - 10
	elseif self.input.is_pressed(h.RIGHT) or self.direction == 1 then
		self.look_at.x = self.position.x + 10
	else
		self.look_at.x = self.position.x
	end
	if self.input.is_pressed(h.UP) then
		self.look_at.z = self.position.z - 10
		if not self.input.is_pressed(h.LEFT) and not self.input.is_pressed(h.RIGHT) then self.look_at.x = self.position.x end
	elseif self.input.is_pressed(h.DOWN) then
		self.look_at.z = self.position.z + 10
		if not self.input.is_pressed(h.LEFT) and not self.input.is_pressed(h.RIGHT) then self.look_at.x = self.position.x end
	else
		self.look_at.z = self.position.z
	end
end
return inputmapper