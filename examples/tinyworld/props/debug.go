embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"pointa\"\n"
  "material: \"/light_and_shadows/materials/fog_sprite/fog_sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/examples/tinyworld/tiles.atlas\"\n"
  "}\n"
  ""
  position {
    y: 0.1
  }
  rotation {
    x: 0.70710677
    w: 0.70710677
  }
}
embedded_components {
  id: "label"
  type: "label"
  data: "size {\n"
  "  x: 128.0\n"
  "  y: 32.0\n"
  "}\n"
  "tracking: -0.2\n"
  "text: \"11.2\\n"
  "\"\n"
  "  \"\"\n"
  "font: \"/builtins/fonts/debug/always_on_top.font\"\n"
  "material: \"/builtins/fonts/label-df.material\"\n"
  ""
  position {
    y: 4.0
  }
  scale {
    x: 0.5
    y: 0.5
  }
}
