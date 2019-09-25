# with no parameter: looks in the current folder for a ".ok" file, and lists its commands numbered
# with a number parameter, runs the relevant command from the .ok file, e.g. "ok 1" runs first line of ".ok" file
function ok([parameter(mandatory=$false, position=0)]$number) {
      [parameter(
          mandatory=$false, 
          position=1, 
          ValueFromRemainingArguments=$true
       )]$arg
  )
  # this is a private function used by ok
  # given a filename (a file full of commands) and a number (possibly null) and some remaining parameters:
  #   invoke the numbered command (if a number was given) or display a numbered list of the commands
  function ok_file($file, $number) {
    $commands = @{};
    $num = 0;
    type $file | % {
      $line = $_.trim();
      if ($line -ne "" -and $line -ne $null) { 
        if ($line.indexOf('#') -ne 0) {
          $num = $num + 1;
          $commands.Add(("" + $num), $line);
        }
      }
    }
    if ($number -ne $null -and $num -ge 1) {
      if ($number -le $num) {
        # INVOKE the command (after pretty-printing it)
        $expression = $commands[("" + $number)];
        write-host -NoNewline "> " -foregroundcolor "magenta" # impersonate prompt...
        if ($expression.indexOf('#') -ge 0) {
          write-host -NoNewline (($expression -split '#')[0]) -foregroundcolor "white"
          write-host $expression.substring($expression.indexOf('#')) -foregroundcolor "green"
        } else {
          write-host $expression -foregroundcolor "white"
        }
        invoke-expression $expression;
      } else {
        write-host "'$number' needs to be <= $num" -foregroundcolor "red"
        ok_file $file
      }
    } else {
      # Get length of longest command/comment
      $maxCommandLength = (($commands.Values | % { ($_ -split '#')[0] } | % { $_.Length }) | Measure-Object -Maximum ).Maximum
      $maxCommentLength = (($commands.Values | % { ($_ -split '#')[1] } | % { $_.Length }) | Measure-Object -Maximum ).Maximum
      $maxCommandLength = [Math]::Min($Host.UI.RawUI.WindowSize.Width -  $maxCommentLength - 5, $maxCommandLength)
      # LIST the commands
      $num = 0;
      type $file | % {
        $command, $comment = $_.trim() -split '#' | % { $_.trim() }
        if ($command) {
          $num = $num + 1
          Write-Host -NoNewLine "$num. " -foregroundcolor "yellow"
          Write-Host -NoNewLine $command.PadRight($maxCommandLength + 1, " ") -foregroundcolor "white"
          if ($comment) { Write-Host "# $comment" -foregroundcolor "green" }
          else { Write-Host "" }
        } else {
          if ($comment) { Write-Host "# $comment" -foregroundcolor "green" }
          else { Write-Host "" }
        }
      }
    }
  }
  
  if (test-path ".\.ok") {
    ok_file ".\.ok" $number @args
  }
}

## Consider: Remove the 'cd' alias, so our function can take over...
#    if (test-path alias:cd) {
#        Remove-Item alias:cd -Force
#    }
#
## We create our `cd` function as a wrapper around set-location that calls 'ok'
#    function cd ([parameter(ValueFromRemainingArguments = $true)][string]$Passthrough) {
#        Set-Location $Passthrough
#        ok # Call 'ok'
#    }
#
## Consider: do the same for pushd and popd...?
## Consider: also check parent folders (recursively)
