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
$black    = "$esc[30m"
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
function Get-UsageColor([double]$percent) {
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
    return ([long]$tokens).ToString()
}

function Test-GitRepo([string]$path) {
    if ([string]::IsNullOrEmpty($path)) { return $false }
    while ($null -ne $dir) {
    }
    return $false
}

################################################################################

function Get-LeafName([string]$path) {
}

    } else {
    }
}

function Get-DirField($data) {
    $cwdFull = $data.cwd
    $dirSeg = "${cyan}${cwdDisplay}${reset}"
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
        return "${dirSeg} ${yellow}${bold}(${branch})${reset}"
    }
    return "${dirSeg} ${lgray}(no-git)${reset}"
}

function Get-EffortLabel($data) {
    $level = $data.effort.level
    $color = switch ($level) {
        "low"    { $cyan   }
        "medium" { $yellow }
        "high"   { $red    }
        "xhigh"  { "${black}${bgRed}" }
        "max"    { "${black}${bgBmagenta}" }
        default  { $reset  }
    }
    return "${color}${level}${reset}"
}

function Get-ModelField($data) {
    $model = $data.model.display_name
    if ([string]::IsNullOrEmpty($model)) {
        $model = $data.model.id
    }
        $model = $model.Replace(" context", "").Replace("(", "").Replace(")", "")
    $bits = @()
    if ($model) { $bits += "${green}${model}${reset}" }
    $effort = Get-EffortLabel $data
    if ($effort) { $bits += $effort }
    return ($bits -join " ")
}

function Format-Elapsed($ms) {
    if ($null -eq $ms) { return "-" }
    $sec = [long][math]::Floor([double]$ms / 1000)
    if ($sec -lt 60) { return "0m" }
    return Format-Duration $sec
}

function Get-ContextField($data) {
    $usedPct = $data.context_window.used_percentage
    if ($null -eq $usedPct) {
        $pctStr = "-%"
    } else {
        $pctStr = "$(Get-UsageColor $usedPct)${usedPct}%${reset}"
    }
    $wall = Format-Elapsed $data.cost.total_duration_ms
    $api  = Format-Elapsed $data.cost.total_api_duration_ms
    return "${bold}${magenta}ctx:${reset}${pctStr} ${gray}(${wall}/${api})${reset}"
}

function Get-LinesField($data) {
    $linesAdd = if ($null -ne $data.cost.total_lines_added)   { [int]$data.cost.total_lines_added   } else { 0 }
    $linesDel = if ($null -ne $data.cost.total_lines_removed) { [int]$data.cost.total_lines_removed } else { 0 }
    return "${green}+${linesAdd}${reset}${lgray}/${reset}${red}-${linesDel}${reset}"
}

function Get-TokenUsage($data) {
    $cumBase  = $data.context_window.total_input_tokens
    $cumOut   = $data.context_window.total_output_tokens
    $upArrow   = [char]0x2191
    $downArrow = [char]0x2193
    $bits = @()
    if ($null -ne $cumBase)  { $bits += "${bblue}${upArrow}$(Format-Tokens $cumBase)${reset}" }
    if ($null -ne $cumOut)   { $bits += "${bcyan}${downArrow}$(Format-Tokens $cumOut)${reset}" }
    if ($bits.Count -eq 0) { return $null }
    return ($bits -join ' ')
}

function Get-CostTokenField($data) {
    $cost = 0.0
    if ($null -ne $data.cost.total_cost_usd) {
        $cost = [double]$data.cost.total_cost_usd
    }
    $costStr = "${yellow}`$" + ("{0:F2}" -f $cost) + "${reset}"
    $tokStr = Get-TokenUsage $data
    if ($tokStr) { return "$costStr $tokStr" }
    return $costStr
}

function Format-RateWindow([string]$label, $window, [long]$nowEpoch) {
    $percent = $window.used_percentage
    if ($null -eq $percent) {
        $pctStr = "-%"
    } else {
        $pctStr = "$(Get-UsageColor $percent)${percent}%${reset}"
    }
    if ($null -eq $window.resets_at) {
        $untilReset = "-"
    } else {
        $untilReset = Format-Duration ([long]$window.resets_at - $nowEpoch)
    }
    return "${lgray}${label}:${reset}${pctStr} ${gray}(${untilReset})${reset}"
}

function Get-RateLimitField($data) {
    $nowEpoch = [long][math]::Floor(([DateTimeOffset]::UtcNow).ToUnixTimeSeconds())
    $bits = @(
        (Format-RateWindow "5h" $data.rate_limits.five_hour $nowEpoch),
        (Format-RateWindow "7d" $data.rate_limits.seven_day $nowEpoch)
    )
    return ($bits -join $delim)
}

function Get-VersionField($data) {
    $verFull = $data.version
    if ([string]::IsNullOrEmpty($verFull)) { return $null }
    $verLast = $verFull.Split(".")[-1]
    return "${gray}v.${verLast}${reset}"
}

################################################################################

try {
    $parts = @(
        (Get-DirField         $data),
        (Get-ModelField       $data),
        (Get-ContextField     $data),
        (Get-LinesField       $data),
        (Get-CostTokenField   $data),
        (Get-RateLimitField   $data),
        (Get-VersionField     $data)
    ) | Where-Object { $_ -ne $null }
    [Console]::Out.Write(($parts -join $delim))
} catch {
    $msg = ($_.Exception.Message -replace "\r?\n", " ")
    [Console]::Out.Write("${red}[Status Line Error]: ${msg}${reset}")
}
