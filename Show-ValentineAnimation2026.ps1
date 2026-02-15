<#
.SYNOPSIS
Valentine's Day terminal animation: Cupid's arrow, assembling heart, personal message, and heart rain.

.DESCRIPTION
A multi-phase Valentine's animation:
  Phase 1 – Cupid's arrow flies across the screen and bursts on impact
  Phase 2 – A large heart assembles piece by piece from scattered heart characters
  Phase 3 – Your name and message appear inside the heart with a heartbeat pulse
  Phase 4 – Falling hearts rain and scrolling love banner

.PARAMETER Name
The name to display inside the heart. You will be prompted if omitted.

.PARAMETER Message
A short love message. Defaults to "Happy Valentine's Day!"

.EXAMPLE
pwsh -File Show-SomeLove-Valentine2026.ps1

.EXAMPLE
pwsh -File Show-SomeLove-Valentine2026.ps1 -Name "Alice" -Message "I love you!"

.NOTES
Best in a wide terminal (100+ columns, 30+ rows) with a Unicode-capable font.
Stop with Ctrl+C.

Version: 1.0.0
Last Updated: 2026-02-14
Author: Vukasin Terzic (https://github.com/vukasinterzic)
#>

param(
  [string]$Name,
  [string]$Message
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# ── Config ──────────────────────────────────────────────────
$UseBeep       = $true
$HeartRainSec  = 6        # seconds of falling hearts
$AssemblyMs    = 5        # ms pause per batch during heart assembly
$TypewriterMs  = 80       # ms per character in typewriter effect
$PulseFrames   = 8        # heartbeat pulse cycles
$BannerLoops   = 2        # how many times the banner scrolls

$SparkChars = @('*','+','·','✦','✧','✶','✷')
$RainChars  = @('♥','♡','♥','♡','♥','♥','❥')

# ── Terminal size ───────────────────────────────────────────
try   { $W = [Console]::WindowWidth; $H = [Console]::WindowHeight }
catch { $W = 120; $H = 40 }

# ── Helpers ─────────────────────────────────────────────────

function Clamp([int]$v,[int]$lo,[int]$hi){
  if($v -lt $lo){ return $lo }; if($v -gt $hi){ return $hi }; $v
}

function Put {
  param([int]$x, [int]$y, [string]$text, [ConsoleColor]$fg)
  $x = Clamp $x 0 ($W-1)
  $y = Clamp $y 0 ($H-1)
  [Console]::SetCursorPosition($x,$y)
  if($PSBoundParameters.ContainsKey('fg')){
    $prev = [Console]::ForegroundColor
    [Console]::ForegroundColor = $fg
    [Console]::Write($text)
    [Console]::ForegroundColor = $prev
  } else {
    [Console]::Write($text)
  }
}

function Clear-Canvas { [Console]::Clear(); [Console]::CursorVisible = $false }

function CenterX([string]$s){ [Math]::Max(0,[int](($W - $s.Length)/2)) }

function Beep-Safe([int]$freq=800,[int]$ms=60){
  if(-not $UseBeep){ return }
  try { [Console]::Beep($freq,$ms) } catch {}
}

# ── Prompt for input ────────────────────────────────────────

if(-not $Name){
  [Console]::Clear()
  [Console]::CursorVisible = $true
  Write-Host ""
  Write-Host "  Valentine's Day Animation" -ForegroundColor Red
  Write-Host ""
  $Name = Read-Host "  Enter a name (or press Enter for 'My Love')"
  if([string]::IsNullOrWhiteSpace($Name)){ $Name = "My Love" }
}
if(-not $Message){
  $Message = Read-Host "  Enter a short message (or press Enter for default)"
  if([string]::IsNullOrWhiteSpace($Message)){ $Message = "Happy Valentine's Day!" }
}

try { $Host.UI.RawUI.WindowTitle = "Valentine's Day - $Name" } catch {}
Start-Sleep -Milliseconds 400

# ── Build heart geometry ────────────────────────────────────
# Implicit heart curve: (x² + y² - 1)³ - x² y³ <= 0

$heartH = [Math]::Min(22, $H - 8)
$heartW = [Math]::Min($heartH * 2 + 6, $W - 10)

$heartCells = [System.Collections.Generic.List[pscustomobject]]::new()

for($r = 0; $r -lt $heartH; $r++){
  for($c = 0; $c -lt $heartW; $c++){
    $nx = ($c - $heartW / 2.0) / ($heartW / 2.0) * 1.3
    $ny = 1.15 - ($r / [double]$heartH) * 2.45
    $val = [Math]::Pow($nx*$nx + $ny*$ny - 1, 3) - $nx*$nx * $ny*$ny*$ny
    if($val -le 0.0){
      $heartCells.Add([pscustomobject]@{ C = $c; R = $r })
    }
  }
}

if($heartCells.Count -lt 20){
  Write-Host "`n  Terminal may be too small for the full animation." -ForegroundColor Yellow
  Write-Host "  Resize to at least 60 columns x 24 rows for best results.`n" -ForegroundColor Yellow
}

# Screen offsets to center the heart
$offX = [int](($W - $heartW) / 2)
$offY = [int](($H - $heartH) / 2) - 1

# Sort heart cells by distance from center (radial outward assembly from arrow impact)
$centerC = [int]($heartW / 2)
$centerR = [int]($heartH / 2)
$sortedByDist = @($heartCells | Sort-Object {
  $dx = $_.C - $centerC; $dy = $_.R - $centerR
  [Math]::Sqrt($dx*$dx + $dy*$dy) + (Get-Random -Minimum 0.0 -Maximum 2.5)
})

# Row-indexed data for fast full-heart redraws (pulse effect)
$heartRowData = @{}
foreach($cell in $heartCells){
  if(-not $heartRowData.ContainsKey($cell.R)){
    $heartRowData[$cell.R] = [System.Collections.Generic.List[int]]::new()
  }
  $heartRowData[$cell.R].Add($cell.C)
}

# Pre-build row strings: heart char at filled positions, space in gaps
$heartRowStrings = @{}
foreach($r in $heartRowData.Keys){
  $cols = $heartRowData[$r] | Sort-Object
  $minC = $cols[0]; $maxC = $cols[-1]
  $buf  = [char[]]::new($maxC - $minC + 1)
  for($i = 0; $i -lt $buf.Length; $i++){ $buf[$i] = ' ' }
  foreach($c in $cols){ $buf[$c - $minC] = [char]0x2665 }   # ♥
  $heartRowStrings[$r] = @{ MinC = $minC; Text = [string]::new($buf) }
}

# Pre-build hearts at 2 scales for the heartbeat animation (normal / big)
$beatScaleValues = @(1.0, 1.22)
$beatHeartsArr   = [object[]]::new(2)
$maxBeatH = 0; $maxBeatW = 0

for($si = 0; $si -lt $beatScaleValues.Count; $si++){
  $scale = $beatScaleValues[$si]
  $sH = [Math]::Max(8, [int]($heartH * $scale))
  $sW = [Math]::Max(14, [int]($heartW * $scale))
  if($sH -gt $maxBeatH){ $maxBeatH = $sH }
  if($sW -gt $maxBeatW){ $maxBeatW = $sW }
  $sOffX = [int](($W - $sW) / 2)
  $sOffY = [int](($H - $sH) / 2) - 1
  $sRowData = @{}
  for($r = 0; $r -lt $sH; $r++){
    for($c = 0; $c -lt $sW; $c++){
      $nx = ($c - $sW / 2.0) / ($sW / 2.0) * 1.3
      $ny = 1.15 - ($r / [double]$sH) * 2.45
      $val = [Math]::Pow($nx*$nx + $ny*$ny - 1, 3) - $nx*$nx * $ny*$ny*$ny
      if($val -le 0.0){
        if(-not $sRowData.ContainsKey($r)){ $sRowData[$r] = [System.Collections.Generic.List[int]]::new() }
        $sRowData[$r].Add($c)
      }
    }
  }
  $sRowStrings = @{}
  foreach($r in $sRowData.Keys){
    $cols = $sRowData[$r] | Sort-Object
    $minC = $cols[0]; $maxC = $cols[-1]
    $buf = [char[]]::new($maxC - $minC + 1)
    for($i = 0; $i -lt $buf.Length; $i++){ $buf[$i] = ' ' }
    foreach($c in $cols){ $buf[$c - $minC] = [char]0x2665 }
    $sRowStrings[$r] = @{ MinC = $minC; Text = [string]::new($buf) }
  }
  $beatHeartsArr[$si] = @{ H = $sH; W = $sW; OffX = $sOffX; OffY = $sOffY; RowStrings = $sRowStrings }
}

# Bounding box for clearing between heartbeat frames
$clearBeatW    = $maxBeatW + 4
$clearBeatOffX = [Math]::Max(0, [int](($W - $maxBeatW) / 2) - 2)
$clearBeatOffY = [Math]::Max(0, [int](($H - $maxBeatH) / 2) - 2)
$clearBeatRows = $maxBeatH + 4

# ── Phase 1+2 – Cupid's Arrow → Heart Assembly ─────────────

function Show-ArrowAndHeart {
  Clear-Canvas
  $cy = [int]($H / 2)

  # Arrow flies to center of screen (where the heart will bloom)
  $arrowLines = @(
    '  \',
    '>>═══════════════▸',
    '  /'
  )
  $arrowH   = $arrowLines.Count
  $arrowW   = ($arrowLines | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
  $topY     = $cy - [int]($arrowH / 2)
  $endX     = [int]($W / 2)   # fly to center
  $colors   = @([ConsoleColor]::DarkRed,[ConsoleColor]::Red,[ConsoleColor]::Magenta)

  for($pos = -$arrowW; $pos -le $endX; $pos += 2){
    # Erase trailing edge of previous frame
    if($pos -gt 0){
      for($row = 0; $row -lt $arrowH; $row++){
        Put ($pos - 2) ($topY + $row) "    "
      }
    }
    # Draw arrow lines
    for($row = 0; $row -lt $arrowH; $row++){
      $line = $arrowLines[$row]
      for($i = 0; $i -lt $line.Length; $i++){
        $ax = $pos + $i
        if($ax -ge 0 -and $ax -lt $W){
          $ch = $line[$i]
          if($ch -eq ' '){ continue }
          $fc = if($row -ne 1){ [ConsoleColor]::Cyan }
                elseif($i -ge ($line.Length - 1)){ [ConsoleColor]::Red }
                elseif($i -lt 2){ [ConsoleColor]::Cyan }
                else { [ConsoleColor]::Magenta }
          Put $ax ($topY + $row) $ch.ToString() $fc
        }
      }
    }
    # Sparkle trail
    if($pos -gt 8){
      $sx = Get-Random -Minimum ([Math]::Max(0,$pos-12)) -Maximum ([Math]::Max(1,$pos-3))
      $sy = $cy + (Get-Random -Minimum -3 -Maximum 4)
      Put $sx $sy ($SparkChars | Get-Random) ($colors | Get-Random)
    }
    Start-Sleep -Milliseconds 12
    if($pos % 8 -eq 0){ Beep-Safe (400 + [Math]::Max(0,$pos) * 2) 8 }
  }

  # Impact burst at center
  Beep-Safe 1200 80
  $burstChars = @([char]0x2665,[char]0x2661,'*','+','·')
  for($burst = 0; $burst -lt 5; $burst++){
    for($j = 0; $j -lt 30; $j++){
      $bx = $endX + (Get-Random -Minimum -14 -Maximum 15)
      $by = $cy   + (Get-Random -Minimum -7  -Maximum 8)
      Put $bx $by ($burstChars | Get-Random).ToString() ($colors | Get-Random)
    }
    Start-Sleep -Milliseconds 70
  }
  Start-Sleep -Milliseconds 300

  # Clear screen and transition to heart assembly from the impact point
  Clear-Canvas

  $cellColors = @([ConsoleColor]::Red,[ConsoleColor]::DarkRed,[ConsoleColor]::Red,
                   [ConsoleColor]::Magenta,[ConsoleColor]::Red)

  $batchSize = [Math]::Max(1, [int]($sortedByDist.Count / 80))

  for($i = 0; $i -lt $sortedByDist.Count; $i += $batchSize){
    $end = [Math]::Min($i + $batchSize, $sortedByDist.Count)
    for($j = $i; $j -lt $end; $j++){
      $cell = $sortedByDist[$j]
      Put ($offX + $cell.C) ($offY + $cell.R) ([char]0x2665).ToString() ($cellColors | Get-Random)
    }
    Start-Sleep -Milliseconds $AssemblyMs
    if($i % ($batchSize * 12) -eq 0){ Beep-Safe (Get-Random -Minimum 500 -Maximum 900) 12 }
  }

  # Normalize to solid red
  foreach($r in $heartRowStrings.Keys){
    $rd = $heartRowStrings[$r]
    Put ($offX + $rd.MinC) ($offY + $r) $rd.Text ([ConsoleColor]::Red)
  }
  Start-Sleep -Milliseconds 300
}

# ── Phase 3 – Name & Message Reveal + Heartbeat Pulse ──────

function Show-NameReveal {
  $centerR = [int]($heartH / 2)

  # Prepare display strings, truncate if needed
  $maxTextW = $heartW - 8
  $nameDisp = "~ $Name ~"
  if($nameDisp.Length -gt $maxTextW){ $nameDisp = $nameDisp.Substring(0, $maxTextW) }
  $msgDisp  = $Message
  if($msgDisp.Length -gt $maxTextW){ $msgDisp = $msgDisp.Substring(0, $maxTextW) }

  $nameX = $offX + [int](($heartW - $nameDisp.Length) / 2)
  $nameY = $offY + $centerR - 1
  $msgX  = $offX + [int](($heartW - $msgDisp.Length) / 2)
  $msgY  = $offY + $centerR + 1

  # Clear rectangular area inside the heart for text
  $clearW = [Math]::Max($nameDisp.Length, $msgDisp.Length) + 4
  $clearX = $offX + [int](($heartW - $clearW) / 2)
  $blank  = ' ' * $clearW
  for($row = ($centerR - 2); $row -le ($centerR + 2); $row++){
    Put $clearX ($offY + $row) $blank
  }

  # Typewriter – name
  for($k = 0; $k -lt $nameDisp.Length; $k++){
    Put ($nameX + $k) $nameY ($nameDisp[$k].ToString()) ([ConsoleColor]::White)
    Start-Sleep -Milliseconds $TypewriterMs
    Beep-Safe (700 + $k * 15) 12
  }
  Start-Sleep -Milliseconds 250

  # Typewriter – message
  for($k = 0; $k -lt $msgDisp.Length; $k++){
    Put ($msgX + $k) $msgY ($msgDisp[$k].ToString()) ([ConsoleColor]::Yellow)
    Start-Sleep -Milliseconds ([int]($TypewriterMs * 0.55))
  }
  Start-Sleep -Milliseconds 400

  # ── Heartbeat – grow bigger then back to normal ──
  # Index: 0=normal(1.0x), 1=big(1.22x)
  $beatSeq      = @(0, 1, 0, 0, 1, 0, 0, 1, 0)
  $beatTimingMs = @(120, 200, 120, 350, 200, 120, 350, 200, 120)
  $beatColorArr = @(
    [ConsoleColor]::Red,     [ConsoleColor]::Red,
    [ConsoleColor]::Red,     [ConsoleColor]::Red,
    [ConsoleColor]::Red,     [ConsoleColor]::Red,
    [ConsoleColor]::Red,     [ConsoleColor]::Red,
    [ConsoleColor]::Red
  )

  # Fixed text zone to preserve (absolute screen Y)
  $textSkipMinY = $nameY - 1
  $textSkipMaxY = $msgY + 1

  for($p = 0; $p -lt $beatSeq.Count; $p++){
    $bh     = $beatHeartsArr[$beatSeq[$p]]
    $bColor = $beatColorArr[$p]

    # Clear bounding box of the largest heart
    $blankLine = ' ' * $clearBeatW
    for($row = 0; $row -lt $clearBeatRows; $row++){
      $absY = $clearBeatOffY + $row
      if($absY -lt 0 -or $absY -ge $H){ continue }
      Put $clearBeatOffX $absY $blankLine
    }

    # Draw heart at current scale (full width on every row)
    foreach($r in $bh.RowStrings.Keys | Sort-Object){
      $absY = $bh.OffY + $r
      $rd = $bh.RowStrings[$r]
      Put ($bh.OffX + $rd.MinC) $absY $rd.Text $bColor
    }

    # Re-clear text background rectangle so text stays readable
    for($row = ($centerR - 2); $row -le ($centerR + 2); $row++){
      Put $clearX ($offY + $row) $blank
    }

    # Redraw text on top
    Put $nameX $nameY $nameDisp ([ConsoleColor]::White)
    Put $msgX  $msgY  $msgDisp  ([ConsoleColor]::Yellow)

    if($beatSeq[$p] -eq 1){ Beep-Safe 440 90 } else { Beep-Safe 220 60 }
    Start-Sleep -Milliseconds $beatTimingMs[$p]
  }

  # Final frame – restore normal-sized heart
  $blankLine = ' ' * $clearBeatW
  for($row = 0; $row -lt $clearBeatRows; $row++){
    $absY = $clearBeatOffY + $row
    if($absY -lt 0 -or $absY -ge $H){ continue }
    Put $clearBeatOffX $absY $blankLine
  }
  $normalHeart = $beatHeartsArr[1]
  foreach($r in $normalHeart.RowStrings.Keys | Sort-Object){
    $absY = $normalHeart.OffY + $r
    $rd = $normalHeart.RowStrings[$r]
    Put ($normalHeart.OffX + $rd.MinC) $absY $rd.Text ([ConsoleColor]::Red)
  }
  for($row = ($centerR - 2); $row -le ($centerR + 2); $row++){
    Put $clearX ($offY + $row) $blank
  }
  Put $nameX $nameY $nameDisp ([ConsoleColor]::White)
  Put $msgX  $msgY  $msgDisp  ([ConsoleColor]::Yellow)
  Start-Sleep -Milliseconds 700
}

# ── Phase 4 – Heart Rain with Framed Scrolling Banner ──────

function Show-HeartRainBanner {
  Clear-Canvas

  # ── Banner frame dimensions ──
  $bannerW = [Math]::Min(56, $W - 8)
  $bannerH = 5
  $bannerX = [int](($W - $bannerW) / 2)
  $bannerY = [int]($H / 2) - [int]($bannerH / 2)
  $innerW  = $bannerW - 4

  # Frame characters
  $hChar = [char]0x2550   # ═
  $vChar = [char]0x2665   # ♥
  $topBorder    = $vChar.ToString() + ([string]::new($hChar, $bannerW - 2)) + $vChar.ToString()
  $bottomBorder = $topBorder

  # Scrolling text
  $scrollText = "  $Name  ♥  $Message  ♥  "
  $padStr     = ' ' * $innerW
  $fullScroll = $padStr + $scrollText + $padStr
  $scrollIdx  = 0

  # Falling hearts state
  $rainColors = @([ConsoleColor]::Red,[ConsoleColor]::DarkRed,
                   [ConsoleColor]::Magenta,[ConsoleColor]::Red,[ConsoleColor]::DarkMagenta)
  $dropCount  = [Math]::Min(120, $W)
  $drops = for($i = 0; $i -lt $dropCount; $i++){
    [pscustomobject]@{
      X = Get-Random -Minimum 0 -Maximum $W
      Y = Get-Random -Minimum 0 -Maximum $H
      V = Get-Random -Minimum 1 -Maximum 3
      C = $RainChars  | Get-Random
      F = $rainColors | Get-Random
    }
  }

  $totalSec = $HeartRainSec + $BannerLoops * 3
  $end = (Get-Date).AddSeconds($totalSec)
  $fc  = 0

  while((Get-Date) -lt $end){
    # ── Falling hearts ──
    foreach($d in $drops){
      $inBanner = ($d.Y -ge ($bannerY - 1) -and $d.Y -le ($bannerY + $bannerH) -and
                   $d.X -ge ($bannerX - 1) -and $d.X -lt ($bannerX + $bannerW + 1))
      if(-not $inBanner){
        Put $d.X $d.Y $d.C $d.F
      }
      $d.Y += $d.V
      if($d.Y -ge $H){
        $d.Y = 0
        $d.X = Get-Random -Minimum 0 -Maximum $W
        $d.C = $RainChars  | Get-Random
        $d.F = $rainColors | Get-Random
      }
    }

    # Partial wipe (avoid banner area)
    for($i = 0; $i -lt 18; $i++){
      $wy = Get-Random -Minimum 0 -Maximum $H
      $wx = Get-Random -Minimum 0 -Maximum $W
      if($wy -ge $bannerY -and $wy -lt ($bannerY + $bannerH) -and
         $wx -ge $bannerX -and $wx -lt ($bannerX + $bannerW)){ continue }
      Put $wx $wy ' '
    }

    # ── Draw banner frame ──
    $frameColor = if($fc % 30 -lt 15){ [ConsoleColor]::Magenta } else { [ConsoleColor]::Red }
    Put $bannerX $bannerY $topBorder $frameColor
    Put $bannerX ($bannerY + $bannerH - 1) $bottomBorder $frameColor
    for($row = 1; $row -lt ($bannerH - 1); $row++){
      Put $bannerX ($bannerY + $row) "$vChar " $frameColor
      Put ($bannerX + $bannerW - 2) ($bannerY + $row) " $vChar" $frameColor
      # Clear inside on non-text rows
      if($row -ne [int]($bannerH / 2)){
        Put ($bannerX + 2) ($bannerY + $row) (' ' * $innerW)
      }
    }

    # ── Scrolling text inside frame ──
    $textY = $bannerY + [int]($bannerH / 2)
    $textX = $bannerX + 2
    $visibleSlice = ''
    for($k = 0; $k -lt $innerW; $k++){
      $visibleSlice += $fullScroll[($scrollIdx + $k) % $fullScroll.Length]
    }
    Put $textX $textY $visibleSlice ([ConsoleColor]::White)
    $scrollIdx++
    if($scrollIdx -ge $fullScroll.Length){ $scrollIdx = 0 }

    $fc++
    if($fc % 25 -eq 0){ Beep-Safe (Get-Random -Minimum 600 -Maximum 1000) 18 }
    Start-Sleep -Milliseconds 55
  }
}

# ── Main ────────────────────────────────────────────────────

try {
  [Console]::CursorVisible = $false

  Show-ArrowAndHeart
  Show-NameReveal
  Show-HeartRainBanner

  # Farewell
  Clear-Canvas
  [Console]::SetCursorPosition(0, $H - 1)
  Write-Host "Done. Happy Valentine's Day!"
}
finally {
  try { [Console]::CursorVisible = $true } catch {}
}
