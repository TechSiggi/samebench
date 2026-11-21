# Colors of the kernel console (jupyter console) to match Liquid Glass.
# Found via JUPYTER_CONFIG_PATH (set in ~/.config/samebench/env.sh). Settings only,
# no logic of its own.
from pygments.token import Token

c = get_config()  # noqa: F821, provided by Jupyter

c.ZMQTerminalInteractiveShell.true_color = True
c.ZMQTerminalInteractiveShell.highlighting_style = "one-dark"
c.ZMQTerminalInteractiveShell.highlighting_style_overrides = {
    Token.Prompt: "#8ff0c8",
    Token.PromptNum: "#8ff0c8 bold",
    Token.OutPrompt: "#c3a6ff",
    Token.OutPromptNum: "#c3a6ff bold",
}
# Shorter startup message
c.ZMQTerminalInteractiveShell.banner = ""
