components {
  id: "player"
  component: "/examples/example2/player/player.script"
}
components {
  id: "dust"
  component: "/examples/example2/player/dust.particlefx"
}
components {
  id: "landing"
  component: "/examples/example2/player/landing.particlefx"
  position {
    z: 1.0
  }
}
embedded_components {
  id: "co"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_KINEMATIC\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"unit\"\n"
  "mask: \"default\"\n"
  "mask: \"unit\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "      y: 6.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "  }\n"
  "  data: 6.0\n"
  "}\n"
  ""
}
embedded_components {
  id: "trig"
  type: "collisionobject"
  data: "type: COLLISION_OBJECT_TYPE_TRIGGER\n"
  "mass: 0.0\n"
  "friction: 0.1\n"
  "restitution: 0.5\n"
  "group: \"unit\"\n"
  "mask: \"coin\"\n"
  "embedded_collision_shape {\n"
  "  shapes {\n"
  "    shape_type: TYPE_SPHERE\n"
  "    position {\n"
  "      y: 6.0\n"
  "    }\n"
  "    rotation {\n"
  "    }\n"
  "    index: 0\n"
  "    count: 1\n"
  "  }\n"
  "  data: 7.5\n"
  "}\n"
  ""
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"noname\"\n"
  "material: \"/light_and_shadows/materials/sprite/light_sprite.material\"\n"
  "size {\n"
  "  x: 192.0\n"
  "  y: 303.0\n"
  "}\n"
  "textures {\n"
  "  sampler: \"tex0\"\n"
  "  texture: \"/assets/rgba/tiles.atlas\"\n"
  "}\n"
  "textures {\n"
  "  sampler: \"tex1\"\n"
  "  texture: \"/assets/rgba/tiles.atlas\"\n"
  "}\n"
  ""
  rotation {
    x: -0.23004974
    w: 0.97317886
  }
  scale {
    x: 0.04
    y: 0.04
    z: 0.04
  }
}
