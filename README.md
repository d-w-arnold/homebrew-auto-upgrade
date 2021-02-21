# Homebrew Auto-Update Tool

Add the following lines to your `~/.bashrc`, `~/.zshrc`, etc. file(s):

(replace `<path>` with the absolute path to this Github project repo)

```shell
# ---------
# Homebrew Auto-Update Config
# ---------

# Change how often to auto-update Homebrew (in days)
export UPDATE_HOMEBREW_DAYS=7

# Path to Homebrew auto-update installation (Github project repo)
export UPDATE_HOMEBREW_PATH=<path>

# Homebrew auto-update script
source $UPDATE_HOMEBREW_PATH/homebrew-updater.sh
```