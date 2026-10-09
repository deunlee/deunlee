function c { Clear-Host }
function q { exit }
function ll { eza -alhF -l --icons --group-directories-first --time-style=long-iso --color-scale=age @args }

function cc {
    $old = $env:CLAUDE_CONFIG_DIR
    $env:CLAUDE_CONFIG_DIR = Join-Path $HOME '.claude1'
    try { claude @args } finally { $env:CLAUDE_CONFIG_DIR = $old }
}
function cc2 {
    $old = $env:CLAUDE_CONFIG_DIR
    $env:CLAUDE_CONFIG_DIR = Join-Path $HOME '.claude2'
    try { claude @args } finally { $env:CLAUDE_CONFIG_DIR = $old }
}
function cc3 {
    $old = $env:CLAUDE_CONFIG_DIR
    $env:CLAUDE_CONFIG_DIR = Join-Path $HOME '.claude3'
    try { claude @args } finally { $env:CLAUDE_CONFIG_DIR = $old }
}

    $packageIds = @(
    )
    foreach ($id in $packageIds) {
        winget install --id $id --exact --scope machine
    }
}
