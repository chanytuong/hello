param([int]$X,[int]$Y,[string]$Text,[switch]$Enter)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class FUI { [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,IntPtr p); [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow(); [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a,uint b,bool c); [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h); [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h); [DllImport("user32.dll")] public static extern void mouse_event(uint f,uint x,uint y,uint d,UIntPtr e); }'
$ft=[FUI]::GetWindowThreadProcessId([FUI]::GetForegroundWindow(),[IntPtr]::Zero)
$ct=[FUI]::GetCurrentThreadId()
$hw=(Get-Process -Id 1880).MainWindowHandle
[FUI]::AttachThreadInput($ct,$ft,$true)|Out-Null
[FUI]::BringWindowToTop($hw)|Out-Null
[FUI]::SetForegroundWindow($hw)|Out-Null
[FUI]::AttachThreadInput($ct,$ft,$false)|Out-Null
Start-Sleep -Milliseconds 150
[System.Windows.Forms.Cursor]::Position=New-Object System.Drawing.Point $X,$Y
[FUI]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
[FUI]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
if($Text){ Start-Sleep -Milliseconds 250; [System.Windows.Forms.Clipboard]::SetText($Text); [System.Windows.Forms.SendKeys]::SendWait('^a^v'); Start-Sleep -Milliseconds 300 }
if($Enter){ Start-Sleep -Milliseconds 150; [System.Windows.Forms.SendKeys]::SendWait('{ENTER}') }; Start-Sleep -Milliseconds 700
$bm=New-Object System.Drawing.Bitmap 1920,1080
$gr=[System.Drawing.Graphics]::FromImage($bm)
$gr.CopyFromScreen(0,0,0,0,$bm.Size)
$bm.Save('E:/neverlookback/docs/protagonist_rebuild_v3/phase_f_pixelorama_state.png')
$gr.Dispose()
$bm.Dispose()
