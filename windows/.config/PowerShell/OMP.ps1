#Alias
Set-Alias nvim "S:\Portable\Dev\neovim\bin\nvim.exe"

Invoke-Expression (&starship init powershell)

#Terminal Icon
Import-Module -Name Terminal-Icons

#PSReadLine
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -MaximumHistoryCount 4096

$env:FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border --bind 'backward-eof:abort,ctrl-s:clear-selection' --preview 'bat --color=always {}'"
Import-Module PSFzf
#Set-PSReadLineKeyHandler -Key 'ctrl-t' -BriefDescription 'Fuzzy browse' -ScriptBlock {Invoke-FuzzyBrowse}
Set-PsFzfOption -TabExpansion -EnableFd -PSReadlineChordProvider 'Ctrl+T' -PSReadlineChordReverseHistory 'Ctrl+h' -EnableAliasFuzzyEdit
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }

#Set-PSReadLineKeyHandler -Key 'alt-c' -BriefDescription 'Fuzzy browse dirs' -ScriptBlock {Invoke-FuzzyBrowse -Directory}
#Set-PSReadLineKeyHandler -Key 'ctrl-o' -BriefDescription 'Fuzzy cmdlet' -ScriptBlock { Invoke-FuzzyGetCmdlet -FzfArgs @('--preview', 'Get-Command {} -ShowCommandInfo') }
#Set-PSReadLineKeyHandler -Key 'ctrl-shift-o' -BriefDescription 'Fuzzy any command' -ScriptBlock { Invoke-FuzzyGetCommand -FzfArgs @('--preview', '(Get-Command {}).Source') }


#Use it to switch directories
#Get-ChildItem . -Attributes Directory | Invoke-Fzf | Set-Location
# Open VS code with selected file
#Get-ChildItem . -Recurse -Attributes !Directory | Invoke-Fzf | % { code $_ }
# Use fd to get desired input to fzf and start VSCode with selected file
#fd -e md | Invoke-Fzf | % { code $_ }
#Set-PsFzfOption -EnableFd:$true

#Utilities
#Show Path
function which ($command) {
	Get-Command -Name $command -ErrorAction SilentlyContinue |
	  Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}
Function br {
  $args = $args -join ' '
  $cmd_file = New-TemporaryFile
  
  $process = Start-Process -FilePath 'S:\Portable\Dev\Broot\broot.exe' `
                           -ArgumentList "--outcmd $($cmd_file.FullName) $args" `
                           -NoNewWindow -PassThru -WorkingDirectory $PWD

  Wait-Process -InputObject $process #Faster than Start-Process -Wait
  If ($process.ExitCode -eq 0) {
    $cmd = Get-Content $cmd_file
    Remove-Item $cmd_file
    If ($cmd -ne $null) { Invoke-Expression -Command $cmd }
  } Else {
    Remove-Item $cmd_file
    Write-Host "`n" # Newline to tidy up broot unexpected termination
    Write-Error "broot.exe exited with error code $($process.ExitCode)"
  }
}
Invoke-Expression (& { (zoxide init powershell | Out-String) })
# function br() {
# 	$tmp = [System.IO.Path]::GetTempFileName()
# 	C:\Software\Broot\broot.exe --outcmd "$tmp" $args
# 	$cd = Get-Content "$tmp"
# 	Remove-Item -Force "$tmp"
# 	$dir = $cd.substring(3)
# 	if (Test-Path -PathType Container "$dir") {
# 		if ("$dir" -ne "$pwd") {
# 			Push-Location "$dir"
# 		}
# 	}
# }
$EDITOR = "nvim"  # Change to your preferred editor
