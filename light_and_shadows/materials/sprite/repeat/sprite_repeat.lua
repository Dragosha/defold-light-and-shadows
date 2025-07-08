--  More info: https://github.com/Dragosha/defold-sprite-repeat

local M = {}

function M.create(sprite_url, sprite_id, self)

	local atlas_data
	local tex_info
	-- use precashed atlas info if them is available 
	if self and self.atlas_data and self.tex_info then
		atlas_data = self.atlas_data
		tex_info = self.tex_info
	else
		local atlas = go.get(sprite_url, "image")
		atlas_data = resource.get_atlas(atlas)
		tex_info = resource.get_texture_info(atlas_data.texture)
		if self then
			self.atlas_data = atlas_data
			self.tex_info = tex_info
		end
	end
	local tex_w = tex_info.width
	local tex_h = tex_info.height

	local animation_data

	local in_sprite_id = sprite_id
	if sprite_id and type(sprite_id) == "string" then
		in_sprite_id = hash(sprite_id)
	end

	local sprite_image_id = in_sprite_id or go.get(sprite_url, "animation")
	for i, animation in ipairs(atlas_data.animations) do
		if hash(animation.id) == sprite_image_id then
			animation_data = animation
			-- print(i, animation.id, animation.width, animation.height, animation.frame_start)
			break
		end
	end
	assert(animation_data, "Unable to find image " .. sprite_image_id)

	local frames = {}
	for index = animation_data.frame_start, animation_data.frame_end - 1 do

		local uvs = atlas_data.geometries[index].uvs
		assert(#uvs == 8, "Sprite trim mode should be disabled for the images.")


		local position_x = uvs[1]
		local position_y = uvs[6]
		local width = uvs[5] - uvs[1]
		local height = uvs[2] - uvs[6]

		if height < 0 then
			-- In case the atlas builder has flipped the sprite to optimise the space.
			position_y = uvs[2]
			height = uvs[6] - uvs[2]
		end

		local u1 = (position_x) / tex_w
		local v1 = (tex_h - (position_y)) / tex_h

		local frame = {
			uv_coord =  vmath.vector4(
				u1,
				v1,
				u1 + width / tex_w,
				v1 - height / tex_h
			),
			w = width,
			h = height
		}
		table.insert(frames, frame)
	end

	local animation = {
		frames 	= frames,
		width 	= animation_data.width,
		height 	= animation_data.height,
		fps 	= animation_data.fps,
		v 		= vmath.vector4(1, 1, animation_data.width, animation_data.height),
		current_frame = 1,
	}

    -- @param repeat_x 
    -- @param repeat_y
	function animation.animate(repeat_x, repeat_y)

		local frame = animation.frames[1]
		go.set(sprite_url, "uv_coord", frame.uv_coord)
		animation.v.x = repeat_x
		animation.v.y = repeat_y
		animation.v.z = frame.w
		animation.v.w = frame.h
		go.set(sprite_url, "uv_repeat", animation.v)

		if #animation.frames > 1 and animation.fps > 0 then
			animation.handle = 
			timer.delay(1/animation.fps, true, function(self, handle, time_elapsed)
				local frame = animation.frames[animation.current_frame]
				go.set(sprite_url, "uv_coord", frame.uv_coord)
				-- go.set(sprite_url, "uv_repeat", vmath.vector4(repeat_x, repeat_y, frame.w, frame.h))
				
				animation.current_frame = animation.current_frame + 1
				if animation.current_frame > #animation.frames then
					animation.current_frame = 1
				end
			end)
		end
	end

	function animation.stop()
		if animation.handle then
			timer.cancel(animation.handle)
			animation.handle = nil
		end
	end

	return animation
end

return M