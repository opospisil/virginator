set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERMINAL alacritty
set -gx GOPATH $HOME/go
set -gx GOROOT $HOME/golang/current
set -gx NODE_HOME $HOME/node/current
set -gx npm_config_prefix $HOME/.local/npm-global

fish_add_path $HOME/.local/bin
fish_add_path $HOME/.local/npm-global/bin
fish_add_path $HOME/go/bin

if test -d $GOROOT/bin
    fish_add_path $GOROOT/bin
end

if test -d $NODE_HOME/bin
    fish_add_path $NODE_HOME/bin
end

if command -q zoxide
    zoxide init fish | source
end

if command -q direnv
    direnv hook fish | source
end
