components {
  id: "shad"
  component: "/examples/tinyworld/3D/shad.sprite"
  position {
    y: 0.03
  }
  rotation {
    x: 0.70710677
    w: 0.70710677
  }
  scale {
    x: 0.097
    y: 0.097
    z: 0.097
  }
}
embedded_components {
  id: "model"
  type: "model"
  data: "mesh: \"/examples/tinyworld/models/block3.gltf\"\n"
  "name: \"unnamed\"\n"
  "materials {\n"
  "  name: \"default\"\n"
  "  material: \"/examples/tinyworld/materials/model_instanced_nearest.material\"\n"
  "  textures {\n"
  "    sampler: \"tex0\"\n"
  "    texture: \"/examples/tinyworld/models/texture.png\"\n"
  "  }\n"
  "}\n"
  ""
}
