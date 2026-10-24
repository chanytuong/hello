param([string]$Tag = "run")
$godot = "C:/Users/Aloha/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
$root = "E:/neverlookback"
$out = "$root/docs/run_se_integration/logs_$Tag"
New-Item -ItemType Directory -Force $out | Out-Null
$suites = "test_runtime","test_identity","test_weapon","test_feel","test_arena","test_killblink","test_strand"
$summary = @()
foreach ($s in $suites) {
  $log = "$out/$s.log"
  & $godot --headless --path $root -s "res://tests/$s.gd" *> $log
  $code = $LASTEXITCODE
  $txt = [string](Get-Content $log -Raw)
  $pass = ([regex]::Matches($txt, "(?m)^PASS")).Count
  $fail = ([regex]::Matches($txt, "(?m)^FAIL")).Count
  $err = ([regex]::Matches($txt, "(?m)(SCRIPT ERROR|Parse Error|ERROR:)")).Count
  $summary += "{0,-16} exit={1} pass={2} fail={3} errors={4}" -f $s, $code, $pass, $fail, $err
}
$summary | Tee-Object "$out/summary.txt"
