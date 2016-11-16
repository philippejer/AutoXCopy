; Script that manages an X-style secondary clipboard (select to copy, middle mouse button to paste)
; The primary clipboard (CTRL+C / CTRL+V) is saved and restored
; Note: the copying can be cancelled while dragging by right clicking (this allows to paste the secondary clipboard over selected text)

; Disable this script for programs which do not support CTRL+C / CTRL+V to copy and paste text
GroupAdd DISABLED, ahk_exe mintty.exe
GroupAdd DISABLED, ahk_exe cmd.exe
#IfWinNotActive ahk_group DISABLED

ShortWaitMs := 25
DeactivationDelayMs := 500
DragThreshold := 5
Activated := False
Cancelled := False
SavedClipboard := ""
SecondaryClipboard := ""
ClickCount := 0
ClickX := 0
ClickY := 0

; To enable debug messages (which can be inspected via DbgView)
Debug := False

Log(Message)
{
	Global Debug
	if (Debug = True)
		OutputDebug, %Message%
}

Activate()
{
	Global Activated, Cancelled, ClickCount, ClickX, ClickY
	Log("[AHK] Activate")
	if (Activated = True) {
		ClickCount := ClickCount + 1
		Return
	}
	Activated := True
	Cancelled := False
	ClickCount := 1
	MouseGetPos ClickX, ClickY
}

Deactivate()
{
	Global Activated
	Log("[AHK] Deactivate")
	if (Activated = False)
		Return
	Activated := False
}

Cancel()
{
	Global Cancelled
	Log("[AHK] Cancel")
	Deactivate()
	Cancelled := True
}

; Checks that the cursor is a "text" cursor before activating this script
; Only checked on button down (the cursor tends to change depending on the program, e.g. when double-clicking)
Check()
{
	if (A_Cursor <> "IBeam")
	{
		Log("[AHK] Not an IBeam cursor")
		Return False
	}
	return True
}

; Saves the clipboard using ClipboardAll instead of Clipboard to preserve images, etc.
SaveClipboard()
{
	Global SavedClipboard	
	SavedClipboard := ClipboardAll
	; Log("[AHK] Saved Clipboard: " + Clipboard)
}

RestoreClipboard()
{
	Global SavedClipboard
	Clipboard := SavedClipboard	
	; Log("[AHK] Restored Clipboard: " + Clipboard)
}

; Checks if the mouse has been dragged, double-clicked or shift-clicked
ShouldCopy()
{
	Global ClickCount, ClickX, ClickY, DragThreshold
	MouseGetPos MouseX, MouseY
	DeltaX := MouseX - ClickX
	DeltaY := MouseY - ClickY
	Log("[AHK] ClickCount: " + ClickCount)
	Log("[AHK] DeltaX: " + DeltaX)
	Log("[AHK] DeltaY: " + DeltaY)
	GetKeyState, ShiftState, Shift
	Log("[AHK] ShiftState: " + ShiftState)
	if ((ClickCount = 1) && (ShiftState = "U") && (DeltaX < DragThreshold) && (DeltaX > -DragThreshold) && (DeltaY < DragThreshold) && (DeltaY > -DragThreshold))
		Return False
	Return True
}

; Copies the currently selected text to the secondary clipboard, saving and restoring the primary clipboard
Copy()
{
	Global SecondaryClipboard, ShortWaitMs
	if (ShouldCopy() = False) {
		Log("[AHK] Not copying")
		Return
	}
	Log("[AHK] Copying")
	SaveClipboard()
	Clipboard := ""
	Sleep %ShortWaitMs%
	SendInput ^c
	Sleep %ShortWaitMs%
	if (Clipboard <> "") {
		SecondaryClipboard := Clipboard
		Log("[AHK] SecondaryClipboard: " + SecondaryClipboard)
	} else {
		Log("[AHK] Nothing to copy")
	}
	RestoreClipboard()
}

; Pastes the secondary clipboard under the mouse (by simulating a left click), saving and restoring the primary clipboard
; If the last activation has been cancelled (by clicking the right mouse button while pressing the left mouse button),
; no left click is generated to allow pasting over the selected text (if any)
Paste()
{
	Global SecondaryClipboard, Cancelled, ShortWaitMs
	Log("[AHK] Pasting")
	if (Cancelled = False) {
		SendInput {LButton Down}
		SendInput {LButton Up}
	}
	SaveClipboard()
	Clipboard := SecondaryClipboard
	Sleep %ShortWaitMs%
	SendInput, ^v
	Sleep %ShortWaitMs%
	RestoreClipboard()	
}

~LButton::
~+LButton::
	Log("[AHK] Left button down")
	if (Check() = False)
		Return
	Activate()	
	Return
	
~LButton Up::
~+LButton Up::
	Log("[AHK] Left button up, Activated: " + Activated)
	if (Activated = False)
		Return
	Copy()
	; Do not deactivate just yet (to handle multiple clicks)
	SetTimer, Deactivate, -%DeactivationDelayMs%
	Return	
	
OverrideMUp := False

Mbutton::
	Log("[AHK] Middle mouse button down")
	if (Check() = False) {
		SendInput {MButton Down}		
		Return
	}
	Paste()
	OverrideMUp := True
	Return
	
MButton Up::
	Log("[AHK] Middle button up")
	if (OverrideMUp = True) {
		OverrideMUp := False
		Return
	}
	; We've intercepted the button press, must also intercept the button release (otherwise there will be random glitches)
	SendInput {MButton Up}
	Return
	
OverrideRUp := False
	
RButton::
	Log("[AHK] Right button down")
	if (Activated = False) {
		SendInput {RButton Down}
		Return
	}
	Cancel()
	; We've intercepted the button press, must also intercept the button release (otherwise there will be random glitches)
	OverrideRUp := True
	Return
	
RButton Up::
	Log("[AHK] Right button up")
	if (OverrideRUp = True) {
		OverrideRUp := False
		Return
	}
	SendInput {RButton Up}
	Return
