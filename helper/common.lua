local common = {}

common.is_debug = sys.get_engine_info().is_debug

common.WHITE  = vmath.vector4(1, 1, 1, 1)
common.RED    = vmath.vector4(1, 0, 0, 1)
common.GREEN  = vmath.vector4(0, 1, 0, 1)
common.YELLOW = vmath.vector4(1, 1, 0, 1)
function common.line(start_point, end_point, color)
    if common.is_debug then
        msg.post("@render:", "draw_line", { start_point = start_point, end_point = end_point, color = color } )
    end
end

function common.init_default_random()
    math.randomseed(100000 * (socket.gettime() % 1))
    math.random()
    math.random()
    math.random()
end

function common.check_game_object(id)
    local ok, err = pcall(go.get_position, id)
    return ok
end

function common.is_web_mobile()
    if html5 then
        return html5.run("(typeof window.orientation !== 'undefined') || (navigator.userAgent.indexOf('IEMobile') !== -1);") == "true"
    end
    return false
end

function common.is_mobile()
    if common.is_mobile_checked then return common.is_mobile_checked end
    local info = sys.get_sys_info()
    if info.system_name == "Android" or info.system_name == "iPhone OS" then
        common.is_mobile_checked = true
    else
        common.is_mobile_checked = false
    end
    return common.is_mobile_checked
end


function common.clamp(x, min, max)
    return x < min and min or (x > max and max or x)
  end

common.cam_pos = vmath.vector3()
common.is_sound_on = true
common.sound_url = "/sounds#"
common.sounds = {
    [hash("button")] = "button",
 }

function common.pan(position, gain_pow)
    local v = common.cam_pos - position
    local len = vmath.length(v)
    local gain = common.clamp (20 / (len + 0.01), 0, 1) * common.clamp ((gain_pow or 1), 0, 2)
    local pan = common.clamp(-v.x / 40, -1, 1)

    return {gain = gain, pan = pan}
end

function common.play_sound(name, param, callback)
    if type(name) == "string" then
        name = hash(name)
    end

    local url = common.sounds[name]
    if common.is_sound_on and url then
        if type(url) == 'table' then url = url[math.random(#url)] end
        if url then 
            sound.play(common.sound_url..url, param, callback) 
        end
    end
end

function common.check_game_object(id)
    local ok, err = pcall(go.get_position, id)
    return ok
end



return common