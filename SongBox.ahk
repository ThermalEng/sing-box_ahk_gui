#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn

; === 配置区 ===
baseDir := A_ScriptDir
proxyCmd := Map(
    1, '' baseDir '\sing-box.exe run -c ' baseDir '\Win_GoHome.json',
    2, '' baseDir '\sing-box.exe run -c ' baseDir '\Win_Global.json',
    3, '' baseDir '\sing-box.exe run -c ' baseDir '\Win_EasyConnect.json'
)
proxyName := Map(
    1, "回家模式",
    2, "世界模式",
    3, "工作模式"
)

global startTime := 0
global ProxyIndex := 0
global SbPid := 0

; === GUI 界面 ===
mainGui := Gui("AlwaysOnTop", "代理启动器")
mainGui.SetFont("s10")
mainGui.AddText("xm y40 w220 h40 vStatusBox Border +Center +0x200", "未运行")
mainGui.AddText("xm w220 vTimerText +Center", "运行时间：00:00:00")

btn1 := mainGui.AddButton("x240 y20 w120 h32", "启动回家模式")
btn2 := mainGui.AddButton("x240 y+10 w120 h32", "启动世界模式")
btn3 := mainGui.AddButton("x240 y+10 w120 h32", "启动工作模式")
btnStop := mainGui.AddButton("x60 y+15 w240 h32", "安全退出")

btn1.OnEvent("Click", (*) => StartProxy(1))
btn2.OnEvent("Click", (*) => StartProxy(2))
btn3.OnEvent("Click", (*) => StartProxy(3))
btnStop.OnEvent("Click", (*) => SendCtrlBreak(SbPid))

mainGui.OnEvent("Close", (*) => mainGui.Hide())
mainGui.Show()

TraySetIcon(baseDir '\singbox\pre.png',,"未运行")
TrayMenu := A_TrayMenu
TrayMenu.Delete()
TrayMenu.Add("显示窗口", (*) => mainGui.Show())
TrayMenu.Add("安全退出", (*) => SendCtrlBreak(SbPid))
;TrayMenu.Add("退出脚本", (*) => ExitApp())
; 把“显示窗口”设为默认项（双击触发）
TrayMenu.Default := "显示窗口"



SetTimer(UpdateTimer, 1000)

StartProxy(idx) {
    global startTime, ProxyIndex, SbPid, proxyName
    if startTime != 0
        return
    Run("*RunAs " proxyCmd[idx], , "Hide", &pid)
    ProxyIndex := idx
    SbPid := pid
    startTime := A_TickCount
    UpdateStatusBox()
    TrayTip("SingBox","已启动：" proxyName[idx], 1)
}

SendCtrlBreak(pid) {
    pid := ProcessExist("sing-box.exe")  ; 查找是否有 sing-box.exe 正在运行
    if (pid = 0) 
        ExitApp() 
    ; 附加到 sing-box 的进程组
    TrayTip("SingBox","安全退出：" proxyName[ProxyIndex], 1)
    DllCall("FreeConsole") 
    DllCall("AttachConsole", "UInt", pid)
    ; 发送 Ctrl+Break
    DllCall("GenerateConsoleCtrlEvent", "UInt", 0, "UInt", 0) ; 1 = CTRL_BREAK_EVENT
}


UpdateStatusBox() {
    global mainGui, proxyName, ProxyIndex, startTime
    status := (startTime>0 && ProxyIndex>0) ? "当前代理：" proxyName[ProxyIndex] : "未运行"
    if ProxyIndex == 3
        TraySetIcon(baseDir '\singbox\ready.png',,"当前模式：" proxyName[ProxyIndex] )
    else If ProxyIndex == 0
        TraySetIcon(baseDir '\singbox\pre.png',,"未运行")
    else TraySetIcon(baseDir '\singbox\ready.png',,"当前模式：" proxyName[ProxyIndex])
    mainGui["StatusBox"].Value := status
}

UpdateTimer() {
    global startTime, mainGui
    mainGui["TimerText"].Value := (startTime > 0)
        ? "运行时间：" . Format("{:02}:{:02}:{:02}"
            , (A_TickCount - startTime) // 3600000
            , Mod((A_TickCount - startTime) // 60000, 60)
            , Mod((A_TickCount - startTime) // 1000, 60))
        : "运行时间：00:00:00"
}