;******************************************************************************
;* FILENAME                                                                   *
;*   anf.asm                                                                  *
;******************************************************************************
;* DESCRIPTION                                                                *
;*   Adaptive Notch Filter implementation in Assembly with Q factor updates   *
;******************************************************************************
; Constants and macros
	.mmregs

MU    .set 0x2000          ; Step size (adjust as needed in Q15 format)

; Functions callable from C code
	.sect	".text"
	.global	_anf

;******************************************************************************
; FUNCTION DEFINITION: _anf                                                   *
; Description: Implements the 2nd order ANF filter in assembly                *
; Arguments:                                                                  *
;   y (Q15): Current input sample                                             *
;   s[3] (Q12): State vector                                                  *
;   a (Q14): Adaptive coefficient                                             *
;   rho[2] (Q15): rho and rho^2                                               *
;   index: Circular buffer index pointer                                      *
;******************************************************************************

; int anf(int y,                => T0  (most important scalar value)
;          int *s,              => AR0  (pointer to the state vector s)
;          int *a,              => AR1  (pointer to the adaptive coefficient a)
;          int *rho,            => AR2  (pointer to the fixed or adaptive rho values)
;          unsigned int* index  => AR3  (pointer to the index for circular buffer)
;         );                     => (remaining parameters, if any, go on the stack)
_anf:
        ; Save the status registers
        PSHM ST0_55
        PSHM ST1_55
        PSHM ST2_55

        ; Step 1: Shift values in state vector
        MOV *AR0(+1), AC0      ; Load s[1] into AC0 (Q12)
        SFTS AC0, #3           ; Convert Q12 to Q15
        MOV AC0, *AR0(+2)      ; s[2] = s[1]
        MOV *AR0, AC0          ; Load s[0] into AC0 (Q12)
        SFTS AC0, #3           ; Convert Q12 to Q15
        MOV AC0, *AR0(+1)      ; s[1] = s[0]

        ; Step 2: Update rho(m)
        MOV *AR2, T1           ; T1 = rho(m-1) (Q15)
        MOV #0x7333, AC0       ; AC0 = lambda (0.9 in Q15 format)
        MPY T1, AC0            ; AC0 = lambda * rho(m-1) (Q15 * Q15 = Q30)
        SFTS AC0, #-15         ; Adjust back to Q15

        MOV #0x6666, T1        ; T1 = rho_inf = 0.1 in Q15 format
        MOV #0x0CCD, AC1       ; AC1 = (1 - lambda) = 0.1 in Q15 format
        MPY T1, AC1            ; AC1 = (1 - lambda) * rho_inf (Q15 * Q15 = Q30)
        SFTS AC1, #-15         ; Adjust back to Q15

        ADD AC1, AC0           ; AC0 = lambda * rho(m-1) + (1 - lambda) * rho_inf = rho(m)

        MOV AC0, *AR2          ; Update rho(m) (Q15)

        ; Step 3: Calculate s(m)
        MOV *AR1, T2           ; T2 = a(m-1) (Q14)
        SFTS T2, #-1           ; Convert Q14 to Q15
        MOV *AR0(+1), AC2      ; AC2 = s(m-1) (Q12)
        SFTS AC2, #3           ; Convert Q12 to Q15
        MPY T2, AC2            ; AC2 = a(m-1) * s(m-1) (Q15 * Q15 = Q30)
        SFTS AC2, #-15         ; Adjust back to Q15

        MOV *AR2, AC0          ; AC0 = rho(m) (Q15)
        MPY AC0, AC2           ; AC2 = rho(m) * (a(m-1) * s(m-1)) (Q15 * Q15 = Q30)
        SFTS AC2, #-15         ; Adjust back to Q15

        ADD T0, AC2            ; AC2 = y + rho(m) * (a(m-1) * s(m-1))

        MOV AC0, AC1           ; AC1 = rho(m)
        MPY AC0, AC1           ; AC1 = rho(m)^2 (Q15 * Q15 = Q30)
        SFTS AC1, #-15         ; Adjust back to Q15

        MOV *AR0(+2), T1       ; T1 = s(m-2) (Q12)
        SFTS T1, #1            ; Convert Q12 to Q15
        SFTS T1, #1            ; Convert Q12 to Q15
        SFTS T1, #1            ; Convert Q12 to Q15
        MPY  T1, AC1           ; AC1 = rho(m)^2 * s(m-2) (Q15 * Q15 = Q30)
        SFTS AC1, #-15         ; Adjust back to Q15

        SUB AC1, AC2           ; AC2 = s(m) = y + rho(m) * a(m-1) * s(m-1) - rho(m)^2 * s(m-2)
        SFTS AC2, #-3          ; Convert Q15 to Q12
        MOV AC2, *AR0          ; Update s[0] = s(m) (Q12)

        ; Step 4: Calculate e(m)
        MOV *AR0(+2), AC1      ; AC1 = s(m-2) (Q12)
        SFTS AC1, #3           ; Convert Q12 to Q15
        ADD AC2, AC1           ; AC1 = s(m) + s(m-2)

        MOV *AR1, T1           ; T1 = a(m-1) (Q14)
        SFTS T1, #-1           ; Convert Q14 to Q15
        MOV *AR0(+1), AC2      ; AC2 = s(m-1) (Q12)
        SFTS AC2, #3           ; Convert Q12 to Q15
        MPY T1, AC2            ; AC2 = a(m-1) * s(m-1) (Q15 * Q15 = Q30)
        SFTS AC2, #-15         ; Adjust back to Q15

        SUB AC2, AC1           ; AC1 = s(m) + s(m-2) - a(m-1) * s(m-1)
        MOV AC1, T0            ; T0 = e(m) (Q15)

        ; Step 5: Update a(m)
        MOV *AR0(+1), AC2      ; AC2 = s(m-1) (Q12)
        SFTS AC2, #3           ; Convert Q12 to Q15
        MPY T0, AC2            ; AC2 = e(m) * s(m-1) (Q15 * Q15 = Q30)
        SFTS AC2, #-15         ; Adjust back to Q15

        MOV MU, T1             ; T1 = mu (Q15)
        MPY T1, AC2            ; AC2 = mu * e(m) * s(m-1) (Q15 * Q15 = Q30)
        SFTS AC2, #-15         ; Adjust back to Q15

        MOV *AR1, T1           ; T1 = a(m-1) (Q14)
        SFTS T1, #-1           ; Convert Q14 to Q15
        ADD T1, AC2            ; AC2 = a(m-1) + mu * e(m) * s(m-1) (Q15)
        SFTS AC2, #-1          ; Convert Q15 to Q14
        MOV AC2, *AR1          ; Update a(m) (Q14)

        ; Restore the status registers
        POPM ST2_55
        POPM ST1_55
        POPM ST0_55

        RET                    ; Return with e(m) in T0
;******************************************************************************
;* End of anf.asm                                                              *
;******************************************************************************
