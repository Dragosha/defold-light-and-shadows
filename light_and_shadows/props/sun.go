components {
  id: "sun"
  component: "/light_and_shadows/sun.script"
}
embedded_components {
  id: "label"
  type: "label"
  data: "size {\n"
  "  x: 50.0\n"
  "  y: 32.0\n"
  "}\n"
  "text: \"Sun\"\n"
  "font: \"/builtins/fonts/default.font\"\n"
  "material: \"/light_and_shadows/materials/hidden_label.material\"\n"
  ""
  position {
    y: 7.385
  }
  scale {
    x: 0.4
    y: 0.4
    z: 0.4
  }
}
embedded_components {
  id: "model"
  type: "model"
  data: "mesh: \"/light_and_shadows/props/bulb_dir.glb\"\n"
  "name: \"unnamed\"\n"
  "materials {\n"
  "  name: \"material_0\"\n"
  "  material: \"/light_and_shadows/materials/hidden_model/yellow.material\"\n"
  "}\n"
  ""
}
