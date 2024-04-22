# Personal settings
# PowerShell 7 (pwsh)

# Set Starship prompt
# Config file is located: ~/.config/starship.toml
# Support for OSC7 (CWD detector or wezterm terminal emulator)
$prompt = ''
function Invoke-Starship-PreCommand {
    $current_location = $executionContext.SessionState.Path.CurrentLocation
    if ($current_location.Provider.Name -eq 'FileSystem') {
        $ansi_escape = [char]27
        $provider_path = $current_location.ProviderPath -replace '\\', '/'
        $env:r = [IO.Path]::GetPathRoot($provider_path)

        # OSC 7
        $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
    }
    $host.ui.Write($prompt)
}
Invoke-Expression (&starship init powershell)

# Configure PSReadLine. Does not like to be loaded from another script with dot sourcing.
# For configuration help see these resources
# https://github.com/PowerShell/PSReadLine
# https://gist.github.com/rkeithhill/3103994447fd307b68be
# And run the command Get-PSReadLineKeyHandler
# Define PSReadLine options in a hashtable
$PSReadLineOptions = @{
    EditMode = 'Vi'
    ViModeIndicator = [Microsoft.PowerShell.ViModeStyle]::Prompt
    PredictionSource = 'HistoryAndPlugin'
    PredictionViewStyle = 'ListView'
    HistoryNoDuplicates = $true
    HistorySearchCursorMovesToEnd = $true
    BellStyle = 'None'
    # Colors = @{
    #     Command = 'Magenta'
    #     ContinuationPrompt = 'DarkGray'
    #     Emphasis = 'Cyan'
    #     Error = 'Red'
    #     String = 'DarkYellow'
    #     Keyword = 'Cyan'
    #     Comment = 'DarkGreen'
    #     Operator = 'DarkRed'
    #     Variable = 'Green'
    #     Parameter = 'DarkGray'
    # }
}

# Apply PSReadLine options from the hashtable
Set-PSReadLineOption @PSReadLineOptions

# Apply the configured PSReadLine options
Set-PSReadLineOption @PSReadLineOptions

function OnViModeChange {
    if ($args[0] -eq 'Command') {
        # Set the cursor to a blinking block.
        Write-Host -NoNewline "`e[1 q"
    } else {
        # Set the cursor to a blinking line.
        Write-Host -NoNewline "`e[5 q"
    }
}
Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler $Function:OnViModeChange

# Custom key mappings
Set-PSReadLineKeyHandler -Chord Ctrl+u -Function PreviousHistory
Set-PSReadLineKeyHandler -Chord Ctrl+d -Function NextHistory
Set-PSReadLineKeyHandler -Chord × -Function DeleteEndOfBuffer

# Put parentheses around the selection or entire line and move the cursor to after the closing paren
Set-PSReadLineKeyHandler -Chord Ctrl+y `
    -BriefDescription ParenthesizeSelection `
    -LongDescription 'Put parentheses around the selection or entire line and move the cursor to after the closing parenthesis' `
    -ScriptBlock {
    param($key, $arg)

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($selectionStart -ne -1) {
        $replacement = '(' + $line.SubString($selectionStart, $selectionLength) + ')'
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $replacement)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }
}

# PSFzf mappings
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }

# Set editor environment variables
$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'

# Add my custom powershell modules to the psmodulepath
# Make sure to use PathSeparator because windows uses ';' and Linux uses ':'
$env:PSModulePath += "$([System.IO.Path]::PathSeparator)$HOME/Scripts/"

# Proxy function to load my powershell module when needed
# This function will delete itself and the proper one will be loaded
function dot {
    # Delete this proxy function
    Remove-Item function:\dot

    # Import the module
    # -Force helps to always load the latest version
    # -DisableNameChecking ignores warnings about unapproved verbs
    Import-Module "$HOME/Scripts/Dots/Dots.psd1" -Force -DisableNameChecking

    # Call the new function so the first call is not noticeably different
    dot $args
}
