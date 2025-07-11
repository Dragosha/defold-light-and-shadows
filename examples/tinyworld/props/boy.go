components {
  id: "shad"
  component: "/examples/tinyworld/3D/shad.sprite"
  position {
    y: 0.3
  }
  rotation {
    x: 0.70710677
    w: 0.70710677
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"boyidle\"\n"
  "material: \"/examples/tinyworld/materials/billboard_light_sprite_nearest.material\"\n"
  "textures {\n"
  "  sampler: \"tex0\"\n"
  "  texture: \"/examples/tinyworld/tiles.atlas\"\n"
  "}\n"
  "textures {\n"
  "  sampler: \"tex1\"\n"
  "  texture: \"/examples/tinyworld/tiles.atlas\"\n"
  "}\n"
  ""
  position {
    y: 9.0
  }
}
