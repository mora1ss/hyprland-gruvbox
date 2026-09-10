-- Hyprland Lua config (required from 0.55+; silences the .conf deprecation notice)
-- https://wiki.hypr.land/Configuring/Start/
-- Source of truth. hyprland.conf is leftover hyprlang and is not loaded when this file exists.

require("modules/monitors")
require("modules/env")
require("modules/look")
require("modules/animations")
require("modules/input")
require("modules/autostart")
require("modules/keybinds")
require("modules/windowrules")
