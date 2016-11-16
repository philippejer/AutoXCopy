; Script that allows an X-style copy and paste action:
;
; - Right button while left button is pressed to copy
; - Middle mouse button to paste
;
; Note: middle button to paste is only enabled with a text-mode mouse cursor to allow for example to close document tabs with the middle mouse button.

; This script should be disabled for programs which do not support CTRL+C / CTRL+V to copy and paste text
GroupAdd DISABLED, ahk_exe mintty.exe
GroupAdd DISABLED, ahk_exe cmd.exe
#IfWinNotActive ahk_group 

; To enable debug messages (which can be inspected via DbgView)
Debug := False

Log(Message)
{
	Global Debug
	if (Debug = True)
		OutputDebug, %Message%
}

; Checks that the mouse cursor is a text-mode cursor before activating this script
CheckCursor()
{
	if (A_Cursor <> "IBeam")
	{
		Log("[AHK] Not an IBeam cursor")
		Return False
	}
	return True
}
	
OverrideRUp := False
	
RButton::
	Log("[AHK] Right button down")
	GetKeyState, state, LButton
	Log("[AHK] Left button state: " + state)
	if (state = "U") {
		SendInput {RButton Down}
		Return
	}
	Log("[AHK] Copying")
	SendInput ^c
	OverrideRUp := True
	Return
	
RButton Up::
	Log("[AHK] Right button up")
	if (OverrideRUp = True) {
		; We've intercepted the button press, must also intercept the button release (otherwise there will be random glitches)
		OverrideRUp := False
		Return
	}
	SendInput {RButton Up}
	Return

OverrideMUp := False

Mbutton::
	Log("[AHK] Middle mouse button down")	
	GetKeyState, state, LButton
	Log("[AHK] Left button state: " + state)
	if (state = "D") {
		Log("[AHK] Copying")
		SendInput ^c
		OverrideMUp := True
		Return
	}
	if (CheckCursor() = False) {
		SendInput {MButton Down}
		Return
	}
	Log("[AHK] Pasting")
	SendInput {LButton Down}
	SendInput {LButton Up}
	SendInput ^v
	OverrideMUp := True
	Return
	
MButton Up::
	Log("[AHK] Middle button up")
	if (OverrideMUp = True) {
		; We've intercepted the button press, must also intercept the button release (otherwise there will be random glitches)
		OverrideMUp := False
		Return
	}
	SendInput {MButton Up}
	Return
