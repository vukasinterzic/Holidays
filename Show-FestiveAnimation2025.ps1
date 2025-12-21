
<#
.SYNOPSIS
Displays a festive terminal animation with a Christmas tree, ornaments, falling snow, and a scrolling greeting.

.DESCRIPTION
Runs an interactive console loop that centers an ASCII/emoji tree, animates a star, spawns and drifts snowflakes, and scrolls a colorful holiday message.

.EXAMPLE
pwsh -File Show-FestiveAnimation.ps1

.NOTES
Stop with Ctrl+C. Works best in a true terminal (not the PowerShell ISE) with emoji support.

Version: 1.0.0 - Initial release
Last Updated: 2025-12-20
Author: Vukasin Terzic (https://github.com/vukasinterzic)

#>

# Christmas Tree Terminal Animation + Falling Snow (PowerShell)
# Stop: Ctrl+C

$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::CursorVisible = $false } catch {}
try { $Host.UI.RawUI.WindowTitle = "🎄 Merry Christmas 🎄" } catch {}

$ornamentColors = @(
  [ConsoleColor]::Red, [ConsoleColor]::Yellow, [ConsoleColor]::Cyan,
  [ConsoleColor]::Magenta, [ConsoleColor]::Blue, [ConsoleColor]::White
)

$treeColor  = [ConsoleColor]::Green
$trunkColor = [ConsoleColor]::DarkYellow

$treeLines = @(
'               *                 ',
'              ***                ',
'             *****               ',
'            *******              ',
'           *********             ',
'          ***********            ',
'         *************           ',
'        ***************          ',
'       *****************         ',
'      *******************        ',
'     *********************       ',
'    ***********************      ',
'   *************************     ',
'  ***************************    ',
' *****************************   ',
'*******************************  ',
'              |||                ',
'        🎁🎁🎁  |||   🎁🎁          '
)

$trunkStart = $treeLines.Count - 2

$message   = "  Merry Christmas and a Happy New Year!  "
$scrollPad = " " * 10
$scrollText = $scrollPad + $message + $scrollPad
$scrollIndex = 0

function Get-SafeWidth  { try { [Console]::WindowWidth }  catch { 80 } }
function Get-SafeHeight { try { [Console]::WindowHeight } catch { 24 } }

function Get-ClippedLine([string]$s, [int]$w) {
  if ($w -le 1) { return "" }
  if ($s.Length -gt ($w - 1)) { return $s.Substring(0, $w - 1) }
  return $s
}

# Snow state
$snowflakes = New-Object System.Collections.Generic.List[object]
$snowChars  = @('.', '*', '❄')
$maxFlakesPerWidth = 0.18

$frame = 0

while ($true) {
  $width  = Get-SafeWidth
  $height = Get-SafeHeight

  $msgRow = $treeLines.Count + 1
  if ($msgRow -ge $height) { $msgRow = $height - 1 }

  # ---- Update snow ----
  $targetCount = [int]([Math]::Max(5, ($width * $maxFlakesPerWidth)))
  $spawnChance = [Math]::Min(40, [Math]::Max(10, 25 + ($targetCount - $snowflakes.Count)))
  if ((Get-Random -Minimum 0 -Maximum 100) -lt $spawnChance) {
    $toAdd = [Math]::Min(3, [Math]::Max(1, [int]($width / 60)))
    for ($a=0; $a -lt $toAdd; $a++) {
      $x = Get-Random -Minimum 0 -Maximum ([Math]::Max(1, $width-1))
      $ch = $snowChars[(Get-Random -Minimum 0 -Maximum $snowChars.Count)]
      $col = if ($ch -eq '❄') { [ConsoleColor]::White } else { [ConsoleColor]::Gray }
      $snowflakes.Add([pscustomobject]@{ X=$x; Y=0; Ch=$ch; Col=$col })
    }
  }

  for ($i = $snowflakes.Count - 1; $i -ge 0; $i--) {
    $f = $snowflakes[$i]
    if ((Get-Random -Minimum 0 -Maximum 100) -lt 30) {
      $dx = (Get-Random -Minimum -1 -Maximum 2)
      $f.X = [Math]::Max(0, [Math]::Min($width-1, $f.X + $dx))
    }
    $f.Y += 1
    if ($f.Y -ge $height - 1 -or $f.Y -eq $msgRow) {
      $snowflakes.RemoveAt($i)
    } else {
      $snowflakes[$i] = $f
    }
  }

  [Console]::SetCursorPosition(0,0)
  Clear-Host

  $snowMap = @{}
  foreach ($f in $snowflakes) {
    $snowMap["$($f.X),$($f.Y)"] = $f
  }

  # ---- Render tree (CENTERED) ----
  for ($row = 0; $row -lt $treeLines.Count; $row++) {

    $line = $treeLines[$row]
    $pad  = [Math]::Max(0, [int](($width - $line.Length) / 2)) # <-- CENTERING

    # left padding (with snow support)
    for ($p = 0; $p -lt $pad; $p++) {
      $snowKey = "$p,$row"
      if ($snowMap.ContainsKey($snowKey)) {
        $f = $snowMap[$snowKey]
        [Console]::ForegroundColor = $f.Col
        [Console]::Write($f.Ch)
      } else {
        [Console]::Write(' ')
      }
    }

    for ($i = 0; $i -lt $line.Length; $i++) {
      $x = $pad + $i
      $snowKey = "$x,$row"

      if ($snowMap.ContainsKey($snowKey)) {
        $f = $snowMap[$snowKey]
        [Console]::ForegroundColor = $f.Col
        [Console]::Write($f.Ch)
        continue
      }

      $ch = $line[$i]

      if ($row -ge $trunkStart) {
        [Console]::ForegroundColor = $trunkColor
        [Console]::Write($ch)
        continue
      }

      <#if ($row -eq 0 -and $ch -eq '*') {
        [Console]::ForegroundColor = [ConsoleColor]::Yellow
        [Console]::Write('*')
        continue
      }#>

      if ($row -eq 0 -and $ch -eq '*') {
        $stars = @('⭐️','🌟','✨')
        [Console]::ForegroundColor = [ConsoleColor]::Yellow
        [Console]::Write($stars[$frame % $stars.Count])
        continue
      }

      if ($ch -eq '*') {
        if ((Get-Random -Minimum 0 -Maximum 100) -lt 35) {
          [Console]::ForegroundColor = $ornamentColors[(Get-Random -Minimum 0 -Maximum $ornamentColors.Count)]
          [Console]::Write('o')
        } else {
          [Console]::ForegroundColor = $treeColor
          [Console]::Write('*')
        }
      } else {
        [Console]::ForegroundColor = if ($ch -eq '|') { $trunkColor } else { $treeColor }
        [Console]::Write($ch)
      }
    }

    # RIGHT FILL so snow can show across the whole width on tree rows
    for ($col = ($pad + $line.Length); $col -lt ($width - 1); $col++) {
      $snowKey = "$col,$row"
      if ($snowMap.ContainsKey($snowKey)) {
        $f = $snowMap[$snowKey]
        [Console]::ForegroundColor = $f.Col
        [Console]::Write($f.Ch)
      } else {
        [Console]::Write(' ')
      }
    }

    [Console]::WriteLine()
  }

  # ---- Background snow ----
  for ($row = $treeLines.Count; $row -lt $height - 1; $row++) {
    if ($row -eq $msgRow) { continue }
    for ($col = 0; $col -lt ($width - 1); $col++) {
      $key = "$col,$row"
      if ($snowMap.ContainsKey($key)) {
        $f = $snowMap[$key]
        [Console]::ForegroundColor = $f.Col
        [Console]::Write($f.Ch)
      } else {
        [Console]::Write(' ')
      }
    }
    [Console]::WriteLine()
  }

  # ---- Scrolling message ----
  $visibleWidth = [Math]::Max(10, $width - 1)
  if ($scrollIndex -ge $scrollText.Length) { $scrollIndex = 0 }

  $slice = ""
  for ($k = 0; $k -lt $visibleWidth; $k++) {
    $slice += $scrollText[($scrollIndex + $k) % $scrollText.Length]
  }

  [Console]::SetCursorPosition(0, $msgRow)
  $msgColors = @([ConsoleColor]::Red,[ConsoleColor]::Green,[ConsoleColor]::Yellow,[ConsoleColor]::Cyan,[ConsoleColor]::Magenta)
  for ($m = 0; $m -lt $slice.Length; $m++) {
    [Console]::ForegroundColor = $msgColors[($m + $frame) % $msgColors.Count]
    [Console]::Write($slice[$m])
  }

  $scrollIndex++
  $frame++
  Start-Sleep -Milliseconds 90
}