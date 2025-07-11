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
components {
  id: "shad1"
  component: "/examples/tinyworld/3D/shad.sprite"
  position {
    x: 8.0
    y: 0.3
    z: -7.0
  }
  rotation {
    x: 0.70710677
    w: 0.70710677
  }
}
components {
  id: "shad2"
  component: "/examples/tinyworld/3D/shad.sprite"
  position {
    x: 9.0
    y: 0.3
    z: 10.0
  }
  rotation {
    x: 0.70710677
    w: 0.70710677
  }
}
components {
  id: "shad3"
  component: "/examples/tinyworld/3D/shad.sprite"
  position {
    x: 5.0
    y: 0.3
    z: -23.0
  }
  rotation {
    x: 0.70710677
    w: 0.70710677
  }
}
components {
  id: "shad4"
  component: "/examples/tinyworld/3D/shad.sprite"
  position {
    x: -6.0
    y: 0.3
    z: -25.0
  }
  rotation {
    x: 0.70710677
    w: 0.70710677
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"tree1\"\n"
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
    y: 8.5
  }
}
embedded_components {
  id: "sprite2"
  type: "sprite"
  data: "default_animation: \"tree2\"\n"
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
    x: 8.0
    y: 9.0
    z: -7.0
  }
}
embedded_components {
  id: "sprite4"
  type: "sprite"
  data: "default_animation: \"tree1\"\n"
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
    x: 9.0
    y: 8.5
    z: 10.0
  }
}
embedded_components {
  id: "sprite6"
  type: "sprite"
  data: "default_animation: \"tree1\"\n"
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
    x: 5.0
    y: 8.5
    z: -23.0
  }
}
embedded_components {
  id: "sprite8"
  type: "sprite"
  data: "default_animation: \"tree2\"\n"
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
    x: -6.0
    y: 9.0
    z: -25.0
  }
}
