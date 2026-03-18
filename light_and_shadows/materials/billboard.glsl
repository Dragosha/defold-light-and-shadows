vec3 computeScreenBillboard(vec3 center, vec2 local, float scaleX, float scaleY)
{
    vec3 right = vec3(view[0][0], view[1][0], view[2][0]);
    vec3 up    = vec3(view[0][1], view[1][1], view[2][1]);
    return center + right * local.x * scaleX + up * local.y * scaleY;
}

vec3 computeAxisLockedBillboard(vec3 center, vec2 local, float scaleX, float scaleY)
{
    vec3 world_up = vec3(0.0, 1.0, 0.0);
    vec3 camera_position = vec3(
        -dot(view[0].xyz, view[3].xyz),
        -dot(view[1].xyz, view[3].xyz),
        -dot(view[2].xyz, view[3].xyz)
    );
    vec3 camera_vector = camera_position - center;

    // project onto horizontal plane
    camera_vector.y = 0.0;

    // avoid NaN when camera directly above
    if (length(camera_vector) < 0.0001)
    {
        camera_vector = vec3(0.0, 0.0, 1.0);
    }

    camera_vector = normalize(camera_vector);
    vec3 right = normalize(cross(world_up, camera_vector));
    vec3 up = world_up;

    return center + right * local.x * scaleX + up * local.y * scaleY;
}