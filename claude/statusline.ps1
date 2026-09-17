# Claude Code 상태줄(Status Line) 스크립트
param()

$esc      = [char]27
$reset    = "$esc[0m"
$bold     = "$esc[1m"
$dim      = "$esc[2m"
$red      = "$esc[31m"
$green    = "$esc[32m"
$yellow   = "$esc[33m"
$blue     = "$esc[34m"
$magenta  = "$esc[35m"
$cyan     = "$esc[36m"
$lgray    = "$esc[37m"
$gray     = "$esc[90m"
$bblue    = "$esc[94m" # bright blue (for input tokens)
$bcyan    = "$esc[96m" # bright cyan (for output tokens)
$delim    = "${dim} | ${reset}"

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $data = [Console]::In.ReadToEnd() | ConvertFrom-Json # Read JSON from stdin
} catch {
    $msg = ($_.Exception.Message -replace "\r?\n", " ")
    [Console]::Out.Write("${red}[Status Line Error]: ${msg}${reset}")
    exit 0
}
if ($null -eq $data) {
    [Console]::Out.Write("${red}[Status Line Error]: JSON data is empty or invalid.${reset}")
    exit 0
}

################################################################################

# 사용률(%)에 따른 색상 반환
function Get-UsageColor([int]$percent) {
    if     ($percent -ge 90) { return $red    } # 90% 이상
    elseif ($percent -ge 70) { return $yellow }
    else                     { return $green  } # 70% 미만
}

# 시간을 사람이 읽기 쉬운 표기로 변환 ("4d3h", "2h12m", "45m", "now")
function Format-Duration([long]$totalSec) {
    if ($totalSec -le 0) { return "now" }
    $d = [int][math]::Floor($totalSec / 86400)
    $h = [int][math]::Floor(($totalSec % 86400) / 3600)
    $m = [int][math]::Floor(($totalSec % 3600) / 60)
    if ($d -gt 0) { return "${d}d${h}h" }
    if ($h -gt 0) { return "${h}h${m}m" }
    return "${m}m"
}

function Format-Tokens([double]$tokens) {
    if ($tokens -ge 1000000) {
        $m = $tokens / 1000000
        if ($m -lt 10) { return ("{0:F1}M" -f $m) }
        return ("{0:F0}M" -f $m)
    }
    if ($tokens -ge 1000) {
        $k = $tokens / 1000
        if ($k -lt 10) { return ("{0:F1}k" -f $k) }
        return ("{0:F0}k" -f $k)
    }
    return ([int]$v).ToString()
}

function Test-GitRepo([string]$path) {
    if ([string]::IsNullOrEmpty($path)) { return $false }
    }
    return $false
}

################################################################################

function Get-DirField($data) {
    $cwdFull = $data.cwd
    if ([string]::IsNullOrEmpty($cwdFull)) {
        $cwdDisplay = "?"
    } else {
        $cwdDisplay = Split-Path -Leaf $cwdFull
        if ([string]::IsNullOrEmpty($cwdDisplay)) { $cwdDisplay = $cwdFull }
    }
    $dirName = "${cyan}${cwdDisplay}${reset}"
    $branch = ""
    if (-not [string]::IsNullOrEmpty($cwdFull) -and (Test-GitRepo $cwdFull)) {
        try {
            $b = & git -C $cwdFull rev-parse --abbrev-ref HEAD 2>$null
            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrEmpty($b)) {
                $branch = $b.Trim()
            }
        } catch {
        }
    }
    if ($branch) {
        return "${dirName} ${yellow}${bold}(${branch})${reset}"
    }
    return "${dirName} ${lgray}(no-git)${reset}"
}

function Get-ModelField($data) {
    $model = $data.model.display_name
    if ([string]::IsNullOrEmpty($model)) {
        $model = $data.model.id
    }
    if ($model) {
        $model = $model.Replace(" context", "").Replace("(", "").Replace(")", "")
    }
    if ($model) { return "${green}${model}${reset}" }
    return $null
}

function Get-EffortField($data) {
    $level   = $data.effort.level
    $thinkOn = $data.thinking.enabled -eq $true
    if (-not ($level -or $thinkOn)) { return $null }
    $bits = @()
    if ($level) {
        $color = switch ($level) {
            "high"  { $yellow }
            "xhigh" { $red    }
            "max"   { $red    }
            default { $reset  }
        }
        $bits += "${color}${level}${reset}"
    }
    if ($thinkOn) {
        $bits += "${cyan}+think${reset}"
    }
    return ($bits -join "")
}

function Get-ContextLineField($data) {
    $bits = @()
    $usedPct = $data.context_window.used_percentage
    if ($null -ne $usedPct) {
        $usedPct = [math]::Round([double]$usedPct)
    } else {
        $total  = $data.context_window.total_input_tokens
        $maxWin = $data.context_window.context_window_size
        if ($maxWin -and $maxWin -gt 0) {
            $usedPct = [math]::Round(([double]$total / [double]$maxWin) * 100)
        }
    }
    if ($null -ne $usedPct) {
        $bits += "${bold}${magenta}ctx:${reset}${usedPct}%"
    }
    $linesAdd = if ($null -ne $data.cost.total_lines_added)   { [int]$data.cost.total_lines_added   } else { 0 }
    $linesDel = if ($null -ne $data.cost.total_lines_removed) { [int]$data.cost.total_lines_removed } else { 0 }
    $bits += "${green}+${linesAdd}${reset}${lgray}/${reset}${red}-${linesDel}${reset}"
    return ($bits -join ' ')
}

function Get-TokenUsage($data) {
    $cumBase  = $data.context_window.total_input_tokens
    $cumOut   = $data.context_window.total_output_tokens
    $cumCache = $null

        }

        $found = $false
        foreach ($file in $files) {
            try { $lines = [System.IO.File]::ReadLines($file) } catch { continue }
            foreach ($line in $lines) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                try { $obj = $line | ConvertFrom-Json } catch { continue }
                if ($obj.type -ne "assistant") { continue }
                $usage = $obj.message.usage
                if ($null -eq $usage) { continue }
                $id = $obj.message.id
                if (-not $id) { $id = $obj.uuid }
                $found = $true
                if ($null -ne $usage.input_tokens)                { $base  += [long]$usage.input_tokens }
                if ($null -ne $usage.cache_read_input_tokens)     { $cache += [long]$usage.cache_read_input_tokens }
                if ($null -ne $usage.cache_creation_input_tokens) { $cache += [long]$usage.cache_creation_input_tokens }
                if ($null -ne $usage.output_tokens)               { $out   += [long]$usage.output_tokens }
            }
        }
        if ($found) {
            $cumBase  = $base
            $cumCache = $cache
            $cumOut   = $out
        }
    }

    $upArrow   = [char]0x2191
    $downArrow = [char]0x2193
    $bits = @()
    if ($null -ne $cumBase)  { $bits += "${bblue}${upArrow}$(Format-Tokens $cumBase)${reset}" }
    if ($null -ne $cumOut)   { $bits += "${bcyan}${downArrow}$(Format-Tokens $cumOut)${reset}" }
    if ($null -ne $cumCache) { $bits += "${gray}($(Format-Tokens $cumCache))${reset}" }
    if ($bits.Count -eq 0) { return $null }
    return ($bits -join ' ')
}

function Get-CostTokenField($data) {
    $cost = 0.0
    if ($null -ne $data.cost.total_cost_usd) {
        $cost = [double]$data.cost.total_cost_usd
    }
}

function Get-RateLimitField($data) {
    $nowEpoch = [long][math]::Floor(([DateTimeOffset]::UtcNow).ToUnixTimeSeconds())
    $bits = @()

    $fiveHour = $data.rate_limits.five_hour
    if ($null -ne $fiveHour -and $null -ne $fiveHour.used_percentage) {
        $percent = [math]::Round([double]$fiveHour.used_percentage)
        $color   = Get-UsageColor $percent
        $text    = "${lgray}5h:${reset}${color}${percent}%${reset}"
        if ($null -ne $fiveHour.resets_at) {
            $untilReset = Format-Duration ([long]$fiveHour.resets_at - $nowEpoch)
            $text += " ${gray}(${untilReset})${reset}"
        }
        $bits += $text
    }

    $sevenDay = $data.rate_limits.seven_day
    if ($null -ne $sevenDay -and $null -ne $sevenDay.used_percentage) {
        $percent = [math]::Round([double]$sevenDay.used_percentage)
        $color   = Get-UsageColor $percent
        $text    = "${lgray}7d:${reset}${color}${percent}%${reset}"
        if ($null -ne $sevenDay.resets_at) {
            $untilReset = Format-Duration ([long]$sevenDay.resets_at - $nowEpoch)
            $text += " ${gray}(${untilReset})${reset}"
        }
        $bits += $text
    }

    if ($bits.Count -gt 0) { return ($bits -join $delim) }
    return $null
}

function Get-VersionField($data) {
    $verFull = $data.version
    if ([string]::IsNullOrEmpty($verFull)) { return $null }
    $verLast = $verFull.Split(".")[-1]
    return "${dim}cc.${verLast}${reset}"
}

################################################################################

try {
    $parts = @(
        (Get-DirField         $data),
        (Get-ModelField       $data),
        (Get-EffortField      $data),
        (Get-ContextLineField $data),
        (Get-CostTokenField   $data),
        (Get-RateLimitField   $data),
        (Get-VersionField     $data)
    ) | Where-Object { $_ -ne $null }
    [Console]::Out.Write(($parts -join $delim))
} catch {
    $msg = ($_.Exception.Message -replace "\r?\n", " ")
    [Console]::Out.Write("${red}[Status Line Error]: ${msg}${reset}")
}
