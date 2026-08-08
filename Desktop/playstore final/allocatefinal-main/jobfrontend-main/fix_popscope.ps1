$file = 'lib\screens\job_seeker\job_seeker_home.dart'
$lines = Get-Content $file
# Line 289 is index 288 (0-based). Change ");  " to ")," then insert ");"
$lines[288] = '    ),'
$newLines = $lines[0..288] + '  );' + $lines[289..($lines.Length-1)]
$newLines | Set-Content $file -Encoding UTF8
Write-Host "Done. Total lines: $($newLines.Length)"
