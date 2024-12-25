;   Prototype: void asmIIR(short *, unsigned short *, short *, unsigned short, short*);
;                           
;   Entry:  arg0: AR0-filter input sample buffer pointer   
;           arg1: T0-number of samples in input buffer
;           arg2: AR2-output sample buffer pointer
;           arg3: AR1-IIR coefficients array pointer     
;           arg4: T1-number of biquads IIR  sections
;           arg5: AR3-delayline pointer  
;
;
;   Direct form II - IIR filter (the ith sections):
;   w(n) = x(n) - ai1 * w(n-1) - ai2 * w(n-2)
;   y(n) = bi0 * w(n) + bi1 * w(n-1) + bi2 * w(n-2)
;
;   Memory arrangement and initialization: (1,2,...i,..,Ns)
;   tempbuf[2*Ns] coefficient[5*Ns]
;   AR3 -> w1j       AR1 -> a1i
;          w1j              a2i
;           :               b2i
;          w2j              b0i
;          w2j              b1i
;           :                :      
;
;   Scale: Coefficient is in Q14 format            
;   The filter result is scaled up to compensate the Q14 coefficient                              

      .global _asmIIR
      .sect   ".text:iir_code" 
	
_asmIIR
      pshm  ST1_55                 ; Save ST1, ST2, and ST3
      pshm  ST2_55
      pshm  ST3_55

      psh   T3                     ; Save T3 on stack
      pshboth XAR6                 ; Save AR6 on stack

      or    #0x340, mmap(ST1_55)   ; Set FRCT,SXMD,SATD
	  ;bclr SXMD
      bset  SMUL                   ; Set SMUL
      sub   #1,T0                  ; Number of samples - 1
      mov   T0,BRC0                ; Set up outer loop counter
      sub   #1,T1,T0               ; Number of sections -1	
      mov   T0,BRC1                ; Set up inner loop counter
	
      mov   T1,T0                  ; Set up circular buffer sizes
      sfts  T0,#1          
      mov   mmap(T0),BK03          ; BK03=2*number of sections
      sfts  T0,#1				
      add   T1,T0                                      
      mov   mmap(T0),BK47          ; BK47=5*number of sections
      mov   mmap(AR3),BSA23        ; Initial delay buffer base 
      mov   mmap(AR2),BSA67        ; Initial coefficient base 
      mov   #0,AR3                 ; Initial delay buffer entry 
      mov   #0,AR6                 ; Initial coefficient entry 
      or    #0x48,mmap(ST2_55)     ; bset  AR6LC, bset  AR3LC
      mov   #1,T0                  ; Used for shift left and necessary to put mov in parallel with mpym
||    rptblocal sample_loop-1	   ; Start IIR filter loop  
      mov   *AR0+<<#13,AC0         ; AC0 = x(n)/4 (in Q15)
      							   ; Keep Q15 format after scaling but note that for summation lateron
								   ; Q15 x Q14 << 1 = Q30 format is necessary while AC0 is first in Q31
								   ; therefore shift one less to the left so << #13 instead of <<#14
||    rptblocal filter_loop-1      ; Loop for each section
      masm  *(AR3+T1),*AR6+,AC0    ; AC0-=ai1*wi(n-1)     AC0 Q30
      masm  T3=*AR3,*AR6+,AC0	   ; AC0-=ai2*wi(n-2)     
      mov   rnd(hi(AC0<<T0)),*AR3  ; wi(n-2)=wi(n) 		  w Q15
||    mpym  *AR6+,T3,AC0           ; AC0+=bi2*wi(n-2)
      macm  *(AR3+T1),*AR6+,AC0    ; AC0+=bi0*wi(n)
      macm  *AR3+,*AR6+,AC0        ; AC0+=bi1*wi(n-1)
filter_loop
      ; Compensate for scaling in case necessary
      mov  rnd(hi(AC0<<#1)),*AR1+  ; Store result in Q15  AC0 Q30
sample_loop

      popboth XAR6                 ; Restore AR6
      pop   T3                     ; Restore T3
      popm  ST3_55                 ; Restore ST1, ST2, and ST3
      popm  ST2_55
      popm  ST1_55
      ret

      .end
