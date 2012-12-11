    JSR detectHW        ; Find the addresses of HW we care about
    JSR setupMonitor    ; Configure and initialize the monitor
    
    JSR splashScreen            ;jump to initial splash screen (all black)
   
    JSR setupClock      ; Set up the clock, so mainLoop runs.

 
:infiniteStall
    SET PC, infiniteStall
    
                        ; Hang here, if everything is golden, we're waiting
                        ; for an interrupt from the clock

; Main loop. Triggered every 1/60s by an interrupt from the clock
:mainLoop

   

    SUB [blockPosition],1       ;increment position by 1
    
    IFU [blockPosition],0
    
    SET [blockPosition], 131

    SET A, 2
    SET B,  " "
    HWI [keyboardHWaddr]
        
    IFE I,10        ;when air time has reached maximum,
    SET C,0         ;set keyboard to off
        
    SET X, [blockPosition]
    SET Y, [blockPosition]
    SHR X,2
    AND Y,3
    ADD X,0x807F

    ADD J,1             ;Increment frame counter (J) per cycle
                        ; Send an interrupt to the keyboard
    
    MOD J,10            ;Limit J to be less than 10 to run every 1/6 second (1/60 cycles per second)
    
    IFE J,0             ;increment which frame number
    ADD Z,1             
    MOD Z,3             ;Mod for 3 frames of animation

    
    
    IFC X, 0x7f60
    SET [X], [blockLeft+Y]     ;Display on one row down 
    ADD X,1
    IFC X, 0x7f60
    SET [X],[blockRight+Y]     ;Display on 0ith frame defined by literal
    
;running
    IFN C, 1 ;running animation
    SET I,0    
    JSR running

;jumping    
    IFE C, 1;jump animation
    IFL I,10
    JSR jumping

    SET [0x80A0], [0x0000]
    SET [0x80A1], [0x0000]
    SET [0x80A2], [0x0000]
    SET [0x80A3], [0x0000]
    SET [0x80A4], [0x0000]
    SET [0x80A5], [0x0000]
    SET [0x80A6], [0x0000]
    SET [0x80A7], [0x0000]
    SET [0x80A8], [0x0000]
    SET [0x80A9], [0x0000]
    SET [0x80AA], [0x0000]
    SET [0x80AB], [0x0000]
    SET [0x80AC], [0x0000]
    SET [0x80AD], [0x0000]
    SET [0x80AE], [0x0000]
    SET [0x80AF], [0x0000]
    SET [0x80B0], [0x0000]
    SET [0x80B1], [0x0000]
    SET [0x80B2], [0x0000]
    SET [0x80B3], [0x0000]
    SET [0x80B4], [0x0000]
    SET [0x80B5], [0x0000]
    SET [0x80B6], [0x0000]
    SET [0x80B7], [0x0000]
    SET [0x80B8], [0x0000]
    SET [0x80B9], [0x0000]
    SET [0x80BA], [0x0000]
    SET [0x80BB], [0x0000]
    SET [0x80BC], [0x0000]
    SET [0x80BD], [0x0000]
    SET [0x80BE], [0x0000]
    SET [0x80BF], [0x0000]


    RFI 0               ; Since mainLoop is technically an interrupt
                        ; service routine, return to where we came from
:blockPosition                        
    DAT 0x0000              
                        
:running
    SET [0x8065],[0x1100]
    SET [0x8046],[0x2200]
    SET [0x8067],[0x3300]

    SET [0x8066],[thiefHead+Z]  ;Display on 0ith frame defined by literal 
    SET [0x8085], [leftBody+Z]      ;Display on one row down 
    SET [0x8086], [rightBody+Z]
    SET [0x8087], [pixel+Z]
    SET PC, POP

:jumping
    SET [0x8085],[0x1100]  
    SET [0x8086],[0x1100] 
    SET [0x8087],[0x1100] 

    ADD I,1
    SET [0x8046],[thiefHead+Z]
    SET [0x8065], [leftBody+Z]      ;Display on one row down 
    SET [0x8066], [rightBody+Z]
    SET [0x8067], [pixel+Z]
    SET PC, POP

:splashScreen
    SET A, 2
    SET B,  " "
:splashScreenLoop
    HWI [keyboardHWaddr]
    IFE C,0
    SET PC,POP
    SET PC, splashScreenLoop
    
; Configures the clock to create an interrupt every 1/60 second and sets
; up the interrupt handler for it.
:setupClock
    SET A, 0            ; Put clock into set frequency mode
    SET B, 3            ; Set clock frequency to 1/60s
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
        ; at (0,0) as bg color
        ; at (1,0) as bg color
        ; at (2,0) as bg color
        ; at (3,0) as bg color
        ; at (4,0) as bg color
        ; at (5,0) as bg color
        ; at (6,0) as bg color
        ; at (7,0) as fg color
    DAT 0x0000
    ; Used...
        ; at (0,0) as fg color
        ; at (1,0) as fg color
        ; at (2,0) as fg color
        ; at (3,0) as fg color
        ; at (4,0) as fg color
        ; at (5,0) as fg color
        ; at (6,0) as fg color
    DAT 0x0248

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

:monitorFont
    ; Font Char 0
    ; Used...
        ; at (4,0)
    ;* *    ;
    ;  *    ;
    ;  *    ;
    ;  *    ;
    ;  *    ;
    ;  *    ;
    ;  *    ;
    ;* *    ;
    DAT 0x81ff, 0x0
    ; Font Char 1
    ; Used...
        ; at (1,0)
    ;*      ;
    ;*   * *;
    ;*   * *;
    ;*   * *;
    ;*   * *;
    ;*   * *;
    ;*   * *;
    ;*      ;
    DAT 0xff00, 0x7e7e
    ; Font Char 2
    ; Used...
        ; at (7,0)
    ;* * * *;
    ;* * * *;
    ;* * * *;
    ;* * * *;
    ;* * * *;
    ;* * * *;
    ;* * * *;
    ;* * * *;
    DAT 0xffff, 0xffff
    ; Font Char 3
    ; Used...
        ; at (3,0)
    ;* *    ;
    ;* *   *;
    ;* *   *;
    ;* *   *;
    ;* *   *;
    ;* *   *;
    ;* *   *;
    ;* *    ;
    DAT 0xffff, 0x7e
    ; Font Char 4
    ; Used...
        ; at (5,0)
    ;* * *  ;
    ;* * *  ;
    ;* * *  ;
    ;* * *  ;
    ;* * *  ;
    ;* * *  ;
    ;* * *  ;
    ;* * *  ;
    DAT 0xffff, 0xff00
    ; Font Char 5
    ; Used...
        ; at (2,0)
    ;*      ;
    ;*      ;
    ;*      ;
    ;*      ;
    ;*      ;
    ;*      ;
    ;*      ;
    ;*      ;
    DAT 0xff00, 0x0
    ; Font Char 6
    ; Used...
        ; at (0,0)
    ;       ;
    ;  * *  ;
    ;  * *  ;
    ;  * *  ;
    ;  * *  ;
    ;  * *  ;
    ;  * *  ;
    ;       ;
    DAT 0x007e, 0x7e00
    ; Font Char 7
    ; Used...
        ; at (6,0)
    ;* * *  ;
    ;    *  ;
    ;    *  ;
    ;    *  ;
    ;    *  ;
    ;    *  ;
    ;    *  ;
    ;* * *  ;
    DAT 0x8181, 0xff00

;Dude info
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


:blockLeft
    DAT 0x0106
    DAT 0x0101
    DAT 0x0103
    DAT 0x0104
    ;DAT 0x0102
    
:blockRight
    DAT 0x0102
    DAT 0x1005
    DAT 0x1000
    DAT 0x1007
    ;DAT 0x0106
    
:thiefHead
    DAT 0x2312
    DAT 0x320F
    DAT 0x2312
    
:leftBody
    DAT 0x320D
    DAT 0x3209
    DAT 0x3208
    
:rightBody
    DAT 0x320B
    DAT 0x3210
    DAT 0x3211
    
:pixel
    DAT 0x420A
    DAT 0x420E
    DAT 0x420A