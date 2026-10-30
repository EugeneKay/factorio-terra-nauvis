-- Never edit by hand: rerun the tool.
local F = {}
F.seg = {parameters = {"px", "py", "ax", "ay", "ux", "uy", "a", "b"}, expression = "ex * ex + ey * ey",
  local_expressions = {dx = "px - ax", dy = "py - ay", t = "clamp(dx * a + dy * b, 0, 1)",
                       ex = "dx - t * ux", ey = "dy - t * uy"}}
F.box = {parameters = {"px", "py", "cx", "cy", "tx", "ty", "hl", "hw"},
  expression = "max(abs(dx * tx + dy * ty) - hl, abs(dy * tx - dx * ty) - hw)",
  local_expressions = {dx = "px - cx", dy = "py - cy"}}
local S = {functions = F}
  -36, 0.013888889, -0.013888889))))"
return S
