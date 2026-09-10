hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 15,
    border_size = 2,
    col = {
      active_border = { colors = { "rgba(ebdbb2aa)", "rgba(f9f5d7aa)" }, angle = 45 },
      inactive_border = "rgba(595959aa)",
    },
    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle",
  },
  decoration = {
    rounding = 10,
    rounding_power = 4,
    active_opacity = 0.9,
    inactive_opacity = 0.8,
    shadow = {
      enabled = true,
      range = 30,
      render_power = 10,
      color = "rgba(1a1a1aee)",
    },
    blur = {
      enabled = true,
      size = 1,
      passes = 5,
      vibrancy = 0.1696,
    },
  },
  dwindle = {
    preserve_split = true,
  },
  master = {
    new_status = "master",
  },
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
  },
  xwayland = {
    force_zero_scaling = true,
  },
})
