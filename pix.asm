    JSR detectHW        ; Find the addresses of HW we care about
    JSR setupMonitor    ; Configure and initialize the monitor
    JSR setupClock      ; Set up the clock, so mainLoop runs.

:infiniteStall
    SET PC, infiniteStall
                        ; Hang here, if everything is golden, we're waiting
                        ; for an interrupt from the clock

; Main loop. Triggered every 1/60s by an interrup from the clock
:mainLoop
    RFI 0               ; Since mainLoop is technically an interrupt
                        ; service routine, return to where we came from

; Configures the clock to create an interrupt every 1/60 second and sets
; up the interrupt handler for it.
:setupClock
    SET A, 0            ; Put clock into set frequency mode
    SET B, 1            ; Set clock frequency to 1/60s
    HWI [clockHWaddr]   ; Send settings to the clock
    IAS mainLoop        ; Set up mainLoop as the interrupt handler
    SET A, 2            ; Put clock into set interrupt mode
    SET B, 1            ; Set clock interrupt message to 1
    HWI [clockHWaddr]   ; Send settings to the clock
    SET PC, POP         ; Return from subroutine

; Configures the monitor and the VRAM for the monitor. Note: time consuming
:setupMonitor
    SET A, 0            ; Put monitor into set VRAM mode
    SET B, monitorVRAM  ; Set the start of the monitors VRAM mapping
    HWI [monitorHWaddr] ; Send settings to monitor
    SET PC, POP         ; Return from subroutine

; Scans attached hardware and populates the (device)HWaddr memory locations
; with the address of each recognized attached device.
:detectHW
    HWN I               ; Store the number of attached devices in I
:detectHWaddrLoop       ; Loop through valid HW addresses
    SUB I, 1            ; Decrement I by 1. We do this first, because HWN
                        ; returns the total number of devices, not the
                        ; index of the last device
    HWQ I               ; Load information about device with HW address I
    SET J, 0            ; Reset J to 0, because loop
:detectHWcompLoop       ; Loop through know device IDs, looking for an ID
                        ; match
    IFE [J+detectHWdataLo], A
                        ; See if the low word of the HW ID in A matches the
                        ; Jth known device ID
    IFE [J+detectHWdataHi], B
                        ; See if the high word of HW ID in B matched the
                        ; Jth known device ID
    SET [J+clockHWaddr], I
                        ; Store the HW address of the Jth recognized device
                        ; The label is clockHWaddr because its the first
                        ; in the block
    ADD J, 3            ; Increment J by 3, becuase each block is 3 words
                        ; long
    IFL J, 9            ; Continue looping if J less than 9, as there are
                        ; 3 known devices * 3 words. Hard coded for small
    SET PC, detectHWcompLoop
                        ; Conditionally jump to start of compLoop
    IFG I, 0            ; If I is greater than 0, loop addrLoop
    SET PC, detectHWaddrLoop
                        ; Conditionally jump to start of addrLoop
    SET PC, POP         ; Return from subroutine

; Hardware IDs and addresses. Use detectHW to populate addresses
:detectHWdataLo
    DAT 0xb402          ; Low word of Generic Clock ID
:detectHWdataHi
    DAT 0x12d0          ; High word of Generic Clock ID
:clockHWaddr
    DAT 0xffff          ; To be filled with HW address of clock
    DAT 0x7406, 0x30cf  ; Generic Keyboard ID
:keyboardHWaddr
    DAT 0xffff          ; To be filled with HW address of keyboard
    DAT 0xf615, 0x7349  ; LEM1802 Monitor ID
:monitorHWaddr
    DAT 0xffff          ; To be filled with HW address of monitor

:monitorVRAM
    DAT 0               ; Monitor VRAM follows this, anything in the next
                        ; 384 words will be displayed on the monitor
