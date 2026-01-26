<#
.SYNOPSIS
    New Year Countdown with Fireworks Animation
.DESCRIPTION
    Displays a colorful countdown to the New Year followed by an animated fireworks display
.NOTES
    Author: Vukasin Terzic
    Date: January 2026
#>

# Clear the screen
Clear-Host

# Set up Ctrl+C handler
$global:exitRequested = $false

# Trap Ctrl+C
trap {
    $global:exitRequested = $true
    try {
        [Console]::CursorVisible = $true
    } catch {}
    Clear-Host
    Write-Host "`nExiting... Goodbye! 👋" -ForegroundColor Yellow
    exit
}

# Get New Year 2026
$newYear = Get-Date -Year 2026 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0

# Function to draw colorful banner
function Show-Banner {
    param($text, $color = "Cyan")
    
    $width = 80
    $padding = [Math]::Floor(($width - $text.Length) / 2)
    
    Write-Host ("=" * $width) -ForegroundColor $color
    Write-Host (" " * $padding + $text) -ForegroundColor $color
    Write-Host ("=" * $width) -ForegroundColor $color
}

# Function to display countdown
function Show-Countdown {
    $colors = @("Red", "Yellow", "Green", "Cyan", "Magenta", "Blue", "White")
    $colorIndex = 0
    
    Show-Banner "🎊 NEW YEAR COUNTDOWN 🎊" "Yellow"
    Write-Host ""
    
    while ($true) {
        if ($global:exitRequested) { return }
        
        $timeLeft = $newYear - (Get-Date)
        
        if ($timeLeft.TotalSeconds -le 0) {
            break
        }
        
        $days = $timeLeft.Days
        $hours = $timeLeft.Hours
        $minutes = $timeLeft.Minutes
        $seconds = $timeLeft.Seconds
        
        # Clear previous countdown line
        [Console]::SetCursorPosition(0, 5)
        
        # Display countdown with rotating colors
        $color = $colors[$colorIndex % $colors.Length]
        
        Write-Host "                                                                                " -NoNewline
        [Console]::SetCursorPosition(0, 5)
        Write-Host "     " -NoNewline
        Write-Host "$days" -ForegroundColor $color -NoNewline
        Write-Host " Days  " -NoNewline
        Write-Host "$hours" -ForegroundColor $color -NoNewline
        Write-Host " Hours  " -NoNewline
        Write-Host "$minutes" -ForegroundColor $color -NoNewline
        Write-Host " Minutes  " -NoNewline
        Write-Host "$seconds" -ForegroundColor $color -NoNewline
        Write-Host " Seconds     "
        
        # Display ASCII art countdown for last 10 seconds
        if ($timeLeft.TotalSeconds -le 10 -and $timeLeft.TotalSeconds -gt 0) {
            [Console]::SetCursorPosition(0, 7)
            $num = [Math]::Ceiling($timeLeft.TotalSeconds)
            Show-BigNumber $num $colors[$colorIndex % $colors.Length]
        }
        
        $colorIndex++
        Start-Sleep -Milliseconds 100
    }
}

# Function to display big numbers
function Show-BigNumber {
    param($number, $color)
    
    $numbers = @{
        1 = @("  ██  ", " ███  ", "  ██  ", "  ██  ", "██████")
        2 = @("█████ ", "    ██", "█████ ", "██    ", "██████")
        3 = @("█████ ", "    ██", " ████ ", "    ██", "█████ ")
        4 = @("██  ██", "██  ██", "██████", "    ██", "    ██")
        5 = @("██████", "██    ", "█████ ", "    ██", "█████ ")
        6 = @("█████ ", "██    ", "█████ ", "██  ██", "█████ ")
        7 = @("██████", "    ██", "   ██ ", "  ██  ", " ██   ")
        8 = @("█████ ", "██  ██", "█████ ", "██  ██", "█████ ")
        9 = @("█████ ", "██  ██", "█████ ", "    ██", "█████ ")
        10 = @("███ ███████", " ██ ███ ███", " ██ ███ ███", " ██ ███ ███", " ██ ███████")
    }
    
    if ($numbers.ContainsKey($number)) {
        foreach ($line in $numbers[$number]) {
            Write-Host ("       " + $line) -ForegroundColor $color
        }
    }
    Write-Host ""
}

# Function to create fireworks
function Show-Fireworks {
    Clear-Host
    
    # Countdown from 10 to 1
    $colors = @("Red", "Yellow", "Green", "Cyan", "Magenta", "Blue", "White")
    
    for ($i = 10; $i -ge 1; $i--) {
        if ($global:exitRequested) { return }
        
        Clear-Host
        Write-Host "`n`n`n`n"
        Show-BigNumber $i $colors[$i % $colors.Length]
        Start-Sleep -Seconds 1
    }
    
    Clear-Host
    
    # Happy New Year 2026 message
    Write-Host ""
    Write-Host ""
    Write-Host "  ██╗  ██╗ █████╗ ██████╗ ██████╗ ██╗   ██╗    ███╗   ██╗███████╗██╗    ██╗" -ForegroundColor Yellow
    Write-Host "  ██║  ██║██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝    ████╗  ██║██╔════╝██║    ██║" -ForegroundColor Yellow
    Write-Host "  ███████║███████║██████╔╝██████╔╝ ╚████╔╝     ██╔██╗ ██║█████╗  ██║ █╗ ██║" -ForegroundColor Yellow
    Write-Host "  ██╔══██║██╔══██║██╔═══╝ ██╔═══╝   ╚██╔╝      ██║╚██╗██║██╔══╝  ██║███╗██║" -ForegroundColor Yellow
    Write-Host "  ██║  ██║██║  ██║██║     ██║        ██║       ██║ ╚████║███████╗╚███╔███╔╝" -ForegroundColor Yellow
    Write-Host "  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝        ╚═╝       ╚═╝  ╚═══╝╚══════╝ ╚══╝╚══╝ " -ForegroundColor Yellow
    Write-Host ""
    Write-Host "     ██╗   ██╗███████╗ █████╗ ██████╗     ██████╗  ██████╗ ██████╗ ███████╗ " -ForegroundColor Cyan
    Write-Host "     ╚██╗ ██╔╝██╔════╝██╔══██╗██╔══██╗    ╚════██╗██╔═████╗╚════██╗██╔════╝ " -ForegroundColor Cyan
    Write-Host "      ╚████╔╝ █████╗  ███████║██████╔╝     █████╔╝██║██╔██║ █████╔╝███████╗ " -ForegroundColor Cyan
    Write-Host "       ╚██╔╝  ██╔══╝  ██╔══██║██╔══██╗    ██╔═══╝ ████╔╝██║██╔═══╝ ██╔══██║ " -ForegroundColor Cyan
    Write-Host "        ██║   ███████╗██║  ██║██║  ██║    ███████╗╚██████╔╝███████╗███████║ " -ForegroundColor Cyan
    Write-Host "        ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝ ╚══════╝╚══════╝ " -ForegroundColor Cyan
    Write-Host ""
    
    $colors = @("Red", "Yellow", "Green", "Cyan", "Magenta", "Blue", "White", "DarkYellow", "DarkCyan", "DarkMagenta")
    $fireworkChars = @("*", "✦", "✧", "⋆", "✨", "○", "●", "◆", "◇", "★", "☆")
    
    # Run fireworks indefinitely until Ctrl+C
    while ($true) {
        if ($global:exitRequested) { return }
        
        # Launch multiple fireworks
        $numFireworks = Get-Random -Minimum 2 -Maximum 5
        
        for ($i = 0; $i -lt $numFireworks; $i++) {
            $x = Get-Random -Minimum 5 -Maximum 75
            $y = Get-Random -Minimum 16 -Maximum 25
            $color = $colors[(Get-Random -Minimum 0 -Maximum $colors.Length)]
            $char = $fireworkChars[(Get-Random -Minimum 0 -Maximum $fireworkChars.Length)]
            
            # Explosion effect
            $positions = @(
                @(0, 0),
                @(-1, -1), @(0, -1), @(1, -1),
                @(-1, 0), @(1, 0),
                @(-1, 1), @(0, 1), @(1, 1),
                @(-2, -2), @(2, -2), @(-2, 2), @(2, 2),
                @(0, -2), @(0, 2), @(-2, 0), @(2, 0)
            )
            
            foreach ($pos in $positions) {
                $px = $x + $pos[0] * 2
                $py = $y + $pos[1]
                
                if ($px -ge 0 -and $px -lt 80 -and $py -ge 15 -and $py -lt 30) {
                    try {
                        [Console]::SetCursorPosition($px, $py)
                        Write-Host $char -ForegroundColor $color -NoNewline
                    } catch {
                        # Ignore cursor position errors
                    }
                }
            }
        }
        
        Start-Sleep -Milliseconds 200
        
        # Clear some fireworks for flickering effect
        if ((Get-Random -Minimum 0 -Maximum 10) -gt 5) {
            for ($clearY = 16; $clearY -lt 26; $clearY++) {
                $clearX = Get-Random -Minimum 0 -Maximum 80
                try {
                    [Console]::SetCursorPosition($clearX, $clearY)
                    Write-Host " " -NoNewline
                } catch {
                    # Ignore cursor position errors
                }
            }
        }
    }
}

# Main execution
try {
    # Hide cursor (cross-platform compatible)
    try {
        [Console]::CursorVisible = $false
    } catch {
        # Ignore if not supported on this platform
    }
    
    # Show countdown
    Show-Countdown
    
    # Play a beep for midnight
    try {
        [Console]::Beep(800, 200)
        [Console]::Beep(1000, 200)
        [Console]::Beep(1200, 500)
    } catch {
        # Ignore if beep not supported
    }
    
    # Show fireworks
    Show-Fireworks
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    # Restore cursor
    try {
        [Console]::CursorVisible = $true
    } catch {
        # Ignore if not supported on this platform
    }
}
