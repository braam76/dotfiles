-- Load options first so the leader keys are set before mappings are defined.
require "config.options"
require "config.diagnostics"
require "config.keymaps"
require "config.theme"

require "config.plugins.flash"
require "config.plugins.which_key"
require "config.plugins.markdown"
require "config.plugins.editing"
require "config.plugins.lsp" -- Also loads Conform before its setup below.
require "config.plugins.formatting"
require "config.plugins.mini"
require "config.plugins.git"
require "config.plugins.oil"
require "config.plugins.abolish"
