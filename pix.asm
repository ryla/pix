    JSR detectHW        ; Find the addresses of HW we care about
    JSR setupMonitor    ; Configure and initialize the monitor
    JSR setupClock      ; Set up the clock, so mainLoop runs.


:infiniteStall
    SET PC, infiniteStall
    
                        ; Hang here, if everything is golden, we're waiting
                        ; for an interrupt from the clock

; Main loop. Triggered every 1/60s by an interrupt from the clock
:mainLoop

	ADD J,1				;Increment frame counter (J) per cycle
                        ; Send an interrupt to the keyboard
    
    MOD J,10 			;Limit J to be less than 30 to run ever						   ;y half second (1/60 cycles per second)
    
    IFE J,0				;increment which frame number
    ADD Z,1				
    MOD Z,3				;Mod for 3 frames of animation

    SET [0x8001],[thiefHead+Z] 	;Display on 0ith frame defined by literal
    SET [0x8020], [leftBody+Z]		;Display on one row down 
    SET [0x8021], [rightBody+Z]
    SET [0x8022], [pixel+Z]
    
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
    SET B, 0x8000  ; Set the start of the monitor's VRAM mapping
    HWI [monitorHWaddr] ; Send settings to monitor. The monitor will still
                        ; respond to interrupts while it's powering on
    SET A, 1            ; Put monitor into set font mode
    SET B, monitorFont  ; Set the start of the monitor's font map
    HWI [monitorHWaddr] ; Send settings to monitor
    SET A, 2            ; Put the monitor into set palette mode
    SET B, monitorPalette
                        ; Set the start of the monitor's font map
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

; Definitions for the monitor's color palette
:monitorPalette
    ; Used...
        ; at (2,1) as bg color
        ; at (5,1) as bg color
        ; at (8,1) as bg color
    DAT 0x0000
    ; Used...
        ; at (0,0) as fg color
        ; at (0,1) as fg color
        ; at (1,0) as fg color
        ; at (1,1) as fg color
        ; at (2,0) as fg color
        ; at (2,1) as fg color
        ; at (3,0) as fg color
        ; at (3,1) as fg color
        ; at (4,0) as fg color
        ; at (4,1) as fg color
        ; at (5,0) as fg color
        ; at (5,1) as fg color
        ; at (6,0) as fg color
        ; at (6,1) as fg color
        ; at (7,0) as fg color
        ; at (7,1) as fg color
        ; at (8,0) as fg color
        ; at (8,1) as fg color
    DAT 0x0777
    ; Used...
        ; at (0,1) as bg color
        ; at (1,0) as bg color
        ; at (1,1) as bg color
        ; at (3,1) as bg color
        ; at (4,0) as bg color
        ; at (4,1) as bg color
        ; at (6,1) as bg color
        ; at (7,0) as bg color
        ; at (7,1) as bg color
    DAT 0x0f00


; Definitions for the monitor's font
:monitorFont
    ; Font Char 0
    ; Used...
        ; at (6,1)
    ;       ;
    ;      *;
    ;       ;
    ;       ;
    ;       ;
    ;      *;
    ;      *;
    ;      *;
    DAT 0x0000, 0x00e2
    ; Font Char 1
    ; Used...
        ; at (3,1)
    ;       ;
    ;      *;
    ;    *  ;
    ;      *;
    ;       ;
    ;      *;
    ;      *;
    ;    * *;
    DAT 0x0000, 0x84ea
    ; Font Char 2
    ; Used...
        ; at (2,1)
        ; at (8,1)
    ;*      ;
    ;       ;
    ;       ;
    ;       ;
    ;       ;
    ;       ;
    ;       ;
    ;       ;
    DAT 0x0100, 0x0000
    ; Font Char 3
    ; Used...
        ; at (1,1)
    ;*      ;
    ;* * * *;
    ;*      ;
    ;*      ;
    ;* *    ;
    ;* *    ;
    ;  *    ;
    ;    *  ;
    DAT 0x3f72, 0x8202
    ; Font Char 4
    ; Used...
        ; at (0,0)
        ; at (2,0)
        ; at (3,0)
        ; at (5,0)
        ; at (6,0)
        ; at (8,0)
    ;       ;
    ;       ;
    ;       ;
    ;       ;
    ;       ;
    ;       ;
    ;       ;
    ;       ;
    DAT 0x0000, 0x0000
    ; Font Char 5
    ; Used...
        ; at (0,1)
    ;       ;
    ;      *;
    ;    *  ;
    ;    *  ;
    ;       ;
    ;       ;
    ;      *;
    ;    *  ;
    DAT 0x0000, 0x8c42
    ; Font Char 6
    ; Used...
        ; at (5,1)
    ;       ;
    ;       ;
    ;*      ;
    ;       ;
    ;       ;
    ;       ;
    ;       ;
    ;       ;
    DAT 0x0400, 0x0000
    ; Font Char 7
    ; Used...
        ; at (4,0)
    ;       ;
    ;       ;
    ;       ;
    ;       ;
    ;       ;
    ;       ;
    ;* *    ;
    ;    *  ;
    DAT 0x4040, 0x8000
    ; Font Char 8
    ; Used...
        ; at (4,1)
    ;* *    ;
    ;*      ;
    ;* *    ;
    ;*   * *;
    ;*      ;
    ;*      ;
    ;  *    ;
    ;  *    ;
    DAT 0x3fc5, 0x0808
    ; Font Char 9
    ; Used...
        ; at (7,1)
    ;*      ;
    ;* *   *;
    ;*   *  ;
    ;* *    ;
    ;*      ;
    ;*      ;
    ;  *    ;
    ;  *    ;
    DAT 0x3fca, 0x0402
    ; Font Char 10
    ; Used...
        ; at (1,0)
        ; at (7,0)
    ;* * * *;
    ;* * * *;
    ;* * * *;
    ;* * * *;
    ;* * * *;
    ;    * *;
    ;* *   *;
    ;    * *;
    DAT 0x5f5f, 0xbfff


:thiefHead
	DAT 0x010A
    DAT 0x1007
    DAT 0x010A
    
:leftBody
	DAT 0x1005
    DAT 0x1001
    DAT 0x1000
    
:rightBody
	DAT 0x1003
    DAT 0x1008
    DAT 0x1009
    
    
:pixel
	DAT 0x2002
    DAT 0x2006
    DAT 0x2002


            
