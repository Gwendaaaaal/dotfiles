local status, _ = pcall(vim.cmd, "colorscheme nightly")
if not status then
  print("Colorscheme not found!")
  return
end
