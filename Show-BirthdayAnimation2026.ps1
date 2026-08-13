<#
.SYNOPSIS
Birthday terminal animation: rising balloons, a candle-lit cake, big "HAPPY BIRTHDAY" text with a
personal name reveal, and a confetti finale.

.DESCRIPTION
A multi-phase birthday animation:
  Phase 1 - Balloons float up from the bottom of the screen
  Phase 2 - A birthday cake assembles and its candles light one by one, then get blown out
  Phase 3 - Big block-letter "HAPPY BIRTHDAY" banner, then your name and message reveal with a pulse
  Phase 4 - Confetti rain finale with a scrolling banner

.PARAMETER Name
The name to celebrate. You will be prompted if omitted.

.PARAMETER Message
A short birthday message. Defaults to "Wishing you a wonderful day!"

.PARAMETER Age
How many candles to put on the cake (capped at 10 for layout). Skip for a default of 5 candles.

.EXAMPLE
pwsh -File Show-BirthdayAnimation.ps1

.EXAMPLE
pwsh -File Show-BirthdayAnimation.ps1 -Name "Elizabeta" -Message "Have an amazing year!" -Age 30

.NOTES
Best in a wide terminal (100+ columns, 30+ rows) with a Unicode-capable font.
Stop with Ctrl+C.

Version: 1.0.0
Last Updated: 2026-07-27
Author: Vukasin Terzic (https://github.com/vukasinterzic)
#>

param(
  [string]$Name,
  [string]$Message,
  [int]$Age
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# ── Config ──────────────────────────────────────────────────
$UseBeep         = $true
$CandleLightMs   = 240     # pause between lighting each candle
$FlickerFrames   = 14      # shared flame flicker frames before the blow-out
$TypewriterMs    = 70      # ms per character in typewriter effect
$PulseBeats      = 8       # name pulse flashes
$ConfettiSec     = 6       # seconds of falling confetti
$BannerLoops     = 3       # how many times the banner scrolls

$ConfettiChars  = @('*','+','o','.','■','▲','◆','●')
$ConfettiColors = @([ConsoleColor]::Red,[ConsoleColor]::Yellow,[ConsoleColor]::Green,
                     [ConsoleColor]::Cyan,[ConsoleColor]::Magenta,[ConsoleColor]::White,
                     [ConsoleColor]::DarkYellow)
$Rainbow        = @([ConsoleColor]::Red,[ConsoleColor]::Yellow,[ConsoleColor]::Green,
                     [ConsoleColor]::Cyan,[ConsoleColor]::Magenta,[ConsoleColor]::White)
$BalloonColors  = @([ConsoleColor]::Red,[ConsoleColor]::Yellow,[ConsoleColor]::Cyan,
                     [ConsoleColor]::Magenta,[ConsoleColor]::Green)

# ── Terminal size ───────────────────────────────────────────
try   { $W = [Console]::WindowWidth; $H = [Console]::WindowHeight }
catch { $W = 120; $H = 40 }
if($W -le 0){ $W = 120 }
if($H -le 0){ $H = 40 }

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

# ── Block font (used for the "HAPPY" / "BIRTHDAY" banner) ──
$Font = @{
  'H' = @('██  ██','██  ██','██████','██  ██','██  ██')
  'A' = @(' ████ ','██  ██','██████','██  ██','██  ██')
  'P' = @('█████ ','██  ██','█████ ','██    ','██    ')
  'Y' = @('██  ██','██  ██',' ████ ','  ██  ','  ██  ')
  'B' = @('█████ ','██  ██','█████ ','██  ██','█████ ')
  'I' = @('████','  ██', '  ██', '  ██', '████')
  'R' = @('█████ ','██  ██','█████ ','██ ██ ','██  ██')
  'T' = @('██████','  ██  ','  ██  ','  ██  ','  ██  ')
  'D' = @('█████ ','██  ██','██  ██','██  ██','█████ ')
  ' ' = @('   ','   ','   ','   ','   ')
  '0' = @('█████ ','██  ██','██  ██','██  ██','█████ ')
  '1' = @('  ██  ',' ███  ','  ██  ','  ██  ','██████')
  '2' = @('█████ ','    ██','█████ ','██    ','██████')
  '3' = @('█████ ','    ██',' ████ ','    ██','█████ ')
  '4' = @('██  ██','██  ██','██████','    ██','    ██')
  '5' = @('██████','██    ','█████ ','    ██','█████ ')
  '6' = @('█████ ','██    ','█████ ','██  ██','█████ ')
  '7' = @('██████','    ██','   ██ ','  ██  ',' ██   ')
  '8' = @('█████ ','██  ██','█████ ','██  ██','█████ ')
  '9' = @('█████ ','██  ██','█████ ','    ██','█████ ')
}

function Get-BigTextLines([string]$text){
  $rows = @('','','','','')
  foreach($ch in $text.ToUpper().ToCharArray()){
    $key = [string]$ch
    $glyph = if($Font.ContainsKey($key)){ $Font[$key] } else { $Font[' '] }
    for($r=0; $r -lt 5; $r++){ $rows[$r] += $glyph[$r] + ' ' }
  }
  return $rows
}

function Show-BigWord([string]$word,[int]$topY){
  $glyphRows = Get-BigTextLines $word
  $offX = CenterX $glyphRows[0]
  for($r=0; $r -lt 5; $r++){
    $line = $glyphRows[$r]
    for($c=0; $c -lt $line.Length; $c++){
      $ch = $line[$c]
      if($ch -eq ' '){ continue }
      $color = $Rainbow[($c + $r) % $Rainbow.Count]
      Put ($offX + $c) ($topY + $r) $ch.ToString() $color
    }
  }
}

# ── Prompt for input ────────────────────────────────────────

if(-not $Name){
  [Console]::Clear()
  [Console]::CursorVisible = $true
  Write-Host ""
  Write-Host "  Birthday Animation" -ForegroundColor Magenta
  Write-Host ""
  $Name = Read-Host "  Enter a name"
  if([string]::IsNullOrWhiteSpace($Name)){ $Name = "Friend" }
}
if(-not $Message){
  $Message = Read-Host "  Enter a short message (or press Enter for default)"
  if([string]::IsNullOrWhiteSpace($Message)){ $Message = "Wishing you a wonderful day!" }
}
if(-not $PSBoundParameters.ContainsKey('Age')){
  $ageInput = Read-Host "  Enter age for candles (or press Enter to skip)"
  $parsedAge = 0
  if(-not [string]::IsNullOrWhiteSpace($ageInput) -and [int]::TryParse($ageInput,[ref]$parsedAge)){
    $Age = $parsedAge
  }
}

$CandleCount = if($Age -gt 0){ Clamp $Age 1 10 } else { 5 }

try { $Host.UI.RawUI.WindowTitle = "Happy Birthday - $Name" } catch {}
[Console]::CursorVisible = $false
Start-Sleep -Milliseconds 400

# ── Phase 1 - Rising Balloons ───────────────────────────────

function Show-Balloons {
  Clear-Canvas

  $balloonGlyph = @(' .-. ','(   )',' `-´ ','  |  ','  |  ')
  $glyphH = $balloonGlyph.Count
  $glyphW = $balloonGlyph[0].Length
  $count  = [Math]::Max(5, [int]($W / 16))

  $balloons = for($i = 0; $i -lt $count; $i++){
    [pscustomobject]@{
      BaseX = Get-Random -Minimum 2 -Maximum ([Math]::Max(3, $W - $glyphW - 2))
      Y     = $H + (Get-Random -Minimum 0 -Maximum ($H / 2))
      Speed = Get-Random -Minimum 1 -Maximum 3
      Phase = Get-Random -Minimum 0.0 -Maximum 6.28
      Color = $BalloonColors | Get-Random
    }
  }

  $frames = $H + [int]($H / 2) + $glyphH
  for($f = 0; $f -lt $frames; $f++){
    foreach($b in $balloons){
      $prevX = $b.BaseX + [int]([Math]::Sin(($b.Y * 0.15) + $b.Phase) * 3)
      # Erase previous glyph position
      for($row = 0; $row -lt $glyphH; $row++){
        $y = $b.Y + $row
        if($y -ge 0 -and $y -lt $H){ Put $prevX $y (' ' * $glyphW) }
      }
      $b.Y -= $b.Speed
      if($b.Y + $glyphH -lt 0){
        $b.Y = $H + (Get-Random -Minimum 0 -Maximum 6)
        $b.BaseX = Get-Random -Minimum 2 -Maximum ([Math]::Max(3, $W - $glyphW - 2))
        $b.Phase = Get-Random -Minimum 0.0 -Maximum 6.28
        $b.Color = $BalloonColors | Get-Random
      }
      $x = $b.BaseX + [int]([Math]::Sin(($b.Y * 0.15) + $b.Phase) * 3)
      for($row = 0; $row -lt $glyphH; $row++){
        $y = $b.Y + $row
        if($y -ge 0 -and $y -lt $H){ Put $x $y $balloonGlyph[$row] $b.Color }
      }
    }
    if($f % 10 -eq 0){ Beep-Safe (Get-Random -Minimum 500 -Maximum 900) 15 }
    Start-Sleep -Milliseconds 45
  }
  Start-Sleep -Milliseconds 200
}

# ── Phase 2 - Cake Assembly + Candles ───────────────────────

function Show-CakeAndCandles {
  Clear-Canvas

  $topTier = @(
    ' ▄▄▄▄▄▄▄▄▄▄▄▄ ',
    '█▓▓▓▓▓▓▓▓▓▓▓▓█',
    '█▓▓▓▓▓▓▓▓▓▓▓▓█'
  )

  # Render the age as big block digits on the cake face when provided
  $ageStr   = if($Age -gt 0){ $Age.ToString() } else { $null }
  $numLines = if($ageStr){ Get-BigTextLines $ageStr } else { $null }
  $numWidth = if($numLines){ $numLines[0].Length } else { 0 }

  $bottomW     = if($numLines){ [Math]::Max(22, $numWidth + 6) } else { 22 }
  $bodyRowCnt  = if($numLines){ 5 } else { 3 }
  $bottomTier  = @(' ' + ('▄' * ($bottomW - 2)) + ' ') +
                 (1..$bodyRowCnt | ForEach-Object { '█' + ('▓' * ($bottomW - 2)) + '█' }) +
                 @('▀' * $bottomW)

  $topW    = $topTier[0].Length
  $cakeH   = 2 + $topTier.Count + $bottomTier.Count   # +2 rows reserved for candles

  $offCakeX    = [int](($W - $bottomW) / 2)
  $topOffX     = $offCakeX + [int](($bottomW - $topW) / 2)
  $offCakeY    = [int](($H - $cakeH) / 2)
  $topY        = $offCakeY + 2
  $bottomY     = $topY + $topTier.Count

  $tierColors = @([ConsoleColor]::Yellow, [ConsoleColor]::White)
  $stickColors = @([ConsoleColor]::Cyan,[ConsoleColor]::Magenta,[ConsoleColor]::Green,
                    [ConsoleColor]::Red,[ConsoleColor]::Yellow)

  # Build cake bottom-to-top for a "rising into view" reveal
  for($r = $bottomTier.Count - 1; $r -ge 0; $r--){
    Put $offCakeX ($bottomY + $r) $bottomTier[$r] ($tierColors | Get-Random)
    Start-Sleep -Milliseconds 60
    Beep-Safe 350 10
  }

  # Engrave the age as big digits on the cake face
  if($numLines){
    $numOffX = $offCakeX + [int](($bottomW - $numWidth) / 2)
    $numOffY = $bottomY + 1
    for($r = 0; $r -lt $numLines.Count; $r++){
      $line = $numLines[$r]
      for($c = 0; $c -lt $line.Length; $c++){
        $ch = $line[$c]
        if($ch -eq ' '){ continue }
        Put ($numOffX + $c) ($numOffY + $r) $ch.ToString() ([ConsoleColor]::Red)
      }
    }
    Beep-Safe 650 90
    Start-Sleep -Milliseconds 300
  }

  for($r = $topTier.Count - 1; $r -ge 0; $r--){
    Put $topOffX ($topY + $r) $topTier[$r] ($tierColors | Get-Random)
    Start-Sleep -Milliseconds 60
    Beep-Safe 450 10
  }

  # Candle positions spread across the top tier's inner width
  $innerStart = 1
  $innerWidth = $topW - 2
  $candleX = for($i = 0; $i -lt $CandleCount; $i++){
    if($CandleCount -eq 1){ $topOffX + $innerStart + [int]($innerWidth / 2) }
    else { $topOffX + $innerStart + [int]($i * ($innerWidth - 1) / ($CandleCount - 1)) }
  }
  $stickY = $topY - 1
  $flameY = $topY - 2

  # Draw unlit candle sticks
  for($i = 0; $i -lt $CandleCount; $i++){
    Put $candleX[$i] $stickY '|' $stickColors[$i % $stickColors.Count]
  }
  Start-Sleep -Milliseconds 300

  # Light candles one by one
  $flameChars  = @('▲','^','n')
  $flameColors = @([ConsoleColor]::Yellow,[ConsoleColor]::Red,[ConsoleColor]::DarkYellow)
  for($i = 0; $i -lt $CandleCount; $i++){
    Put $candleX[$i] $flameY ($flameChars | Get-Random) ($flameColors | Get-Random)
    Beep-Safe (900 + $i * 30) 40
    Start-Sleep -Milliseconds $CandleLightMs
  }

  # Flicker all candles together
  for($f = 0; $f -lt $FlickerFrames; $f++){
    for($i = 0; $i -lt $CandleCount; $i++){
      Put $candleX[$i] $flameY ($flameChars | Get-Random) ($flameColors | Get-Random)
    }
    Start-Sleep -Milliseconds 90
  }

  Write-Host ""
  $wishY = $offCakeY - 2
  if($wishY -ge 0){
    $wishText = "Make a wish, $Name!"
    Put (CenterX $wishText) $wishY $wishText ([ConsoleColor]::White)
  }
  Start-Sleep -Milliseconds 900
  Beep-Safe 1000 100

  # Blow out - puff of smoke, then dark wicks
  $smokeChars  = @('~','·','.')
  for($p = 0; $p -lt 3; $p++){
    for($i = 0; $i -lt $CandleCount; $i++){
      Put $candleX[$i] ($flameY - $p) ($smokeChars | Get-Random) ([ConsoleColor]::DarkGray)
    }
    if($p -gt 0){
      for($i = 0; $i -lt $CandleCount; $i++){ Put $candleX[$i] ($flameY - $p + 1) ' ' }
    }
    Start-Sleep -Milliseconds 120
  }
  for($i = 0; $i -lt $CandleCount; $i++){ Put $candleX[$i] ($flameY - 2) ' ' }
  Beep-Safe 220 120
  Start-Sleep -Milliseconds 600
}

# ── Phase 3 - Big Title + Name/Message Reveal ───────────────

function Show-TitleAndName {
  Clear-Canvas

  $line1 = Get-BigTextLines 'HAPPY'
  $line2 = Get-BigTextLines 'BIRTHDAY'
  $blockH = 5
  $gap = 1
  $totalH = $blockH * 2 + $gap
  $startY = [Math]::Max(0, [int](($H - $totalH) / 2) - 4)

  Show-BigWord 'HAPPY' $startY
  Start-Sleep -Milliseconds 250
  Beep-Safe 700 100
  Show-BigWord 'BIRTHDAY' ($startY + $blockH + $gap)
  Start-Sleep -Milliseconds 250
  Beep-Safe 900 120

  # A few sparkles around the title
  $sparkChars = @('*','+','·','✦','✧')
  for($s = 0; $s -lt 20; $s++){
    $sx = Get-Random -Minimum 0 -Maximum $W
    $sy = Get-Random -Minimum $startY -Maximum ($startY + $totalH + 2)
    Put $sx $sy ($sparkChars | Get-Random) ($Rainbow | Get-Random)
    Start-Sleep -Milliseconds 15
  }

  $nameY = $startY + $totalH + 3
  $msgY  = $nameY + 2

  $nameDisp = "~ $Name ~"
  $msgDisp  = $Message
  $nameX = CenterX $nameDisp
  $msgX  = CenterX $msgDisp

  # Typewriter - name
  for($k = 0; $k -lt $nameDisp.Length; $k++){
    Put ($nameX + $k) $nameY ($nameDisp[$k].ToString()) ([ConsoleColor]::White)
    Start-Sleep -Milliseconds $TypewriterMs
    Beep-Safe (700 + $k * 15) 12
  }
  Start-Sleep -Milliseconds 250

  # Typewriter - message
  for($k = 0; $k -lt $msgDisp.Length; $k++){
    Put ($msgX + $k) $msgY ($msgDisp[$k].ToString()) ([ConsoleColor]::Yellow)
    Start-Sleep -Milliseconds ([int]($TypewriterMs * 0.55))
  }
  Start-Sleep -Milliseconds 300

  # Pulse the name a few times
  $pulseColors = @([ConsoleColor]::White,[ConsoleColor]::Yellow)
  for($p = 0; $p -lt $PulseBeats; $p++){
    Put $nameX $nameY $nameDisp $pulseColors[$p % 2]
    $beepFreq = if($p % 2 -eq 0){ 500 } else { 750 }
    Beep-Safe $beepFreq 60
    Start-Sleep -Milliseconds 180
  }
  Put $nameX $nameY $nameDisp ([ConsoleColor]::White)
  Start-Sleep -Milliseconds 600
}

# ── Phase 4 - Confetti Rain with Scrolling Banner ───────────

function Show-ConfettiFinale {
  Clear-Canvas

  $bannerW = [Math]::Min(56, $W - 8)
  $bannerH = 5
  $bannerX = [int](($W - $bannerW) / 2)
  $bannerY = [int]($H / 2) - [int]($bannerH / 2)
  $innerW  = $bannerW - 4

  $hChar = [char]0x2550   # ═
  $vChar = '*'
  $topBorder    = $vChar + ([string]::new($hChar, $bannerW - 2)) + $vChar
  $bottomBorder = $topBorder

  $scrollText = "  $Name  *  $Message  *   "
  $totalSteps = $scrollText.Length * $BannerLoops

  $dropCount = [Math]::Min(150, $W)
  $drops = for($i = 0; $i -lt $dropCount; $i++){
    [pscustomobject]@{
      X = Get-Random -Minimum 0 -Maximum $W
      Y = Get-Random -Minimum 0 -Maximum $H
      V = Get-Random -Minimum 1 -Maximum 3
      C = $ConfettiChars  | Get-Random
      F = $ConfettiColors | Get-Random
    }
  }

  $fc = 0
  for($scrollIdx = 0; $scrollIdx -lt $totalSteps; $scrollIdx++){
    foreach($d in $drops){
      $inBanner = ($d.Y -ge ($bannerY - 1) -and $d.Y -le ($bannerY + $bannerH) -and
                   $d.X -ge ($bannerX - 1) -and $d.X -lt ($bannerX + $bannerW + 1))
      if(-not $inBanner){ Put $d.X $d.Y $d.C $d.F }
      $d.Y += $d.V
      if($d.Y -ge $H){
        $d.Y = 0
        $d.X = Get-Random -Minimum 0 -Maximum $W
        $d.C = $ConfettiChars  | Get-Random
        $d.F = $ConfettiColors | Get-Random
      }
    }

    for($i = 0; $i -lt 18; $i++){
      $wy = Get-Random -Minimum 0 -Maximum $H
      $wx = Get-Random -Minimum 0 -Maximum $W
      if($wy -ge $bannerY -and $wy -lt ($bannerY + $bannerH) -and
         $wx -ge $bannerX -and $wx -lt ($bannerX + $bannerW)){ continue }
      Put $wx $wy ' '
    }

    $frameColor = $Rainbow[[int]($fc / 5) % $Rainbow.Count]
    Put $bannerX $bannerY $topBorder $frameColor
    Put $bannerX ($bannerY + $bannerH - 1) $bottomBorder $frameColor
    for($row = 1; $row -lt ($bannerH - 1); $row++){
      Put $bannerX ($bannerY + $row) "$vChar " $frameColor
      Put ($bannerX + $bannerW - 2) ($bannerY + $row) " $vChar" $frameColor
      if($row -ne [int]($bannerH / 2)){
        Put ($bannerX + 2) ($bannerY + $row) (' ' * $innerW)
      }
    }

    $textY = $bannerY + [int]($bannerH / 2)
    $textX = $bannerX + 2
    $visibleSlice = ''
    for($k = 0; $k -lt $innerW; $k++){
      $visibleSlice += $scrollText[($scrollIdx + $k) % $scrollText.Length]
    }
    Put $textX $textY $visibleSlice ([ConsoleColor]::White)

    $fc++
    if($fc % 25 -eq 0){ Beep-Safe (Get-Random -Minimum 600 -Maximum 1000) 18 }
    Start-Sleep -Milliseconds 55
  }
}

# ── Main ────────────────────────────────────────────────────

try {
  [Console]::CursorVisible = $false

  Show-Balloons
  Show-CakeAndCandles
  Show-TitleAndName
  Show-ConfettiFinale

  # Freeze on the last confetti frame and hold it there until the user is
  # ready to move on, instead of wiping it away immediately.
  $doneText = "  Happy Birthday, $Name!  "
  $doneY = Clamp ($H - 2) 0 ($H - 1)
  Put 0 $doneY (' ' * $W)
  Put (CenterX $doneText) $doneY $doneText ([ConsoleColor]::Green)
}
catch {
  # Surface any failure instead of letting it vanish silently - a crash
  # partway through used to jump straight to a screen-clearing `finally`
  # with no message at all.
  Clear-Canvas
  [Console]::CursorVisible = $true
  Write-Host ""
  Write-Host "  The animation hit a problem and stopped early:" -ForegroundColor Red
  Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
  Write-Host "  (line $($_.InvocationInfo.ScriptLineNumber))" -ForegroundColor DarkRed
  Write-Host ""
}
finally {
  # Always pause here - on a normal finish or after an error above - so
  # nothing clears until the user explicitly says they're done looking.
  # Read-Host waits for a real Enter keypress and works reliably across
  # terminals/hosts - [Console]::ReadKey needs raw console access that not
  # every host (IDE terminals, some redirected sessions) actually provides,
  # and silently throws there instead of waiting.
  [Console]::CursorVisible = $true
  Write-Host ""
  try { Read-Host "  Press Enter to exit" | Out-Null }
  catch { Start-Sleep -Seconds 6 }
  try { [Console]::Clear() } catch {}
  try { [Console]::CursorVisible = $true } catch {}
}
