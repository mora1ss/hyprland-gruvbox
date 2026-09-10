-- Keep 1-5 alive when empty so the bar always shows the same slots.
for i = 1, 5 do
  hl.workspace_rule({
    workspace = tostring(i),
    persistent = true,
  })
end
