-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "tokyonight",

	hl_add = {
		-- YAML: keys -> snazzy cyan, values -> snazzy pink
		-- vim-syntax groups (no TS parser); TS groups kept for if it gets installed
		-- keys
		yamlBlockMappingKey = { fg = "#9aedfe" },
		["@property.yaml"] = { fg = "#9aedfe" },
		["@field.yaml"] = { fg = "#9aedfe" },
		-- values
		yamlFlowString = { fg = "#ff6ac1" },
		yamlPlainScalar = { fg = "#ff6ac1" },
		yamlBlockString = { fg = "#ff6ac1" },
		yamlString = { fg = "#ff6ac1" },
		yamlBool = { fg = "#ff6ac1" },
		yamlInteger = { fg = "#ff6ac1" },
		yamlFloat = { fg = "#ff6ac1" },
		["@string.yaml"] = { fg = "#ff6ac1" },
		["@boolean.yaml"] = { fg = "#ff6ac1" },
		["@number.yaml"] = { fg = "#ff6ac1" },
	},
}

-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
-- }

return M
