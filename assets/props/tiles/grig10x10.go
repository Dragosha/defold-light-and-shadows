embedded_components {
  id: "collisionobject"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_STATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"default\"\n"
  "mask: \"default\"\n"
  "mask: \"unit\"\n"
  "mask: \"bullet\"\n"
  "mask: \"bullet2\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_BOX\n"
  "    position {\n"
  "      y: -0.5\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 3\n"
  "  }\n"
  "  data: 25.0\n"
  "  data: 0.5\n"
  "  data: 25.0\n"
  "}\n"
  ""
}
embedded_components {
  id: "model"
  type: "model"
  data: "mesh: \"/assets/images/tiles/grid10x10.dae\"\n"
  "name: \"unnamed\"\n"
  "materials {\n"
  "  name: \"default\"\n"
  "  material: \"/light_and_shadows/materials/model/model_world_nocast.material\"\n"
  "  textures {\n"
  "    sampler: \"tex0\"\n"
  "    texture: \"/assets/images/tiles/bg.png\"\n"
  "  }\n"
  "  textures {\n"
  "    sampler: \"tex1\"\n"
  "    texture: \"/assets/images/tiles/bg.png\"\n"
  "  }\n"
  "}\n"
  ""
  position {
    y: -0.01
  }
}
