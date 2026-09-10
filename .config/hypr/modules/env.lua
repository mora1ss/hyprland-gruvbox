local v = require("modules/vars")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("HYPRSHOT_DIR", v.home .. "/Imagens/Capturas")

pcall(require, "nvidia")
