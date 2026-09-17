<#
.SYNOPSIS
    터미널 컬러 팔레트를 출력합니다.

.DESCRIPTION
    ANSI 16색(표준/밝은색), 256색 팔레트, 24비트 트루컬러 그라데이션을
    현재 터미널에 출력합니다. Windows PowerShell 5.1 / PowerShell 7+ 모두 지원하며,
    conhost(기본 콘솔)에서도 VT(가상 터미널) 처리를 자동으로 켭니다.

.PARAMETER Section
    출력할 섹션을 고릅니다. 기본값은 All.
    16, 256, True, All 중에서 선택할 수 있습니다.

.EXAMPLE
    .\Show-ColorPalette.ps1
    전체 팔레트를 출력합니다.

.EXAMPLE
    .\Show-ColorPalette.ps1 -Section 256
    256색 팔레트만 출력합니다.
#>
[CmdletBinding()]
param(
    [ValidateSet('16', '256', 'True', 'All')]
    [string]$Section = 'All'
)

$ESC   = [char]27
$RESET = "$ESC[0m"

# ---------------------------------------------------------------------------
# VT(가상 터미널) 처리 활성화 — conhost에서도 ANSI 이스케이프가 동작하게 함
# ---------------------------------------------------------------------------
function Enable-VirtualTerminal {
    try {
        if (-not ('VTConsole' -as [type])) {
            Add-Type -ErrorAction Stop -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class VTConsole {
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr GetStdHandle(int nStdHandle);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
    public static void Enable() {
        IntPtr handle = GetStdHandle(-11); // STD_OUTPUT_HANDLE
        uint mode;
        if (GetConsoleMode(handle, out mode)) {
            SetConsoleMode(handle, mode | 0x0004); // ENABLE_VIRTUAL_TERMINAL_PROCESSING
        }
    }
}
"@
        }
        [VTConsole]::Enable()
    }
    catch {
        # 콘솔 핸들이 없거나(리다이렉트 등) API 호출 실패 시 무시 — 대부분의 모던 터미널은 그대로 동작
    }
}

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "$ESC[1m$ESC[97m$Text$RESET"
    Write-Host ("$ESC[90m" + ('─' * 60) + $RESET)
}

# ---------------------------------------------------------------------------
# 1) 표준 16색 (전경 / 배경)
# ---------------------------------------------------------------------------
function Show-Ansi16 {
    Write-Header "표준 16색 (ANSI 16 colors)"

    $names = @('Black','Red','Green','Yellow','Blue','Magenta','Cyan','White')

    Write-Host "  전경색 (Foreground)"
    foreach ($row in @(@{label='기본 '; base=30}, @{label='밝게 '; base=90})) {
        $line = "    " + $row.label
        for ($i = 0; $i -lt 8; $i++) {
            $code = $row.base + $i
            $line += "$ESC[${code}m" + ('{0,-9}' -f $names[$i]) + $RESET
        }
        Write-Host $line
    }

    Write-Host ""
    Write-Host "  배경색 (Background)"
    foreach ($row in @(@{label='기본 '; base=40}, @{label='밝게 '; base=100})) {
        $line = "    " + $row.label
        for ($i = 0; $i -lt 8; $i++) {
            $code = $row.base + $i
            # 어두운 배경 위 텍스트는 흰색, 밝은 배경 위 텍스트는 검은색으로 가독성 확보
            $fg = if ($i -le 0) { 97 } else { 30 }
            $line += "$ESC[${code}m$ESC[${fg}m" + (' {0,-3} ' -f $code) + $RESET
        }
        Write-Host $line
    }
}

# ---------------------------------------------------------------------------
# 2) 256색 팔레트
# ---------------------------------------------------------------------------
function Show-Ansi256 {
    Write-Header "256색 팔레트 (256 colors)"

    $sw = { param($n) "$ESC[48;5;${n}m" + ('{0,4}' -f $n) + $RESET }

    # 0-15: 시스템 컬러
    Write-Host "  시스템 (0-15)"
    $line = "    "
    for ($i = 0; $i -le 15; $i++) {
        $line += & $sw $i
        if (($i + 1) % 8 -eq 0) { Write-Host $line; $line = "    " }
    }

    # 16-231: 6x6x6 컬러 큐브
    Write-Host ""
    Write-Host "  컬러 큐브 (16-231)"
    for ($i = 16; $i -le 231; $i++) {
        if (($i - 16) % 36 -eq 0) { Write-Host -NoNewline "`n    " }
        Write-Host -NoNewline (& $sw $i)
    }
    Write-Host ""

    # 232-255: 그레이스케일
    Write-Host ""
    Write-Host "  그레이스케일 (232-255)"
    $line = "    "
    for ($i = 232; $i -le 255; $i++) {
        $line += & $sw $i
        if (($i - 231) % 12 -eq 0) { Write-Host $line; $line = "    " }
    }
    if ($line.Trim()) { Write-Host $line }
}

# ---------------------------------------------------------------------------
# 3) 24비트 트루컬러 그라데이션
# ---------------------------------------------------------------------------
function Show-TrueColor {
    Write-Header "24비트 트루컬러 (TrueColor gradient)"

    $width = 60

    # 무지개(HSV 색상환) 그라데이션
    $line = "    "
    for ($x = 0; $x -lt $width; $x++) {
        $h = ($x / $width) * 360.0
        $rgb = ConvertFrom-Hsv -H $h -S 1.0 -V 1.0
        $line += "$ESC[48;2;$($rgb.R);$($rgb.G);$($rgb.B)m "
    }
    Write-Host ($line + $RESET)

    # 빨강/초록/파랑 채널별 그라데이션
    foreach ($channel in 'Red', 'Green', 'Blue') {
        $line = "    "
        for ($x = 0; $x -lt $width; $x++) {
            $v = [int](($x / ($width - 1)) * 255)
            switch ($channel) {
                'Red'   { $r, $g, $b = $v, 0, 0 }
                'Green' { $r, $g, $b = 0, $v, 0 }
                'Blue'  { $r, $g, $b = 0, 0, $v }
            }
            $line += "$ESC[48;2;$r;$g;${b}m "
        }
        Write-Host ($line + $RESET)
    }

    # 회색조 그라데이션
    $line = "    "
    for ($x = 0; $x -lt $width; $x++) {
        $v = [int](($x / ($width - 1)) * 255)
        $line += "$ESC[48;2;$v;$v;${v}m "
    }
    Write-Host ($line + $RESET)
}

# HSV → RGB 변환 (H: 0-360, S/V: 0-1)
function ConvertFrom-Hsv {
    param([double]$H, [double]$S, [double]$V)
    $c = $V * $S
    $x = $c * (1 - [math]::Abs((($H / 60.0) % 2) - 1))
    $m = $V - $c
    switch ([math]::Floor($H / 60.0) % 6) {
        0 { $r,$g,$b = $c,$x,0 }
        1 { $r,$g,$b = $x,$c,0 }
        2 { $r,$g,$b = 0,$c,$x }
        3 { $r,$g,$b = 0,$x,$c }
        4 { $r,$g,$b = $x,0,$c }
        5 { $r,$g,$b = $c,0,$x }
    }
    [pscustomobject]@{
        R = [int](($r + $m) * 255)
        G = [int](($g + $m) * 255)
        B = [int](($b + $m) * 255)
    }
}

# ---------------------------------------------------------------------------
# 실행
# ---------------------------------------------------------------------------
Enable-VirtualTerminal

if ($Section -in @('16',  'All')) { Show-Ansi16 }
if ($Section -in @('256', 'All')) { Show-Ansi256 }
if ($Section -in @('True','All')) { Show-TrueColor }

Write-Host ""
