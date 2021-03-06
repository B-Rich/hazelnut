include l4pre.inc

  dcode

  Copyright GMD, L4.KDIO.PC, 21,06,96, 24 

 
;*********************************************************************
;******                                                         ******
;******                L4 KDIO.PC                               ******
;******                                                         ******
;******                                                         ******
;******                                                         ******
;******                                   created:  28.02.91    ******
;******                                   modified: 21.06.96    ******
;******                                                         ******
;*********************************************************************
 

  public init_kdio
  public set_remote_info_mode
  public open_debug_keyboard
  public close_debug_keyboard
  public init_debug_screen
  public open_debug_screen
  public kd_outchar
  public kd_inchar
  public kd_incharety
  public kd_kout
  public local_outbar
  public old_pic1_imr

  extrn  reset:near



.nolist
include l4const.inc
include adrspace.inc
include intrifc.inc
include uid.inc
include tcb.inc
.list
 

ok_for i486,pentium,ppro,k6


cga_crtc_base       equ   3D4h
hercules_crtc_base  equ   3B4h


cga_base      equ 0B8000h
hercules_base equ 0B0000h

lines         equ 25
columns       equ 80


video_control_data_area struc

                    db 449h dup (0)
  display_mode_set  db 0
                    db 19h dup (0)
  crtc_base         dw 0

video_control_data_area ends


cursor_addr_high    equ 0Eh
cursor_addr_low     equ 0Fh

screen_start_high   equ 0Ch
screen_start_low    equ 0Dh





deb_screen_base     dd cga_base
deb_crtc_base       dw 3DAh



;----------------------------------------------------------------------------
;
;       init kdio
;
;----------------------------------------------------------------------------
;
;       AL    'a'   automatic
;       AL    'c'   CGA screen
;       AL    'm'   monochrom screen
;       AL    'h'   hercules screen
;
;----------------------------------------------------------------------------

        assume ds:codseg





init_kdio:

  pushad
  push  ds

  IFAE  esp,<offset tcb_space>
        mov   ebx,phys_mem
        mov   ds,ebx
  FI

  mov   dx,cga_crtc_base
  IFZ   al,'c'
        mov   edi,cga_base
  ELIFZ al,'m'
        mov   edi,hercules_base
  ELIFZ al,'h'
        mov   dx,hercules_crtc_base
        mov   edi,hercules_base
  ELSE_
        mov   edi,hercules_base
        mov   dx,ds:[crtc_base]
        IFNZ  ds:[display_mode_set],7
              mov   edi,cga_base
        FI
  FI

  mov   [deb_screen_base],edi
  mov   [deb_crtc_base],dx

  pop   ds
  popad
  ret





remote_io_open      db false









kd_incharety:
 
  call  local_soft_incharety
  IFZ   eax,-1 
        call remote_incharety
        IFZ   [remote_io_open],false
              IFZ   al,'+'
                    mov   [remote_io_open],true
              FI
              stc
              sbb   eax,eax
        FI
  FI
  ret
 



;----------------------------------------------------------------------------
;
;       kd inchar
;
;----------------------------------------------------------------------------
; POSTCONDITION:
;
;       EAX    char
;
;----------------------------------------------------------------------------
 
 
kd_inchar:
 
  push  ebx
  sub   ebx,ebx
  DO
        call  local_incharety
        test  eax,eax
        EXITNS
        call remote_incharety
        test  eax,eax
        REPEATS

        cmp   al,'~'
        REPEATZ

        IFZ   [remote_io_open],false
              IFZ   al,'+'
                    mov   [remote_io_open],true
              FI
              REPEAT
        FI
        IFZ   al,27
              mov   bl,al
              REPEAT
        FI
        IFZ   al,'['
        CANDZ bl,27
              mov   bl,al
              REPEAT
        FI
        IFZ   bl,'['
              IFZ   al,'A'
                    mov   al,3
              FI
              IFZ   al,'B'
                    mov   al,10
              FI
              IFZ   al,'C'
                    mov   al,2
              FI
              IFZ   al,'D'
                    mov   al,8
              FI
              IFZ   al,0
                    mov   al,1
              FI
              IFZ   al,'5'
                    mov   al,11h
              FI
              IFZ   al,'6'
                    mov   al,10h
              FI
        FI
  OD
  pop   ebx
  ret
 




;*********************************************************************
;******                                                         ******
;******      local info (kernel debug) support                  ******
;******                                                         ******
;*********************************************************************
 

        align 4


kout_ptr      dd 0


cursor_x      db 0
cursor_y      db 0

de_facto_xy   dw 0

charmode      db 0



shift_status  db 0

old_pic1_imr  db 0

        align 4

debug_keyboard_level      dd 0


shift_left    equ 2Ah
shift_right   equ 36h

break_mask    equ 80h

num_lock      equ 45h

kb_data       equ 60h
kb_status     equ 64h
kb_cmd        equ 64h

disable_keyboard    equ 0ADh
enable_keyboard     equ 0AEh

pic1_icw1     equ 20h
pic1_imr      equ 21h

seoi_kb       equ 61h



           align 4

chartab    db   0,  0  ;  00
           db 1Bh,1Bh  ;  01    esc
           db '1','!'  ;  02    1
           db '2',22h  ;  03    2
           db '3','�'  ;  04    3
           db '4','$'  ;  05    4
           db '5','%'  ;  06    5
           db '6','&'  ;  07    6
           db '7','/'  ;  08    7
           db '8','*'  ;  09    8   ; US 
           db '9',')'  ;  0A    9
           db '0','='  ;  0B    0
           db '-','?'  ;  0C    �   ; US
           db 27h,'+'  ;  0D    '   ; US
           db 08h,08h  ;  0E    backspace
           db 09h,09h  ;  0F    tab
           db 'q','Q'  ;  10    Q
           db 'w','W'  ;  11    W
           db 'e','E'  ;  12    E
           db 'r','R'  ;  13    R
           db 't','T'  ;  14    T
           db 'z','Z'  ;  15    Z
           db 'u','U'  ;  16    U
           db 'i','I'  ;  17    I
           db 'o','O'  ;  18    O
           db 'p','P'  ;  19    P
           db 219,216  ;  1A    �
           db '+','*'  ;  1B    +
           db 0Dh,0Dh  ;  1C    enter
           db   0,  0  ;  1D    (left) ctrl
           db 'a','A'  ;  1E    A
           db 's','S'  ;  1F    S
           db 'd','D'  ;  20    D
           db 'f','F'  ;  21    F
           db 'g','G'  ;  22    G
           db 'h','H'  ;  23    H
           db 'j','J'  ;  24    J
           db 'k','K'  ;  25    K
           db 'l','L'  ;  26    L
           db 218,215  ;  27    �
           db 217,214  ;  28    �
           db  35, 39  ;  29    �
           db   0,  0  ;  2A    (left) shift
           db 3Ch,3Eh  ;  2B    <
           db 'y','Y'  ;  2C    Y
           db 'x','X'  ;  2D    X
           db 'c','C'  ;  2E    C
           db 'v','V'  ;  2F    V
           db 'b','B'  ;  30    B
           db 'n','N'  ;  31    N
           db 'm','M'  ;  32    M
           db ',',';'  ;  33    ,
           db '.',':'  ;  34    .
           db '-','_'  ;  35    -
           db   0,  0  ;  36    (right) shift
           db '+','+'  ;  37    +
           db   0,  0  ;  38    (left) alt
           db 20h,20h  ;  39    space
           db   0,  0  ;  3A    caps lock
           db 81h,91h  ;  3B    f1
           db 82h,92h  ;  3C    f2
           db 83h,93h  ;  3D    f3
           db 84h,94h  ;  3E    f4
           db 85h,95h  ;  3F    f5
           db 86h,96h  ;  40    f6
           db 87h,97h  ;  41    f7
           db 88h,98h  ;  42    f8
           db 89h,99h  ;  43    f9
           db 8Ah,9Ah  ;  44    f10
           db   0,  0  ;  45    num lock
           db '*','*'  ;  46    *
           db 01h,01h  ;  47    7    home
           db 03h,03h  ;  48    8    up arrow
           db 10h,10h  ;  49    9    page up
           db   0,  0  ;  4A
           db 08h,08h  ;  4B    4    left arrow
           db 01h,01h  ;  4C    5
           db 02h,02h  ;  4D    6    right arrow
           db 0Dh,0Dh  ;  4E    enter
           db 10h,10h  ;  4F    1    end
           db 0Ah,0Ah  ;  50    2    down arrow
           db 11h,11h  ;  51    3    page down
           db 0Bh,0Bh  ;  52    0    ins
           db 0Ch,0Ch  ;  53    .    del
           db   0,  0  ;  54    sys req
           db   0,  0  ;  55
           db '<','>'  ;  56
           db 8Bh,9Bh  ;  57    f11
           db   7,  7  ;  58    f12
           db   0,  0  ;  59
           db   0,  0  ;  5A
           db   0,  0  ;  5B
           db   0,  0  ;  5C
           db   0,  0  ;  5D
           db   0,  0  ;  5E
           db   0,  0  ;  5F
           db   0,  0  ;  60
           db   0,  0  ;  61
           db   0,  0  ;  62
           db   0,  0  ;  63
           db   0,  0  ;  64
           db   0,  0  ;  65
           db   0,  0  ;  66
           db   0,  0  ;  67
           db   0,  0  ;  68
           db   0,  0  ;  69
           db   0,  0  ;  6A
           db   0,  0  ;  6B
           db   0,  0  ;  6C
           db   0,  0  ;  6D
           db   0,  0  ;  6E
           db   0,  0  ;  6F
           db   0,  0  ;  70
           db   0,  0  ;  71
           db   0,  0  ;  72
           db   0,  0  ;  73
           db   0,  0  ;  74
           db   0,  0  ;  75
           db   0,  0  ;  76
           db   0,  0  ;  77
           db   0,  0  ;  78
           db   0,  0  ;  79
           db   0,  0  ;  7A
           db   0,  0  ;  7B
           db   0,  0  ;  7C
           db   0,  0  ;  7D
           db   0,  0  ;  7E
           db   0,  0  ;  7F


;----------------------------------------------------------------------------
;
;       open / close debgug terminal
;
;----------------------------------------------------------------------------

  assume ds:codseg


open_debug_keyboard:

  push  eax
  push  ds
  pushfd
  cli

  mov   eax,cr0
  bt    eax,31
  IFC
        mov   eax,phys_mem
        mov   ds,eax
  FI

  in    al,pic1_imr
  IFZ   [debug_keyboard_level],0
        mov   [old_pic1_imr],al
  FI
  inc   [debug_keyboard_level]
  test  al,00000010b
  IFZ
        or    al,00000010b
        out   pic1_imr,al
        DO
              in    al,kb_status
              test  al,2
              REPEATNZ
        OD
        mov   al,disable_keyboard
        out   kb_cmd,al
        DO
              in    al,kb_status
              test  al,2
              REPEATNZ
        OD
        mov   al,0F4h                      ; nop command, because may be
        out   kb_data,al                   ; within set led sequence
        DO
              in    al,kb_status
              test  al,1
              REPEATZ
        OD
        in    al,kb_data
        DO
              in    al,kb_status
              test  al,2
              REPEATNZ
        OD
        mov   al,enable_keyboard
        out   kb_cmd,al
  FI

  popfd                                    ; Rem: change of NT impossible
  pop   ds
  pop   eax
  ret



close_debug_keyboard:

  push  eax
  push  ds
  pushfd
  cli

  mov   eax,cr0
  bt    eax,31
  IFC
        mov   eax,phys_mem
        mov   ds,eax
  FI

  dec   [debug_keyboard_level]
  IFZ
        in    al,pic1_imr
        and   al,11111101b
        mov   ah,[old_pic1_imr]
        and   ah,00000010b
        or    al,ah
        out   pic1_imr,al
  FI

  popfd                                    ; Rem: change of NT impossible
  pop   ds
  pop   eax
  ret



;----------------------------------------------------------------------------
;
;       local incharety
;
;----------------------------------------------------------------------------
; PRECONDITION:
;
;       DS    phys mem
;
;----------------------------------------------------------------------------
; POSTCONDITION:
;
;       EAX   -1    iff (remote info mode = off OR no input char available)
;
;       EAX   char  else
;
;----------------------------------------------------------------------------


local_incharety:

  call  update_cursor



local_soft_incharety:

  in    al,kb_status
  test  al,1

  IFZ
        stc
        sbb   eax,eax
        ret
  FI

  sub   eax,eax
  in    al,kb_data


  IFZ   al,num_lock
  CANDZ [shift_status],1
        mov   cl,1
        jmp   reset
  FI

  CORZ  al,shift_left
  IFZ   al,shift_right
        mov   [shift_status],1

  ELIFZ al,shift_left+break_mask
        mov   [shift_status],0
  ELIFZ al,shift_right+break_mask
        mov   [shift_status],0
  FI

  test  al,break_mask
  IFZ
        add   al,al
        add   al,[shift_status]
        mov   al,[eax+chartab]
        test  al,al
        IFNZ
              ret
        FI
  FI

  stc
  sbb   eax,eax
  ret




;----------------------------------------------------------------------------
;
;       open / init debug screen
;
;----------------------------------------------------------------------------






open_debug_screen:

  push  eax
  push  edx
  mov   dx,3D8h
  mov   al,9
  out   dx,al
  pop   edx
  pop   eax
  ret



init_debug_screen:

  push  eax
  push  edx

  mov   dx,[deb_crtc_base]
  mov   al,screen_start_low
  out   dx,al
  inc   edx
  mov   al,0
  out   dx,al
  dec   edx
  mov   al,screen_start_high
  out   dx,al
  inc   edx
  shr   eax,16
  mov   al,0
  out   dx,al

  pop   edx
  pop   eax
  ret





;----------------------------------------------------------------------------
;
;       kout
;
;----------------------------------------------------------------------------



kd_kout:

  push  ebx
  push  ecx

  mov   ebx,[deb_screen_base]    ;;;;; 0b0000h 
  mov   ecx,[kout_ptr]

  mov   byte ptr [(ecx*2)+ebx],al
  mov   byte ptr [(ecx*2)+ebx+1],0Fh

  inc   ecx
  IFAE  ecx,10*80
        sub   ecx,ecx
  FI
  mov   word ptr [(ecx*2)+ebx],0

  mov   [kout_ptr],ecx

  pop   ecx
  pop   ebx
  ret




;----------------------------------------------------------------------------
;
;       update cursor
;
;----------------------------------------------------------------------------



update_cursor:

  push  eax
  push  edx

  mov   ax,word ptr [cursor_x]
  IFNZ  [de_facto_xy],ax

        mov   [de_facto_xy],ax

        movzx edx,al
        movzx eax,ah
        imul  eax,columns
        add   eax,edx
        shl   eax,8

        mov   dx,[deb_crtc_base]
        mov   al,cursor_addr_low
        out   dx,al
        inc   edx
        mov   al,ah
        out   dx,al
        dec   edx
        mov   al,cursor_addr_high
        out   dx,al
        inc   edx
        shr   eax,16
        out   dx,al

  FI
  pop   edx
  pop   eax
  ret



;----------------------------------------------------------------------------
;
;       kd outchar
;
;----------------------------------------------------------------------------
; PRECONDITION:
;
;       AL    char
;
;       DS    phys mem
;
;----------------------------------------------------------------------------
; POSTCONDITION:
;
;       EAX   scratch
;
;----------------------------------------------------------------------------



kd_outchar:

  mov   ah,[charmode]
  IFZ   ah,1
        mov   [cursor_y],al
        mov   [charmode],2
        ret
  FI
  IFZ   ah,2
        mov   [cursor_x],al
        mov   [charmode],0

        push  eax
        mov   al,27
        call  remote_outchar
        mov   al,'['
        call  remote_outchar
        mov   al,[cursor_y]
        inc   al
        call  remote_outdec8
        mov   al,';'
        call  remote_outchar
        mov   al,[cursor_x]
        inc   al
        call  remote_outdec8
        mov   al,'H'
        call  remote_outchar
        pop   eax
        ret
  FI
  IFZ   al,6
        mov   [charmode],1
        ret
  FI
  IFZ   al,1
        mov   [cursor_x],0
        mov   [cursor_y],0
        push  eax
        mov   al,'H'
        call  vt100_control
        pop   eax
        ret
  FI
  IFZ   al,5
        pushad
        movzx edi,[cursor_y]
        imul  edi,columns*2
        movzx eax,[cursor_x]
        lea   edi,[(eax*2)+edi]
        add   edi,[deb_screen_base]
        mov   ecx,columns
        sub   ecx,eax
        IFNC
              mov   eax,07200720h
              cld
              rep   stosd
        FI
        mov   al,'K'
        call  vt100_control
        popad
        ret
  FI
  IFZ   al,8
        IFNZ  [cursor_x],0
              dec   [cursor_x]
        FI
        call  remote_outchar
        ret
  FI
  IFZ   al,13
        mov   [cursor_x],0
        call  remote_outchar
        ret
  FI
  IFZ   al,10
        IFB_  [cursor_y],24
              inc   [cursor_y]
        ELSE_
              pushad
              mov   eax,07200720h
              mov   edi,[deb_screen_base]
              lea   esi,[edi+columns*2]
              mov   ecx,(lines-1)*columns*2/4
              cld
              rep   movsd
              mov   ecx,columns*2/4
              rep   stosd
              popad
        FI
        call  remote_outchar
        ret
  FI

  push  ecx
  push  edx
  movzx ecx,[cursor_y]
  imul  ecx,columns
  add   cl,[cursor_x]
  adc   ch,0
  add   ecx,ecx
  add   ecx,[deb_screen_base]
  mov   [ecx],al
  mov   byte ptr [ecx+1],7
  inc   [cursor_x]
  pop   edx
  pop   ecx

  IFB_  al,20h
        mov   al,' '
  FI
  call  remote_outchar

  ret





;----------------------------------------------------------------------------
;
;       local outbar
;
;----------------------------------------------------------------------------
; PRECONDITION:
;
;       EAX   value
;       EBX   100% value
;       CL    width
;       DL    x
;       DH    y
;
;       DS    linear space
;
;----------------------------------------------------------------------------




local_outbar:

  pushad

  mov   esi,columns*2
  movzx edi,dh
  imul  edi,esi
  movzx edx,dl
  lea   edi,[(edx*2)+edi+PM]
  add   edi,[deb_screen_base+PM]

  movzx ecx,cl
  imul  eax,ecx
  sub   edx,edx
  idiv  ebx
  shr   ebx,1
  cmp   edx,ebx
  cmc
  adc   al,0
  IFA   al,cl

  FI

  mov   ch,0

  IFNZ  al,0
        dec   al
        mov   byte ptr [edi],0DFh
        sub   edi,esi
        add   ch,2
  FI
  DO
        sub   al,2
        EXITB
        mov   byte ptr [edi],0DBh
        sub   edi,esi
        add   ch,2
        cmp   ch,cl
        REPEATBE
  OD
  IFZ   al,-1
  CANDBE ch,cl
        mov   byte ptr [edi],0DCh
        sub   edi,esi
        add   ch,2
  FI
  IFBE  ch,cl
        DO
              test  ch,2
              IFNZ
                    mov   byte ptr [edi],20h
              ELSE_
                    mov   byte ptr [edi],0C4h
              FI
              sub   edi,esi
              add   ch,2
              cmp   ch,cl
              REPEATBE

        OD
  FI

  popad
  ret


;*********************************************************************
;******                                                         ******
;******      remote info (kernel debug) support                 ******
;******                                                         ******
;*********************************************************************
 

                    align 4

remote_info_port    dw 0


;----------------------------------------------------------------------------
;
;       8250  ports and masks
;
;----------------------------------------------------------------------------


sio_rbr     equ     0           ; receiver buffer register
sio_thr     equ     0           ; transmitter holding register
sio_ier     equ     1           ; interrupt enable register
sio_iir     equ     2           ; interrupt identification register
sio_lcr     equ     3           ; line control register
sio_mcr     equ     4           ; modem control register
sio_lsr     equ     5           ; line status register
sio_msr     equ     6           ; modem status register
sio_scratch equ     7           ; scratch pad register
sio_dllow   equ     0           ; baud rate divisor latch (low)
sio_dlhigh  equ     1           ; baud rate divisor latch (high)


lsr_receiver_full     equ 00000001b
lsr_thr_empty         equ 00100000b
lsr_tsr_empty         equ 01000000b
lsr_receiver_full_bit equ 0
lsr_thr_empty_bit     equ 5
lsr_tsr_empty_bit     equ 6
lsr_overrun_bit       equ 1

lcr_dlab_bit          equ 7

mcr_dtr              equ 00001b
mcr_rts              equ 00010b
mcr_enable           equ 01000b
 
iir_no_intr          equ 001b
iir_modem_status     equ 000b
iir_thr_empty        equ 010b
iir_data_avail       equ 100b
iir_line_status      equ 110b

ier_data_avail       equ 0001b
ier_thr_empty        equ 0010b
ier_line_status      equ 0100b
ier_modem_status     equ 1000b


rate_divisor  dw  192        ;   600
              dw   96        ;  1200
              dw   48        ;  2400
              dw   24        ;  4800
              dw   12        ;  9600
              dw    6        ; 19200
              dw    3        ; 38400
              dw    1        ;115200


;----------------------------------------------------------------------------
;
;       IO macros
;
;----------------------------------------------------------------------------


outdx macro relative_port,reg

  jmp   $+2
  jmp   $+2
  if relative_port eq 0
  out   dx,reg
  else
  add   dl,relative_port
  out   dx,reg
  sub   dl,relative_port
  endif
  endm


indx macro reg,relative_port

  jmp   $+2
  jmp   $+2
  if relative_port eq 0
  in    reg,dx
  else
  add   dl,relative_port
  in    reg,dx
  sub   dl,relative_port
  endif
  endm



;----------------------------------------------------------------------------
;
;       set remote info mode
;
;----------------------------------------------------------------------------
; PRECONDITION:
;
;       EAX BIT 12..23  = 0  :  remote info off
;
;       EAX BIT 12..23  > 0  :  8250 port base address
;       EAX BIT  8..10       :  baud rate index
;       EAX BIT  0..5        :  line control register
;
;             DS    phys mem
;
;             kernel debug available
;
;----------------------------------------------------------------------------

  assume ds:codseg


set_remote_info_mode:

  push  ds
  pushad
  pushfd

  cli
  push  phys_mem
  pop   ds

  mov   edx,eax
  shr   edx,12
  and   dx,0FFFh
  mov   [remote_info_port],dx

        mov   ebx,eax                      ; set LCR and baud rate divisor
        and   al,3Fh                       ;
        or    al,80h                       ;
        outdx sio_lcr,al                   ;
        mov   eax,ebx                      ;
        shr   eax,8                        ;
        and   eax,07h                      ;
        mov   ax,[(eax*2)+rate_divisor]    ;
        outdx sio_dllow,al                 ;
        mov   al,ah                        ;
        outdx sio_dlhigh,al                ;
        mov   al,bl                        ;
        and   al,3Fh                       ;
        outdx sio_lcr,al                   ;

        indx  al,sio_iir                   ; reset 8250
        indx  al,sio_lsr                   ;
        indx  al,sio_iir                   ;
        indx  al,sio_rbr                   ;
        indx  al,sio_iir                   ;
        indx  al,sio_msr                   ;
        indx  al,sio_iir                   ;

        mov   al,0                         ; disable all 8250 interrupts
        outdx sio_ier,al                   ;

        mov   al,mcr_dtr+mcr_rts+mcr_enable
        outdx sio_mcr,al

  popfd                                    ; Rem: change of NT impossible
  popad
  pop   ds
  ret


;----------------------------------------------------------------------------
;
;       remote outchar
;
;----------------------------------------------------------------------------
; PRECONDITION:
;
;       AL    char
;
;       DS    phys mem
;
;----------------------------------------------------------------------------


remote_outchar:

  push  eax
  push  edx

  mov   ah,al
  mov   dx,[remote_info_port]
  IFNZ  dx,0
        DO
              indx  al,sio_lsr
              test  al,lsr_tsr_empty
              REPEATZ
        OD
        mov   al,ah
        outdx sio_thr,al
  FI

  pop   edx
  pop   eax
  ret




vt100_control:

  push  eax
  mov   al,27
  call  remote_outchar
  mov   al,'['
  call  remote_outchar
  pop   eax
  call  remote_outchar
  ret




remote_outdec8:

  IFAE  al,10
        push  eax
        push  edx
        mov   ah,0
        mov   dl,10
        div   dl
        push  eax
        call  remote_outdec8
        pop   eax
        mov   al,ah
        call  remote_outdec8
        pop   edx
        pop   eax
        ret
  FI

  push  eax
  add   al,'0'
  call  remote_outchar
  pop   eax
  ret




;----------------------------------------------------------------------------
;
;       remote incharety
;
;----------------------------------------------------------------------------
; PRECONDITION:
;
;       DS    phys mem
;
;----------------------------------------------------------------------------
; POSTCONDITION:
;
;       EAX   -1    iff (remote info mode = off OR no input char available)
;
;       EAX   char  else
;
;----------------------------------------------------------------------------


remote_incharety:

  push  edx

  mov   dx,[remote_info_port]
  IFNZ  dx,0
        indx  al,sio_lsr
        test  al,lsr_receiver_full
        IFNZ
              indx  al,sio_rbr
              movzx eax,al
        FI
  FI
  IFZ
        mov   eax,-1
  FI

  pop   edx
  ret


  dcod ends


  code  ends
  end
