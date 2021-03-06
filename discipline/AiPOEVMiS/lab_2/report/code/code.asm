;; macro for memory initialization
;; di = len1-1+offset mem1
;; si = len2-1+offset mem2
;; cx = min(len1, len2)
Init	macro   mem1,len1,mem2,len2
    local _assign_len1_,_assign_len2_,_end_
    push    ax
    push    dx
        
    mov     ax, len1            
    sub     ax,1
    add     ax, offset mem1
    mov	    di,ax
        
    mov     dx, len2            
    sub     dx, 1
    add     dx, offset mem2      
	mov	    si,dx

    mov     ax, len1
    cmp     ax, len2            
    jg      _assign_len2_     

_assign_len1_:
    mov     cx, len1
    jmp     _end_
        
_assign_len2_:
    mov     cx, len2
    jmp     _end_

_end_:
    pop     dx
    pop     ax    
    endm

;; ax = length of essential part BCD number
LenBCD      macro mem,len_mem,pos_dot, max_size
            local _start_zero_,_end_
        
    mov     si, offset mem
    mov     cx, max_size
    call    LenBCDp

    cmp     ax, pos_dot
    je      _start_zero_
    jmp     _end_
        
_start_zero_:
    inc     ax
    jmp     _end_

_end_:  
    mov     len_mem, ax    
    endm

;; Check, if BCD number is equal to zero, and place result in CF
IsZeroBCD      macro mem,len
    mov     si, offset mem
    mov     cx, len
    call    IsZeroBCDp
    endm
        
;; Align position of BCD number by
;; right border of memory:
;; [12343---] => [---12343]
AlignBCD    macro mem,len,max_size
    Init    mem,max_size,mem,len
    mov     cx, len
    call    CpBCDp

    mov     di, offset mem
    ;; cx = max_size - len
    mov     cx, max_size
    sub     cx, len    
    call    SetZerop
    endm
        
; Copy mem2 to mem1
CpBCD   macro   mem1,mem2,max_size
    Init mem1,max_size,mem2,max_size   
    call CpBCDp
    endm

;; Addition of BCD numbers
;; Store result of addition in mem1
;; 
;; In:
;; mem1 -- first operand
;; sign1 -- sign of first operand
;; pos_dot1 -- position of dot in first operand
;; 
;; mem2 -- second operand
;; sign2 -- sign of second operand
;; pos_dot2 -- position of dot in second operand 
;;
;; max_size -- maximal size of mem1 and mem2
;; 
;; Out: 
;; len_mem1 -- essential part length of mem1 (result)
AddBCD	macro	mem1,len_mem1,sign1,pos_dot1, mem2,len_mem2,sign2,pos_dot2, max_size
        local _compare_signs_,_signs_equal_,_signs_not_equal_,_mem1_gz_mem2_,_mem1_lz_mem2,_rest1_gz_rest2_,_rest1_lz_rest2_,_corrections_,_end_
        
    ;; adjust bcd by dot pos
    mov     ax, pos_dot1
    mov     dx, pos_dot2
    cmp     ax, dx
    jg      _rest1_gz_rest2_
    jl      _rest1_lz_rest2_

    CpBCD   mem_overhead,mem2,max_size    
    jmp     _compare_signs_
        
_rest1_gz_rest2_:
    ;; pos_dot1 > pos_dot2  

    mov     di, offset mem_overhead
    mov     cx, max_size
    call    SetZerop

    ;; si = offset mem2 - 1 + max_size
    mov     si, offset mem2
    add     si, max_size
    sub     si, 1

    ;; di = offset mem_overhead+max_size-(pos_dot1-pos_dot2)-1   
    mov     di, offset mem_overhead
    add     di, max_size
    add     di, pos_dot2
    sub     di, pos_dot1
    sub     di, 1

    mov     cx, len_mem2
    call    CpBCDp   
    jmp     _compare_signs_

_rest1_lz_rest2_:
    ;; pos_dot1 < pos_dot2  

    mov     di, offset mem_overhead
    mov     cx, max_size
    call    SetZerop

    ;; si = offset mem2 - 1 + max_size
    mov     si, offset mem1
    add     si, max_size
    sub     si, 1

    ;; di = offset mem_overhead+max_size-(pos_dot2 - pos_dot1)-1   
    mov     di, offset mem_overhead
    add     di, max_size
    sub     di, pos_dot2
    add     di, pos_dot1
    sub     di, 1

    mov     cx, len_mem1
    call    CpBCDp

    CpBCD   mem1, mem_overhead, max_size

    jmp     _compare_signs_ 
        
_compare_signs_: 
    mov     ah, sign1
    mov     al, sign2
    xor     ah, al
    cmp     ah, 0
       
    je      _signs_equal_
    jmp     _signs_not_equal_
        
_signs_equal_:
;; sign1 == sign2
;; mem1 = mem1 + mem2
;; sign1 = sign1
    Init	mem1,max_size,mem_overhead,max_size
	call	AddBCDp
    jmp     _corrections_

_signs_not_equal_:      
;; sign1 != sign2
;; mem1 = max(mem1, mem2) - min(mem1, mem2)
;; sign1 = sign(max(mem1, mem2))
    mov     di, offset mem1
    mov     si, offset mem_overhead
    mov     cx, max_size
    call    CmpBCDp
    jc      _mem1_gz_mem2_
    jmp     _mem1_lz_mem2_
        
_mem1_gz_mem2_:      
    Init	mem1,max_size,mem_overhead,max_size
	call	SubBCDp
    jmp     _corrections_
        
_mem1_lz_mem2_:
    mov al, sign2
    mov sign1, al
         
    Init	mem_overhead,max_size,mem1,max_size
	call	SubBCDp
    CpBCD   mem1,mem_overhead,max_size
        
    jmp     _corrections_
        
_corrections_:        
    LenBCD  mem1,len_mem1,pos_dot1,max_size
        
    ;; check, if result == 0, and set sign to 0
    IsZeroBCD mem1,max_size
    jnc     _end_
    mov     sign1, 0
    jmp     _end_
        
_end_:       
	endm

;; Subtraction of BCD numbers
;; Store result of subtraction in mem1
;; 
;; In:
;; mem1 -- first operand
;; sign1 -- sign of first operand
;;
;; mem2 -- second operand
;; sign2 -- sign of second operand
;;
;; max_size -- maximal size of mem1 and mem2
;; 
;; Out: 
;; len_mem1 -- essential part length of mem1 (result)        
SubBCD	macro	mem1,len_mem1,sign1,pos_dot1, mem2,len_mem2,sign2,pos_dot2, max_size
        local   _compare_signs_,_signs_equal_,_signs_not_equal_,_mem1_gz_mem2_,_mem1_gz_mem2_gz_0_,_mem1_lz_mem2_lz_0_,_mem1_lz_mem2,_mem1_lz_mem2_,_mem2_gz_mem1_gz_0_,_mem2_lz_mem1_lz_0_,_mem1_sub_mem2_,_mem2_sub_mem1_,_corrections_,_end_

    ;; adjust bcd by dot pos
    mov     ax, pos_dot1
    mov     dx, pos_dot2
    cmp     ax, dx
    jg      _rest1_gz_rest2_
    jl      _rest1_lz_rest2_

    CpBCD   mem_overhead,mem2,max_size    
    jmp     _compare_signs_
        
_rest1_gz_rest2_:
    ;; pos_dot1 > pos_dot2  

    mov     di, offset mem_overhead
    mov     cx, max_size
    call    SetZerop

    ;; si = offset mem2 - 1 + max_size
    mov     si, offset mem2
    add     si, max_size
    sub     si, 1

    ;; di = offset mem_overhead+max_size-(pos_dot1-pos_dot2)-1   
    mov     di, offset mem_overhead
    add     di, max_size
    add     di, pos_dot2
    sub     di, pos_dot1
    sub     di, 1

    mov     cx, len_mem2
    call    CpBCDp   
    jmp     _compare_signs_

_rest1_lz_rest2_:
    ;; pos_dot1 < pos_dot2  

    mov     di, offset mem_overhead
    mov     cx, max_size
    call    SetZerop

    ;; si = offset mem2 - 1 + max_size
    mov     si, offset mem1
    add     si, max_size
    sub     si, 1

    ;; di = offset mem_overhead+max_size-(pos_dot2 - pos_dot1)-1   
    mov     di, offset mem_overhead
    add     di, max_size
    sub     di, pos_dot2
    add     di, pos_dot1
    sub     di, 1

    mov     cx, len_mem1
    call    CpBCDp

    CpBCD   mem1, mem_overhead, max_size

    jmp     _compare_signs_ 
        
_compare_signs_: 
    mov     ah, sign1
    mov     al, sign2
    xor     ah, al
    cmp     ah, 0
    je      _signs_equal_
    jmp     _signs_not_equal_
   
_signs_not_equal_:      
;; sign1 != sign2
;; mem1 = max(mem1, mem2) - min(mem1, mem2)
;; sign1 = sign(max(mem1, mem2))
    Init	mem1,max_size,mem_overhead,max_size
	call	AddBCDp
    jmp     _corrections_
     
_signs_equal_:
;; sign1 == sign2
;; mem1 = mem1 + mem2
;; sign1 = sign1
    mov     di, offset mem1
    mov     si, offset mem_overhead
    mov     cx, max_size
    call    CmpBCDp
    jc      _mem1_gz_mem2_
    jmp     _mem1_lz_mem2_

;; by absolute value        
_mem1_gz_mem2_:                 
    mov     al, sign2                
    cmp     al, 0
    je      _mem1_gz_mem2_gz_0_
    jmp     _mem1_lz_mem2_lz_0_       

;; by absolute value
_mem1_lz_mem2_:
    mov     al, sign2
    mov     al, 0
    je      _mem2_gz_mem1_gz_0_
    jmp     _mem2_lz_mem1_lz_0_       
        
_mem1_gz_mem2_gz_0_:
_mem1_lz_mem2_lz_0_:              
    jmp     _mem1_sub_mem2_

_mem2_gz_mem1_gz_0_:
    mov     sign1, 1
    jmp     _mem2_sub_mem1_

_mem2_lz_mem1_lz_0_:
    mov     sign1, 1
    jmp     _mem2_sub_mem1_
  
_mem1_sub_mem2_:     
    Init	mem1,max_size,mem_overhead,max_size
	call	SubBCDp
    jmp     _corrections_

_mem2_sub_mem1_:
    Init	mem_overhead,max_size,mem1,max_size
	call	SubBCDp
    CpBCD   mem1,mem_overhead,max_size
        
    jmp     _corrections_
        
_corrections_:  
    LenBCD  mem1,len_mem1,pos_dot1,max_size

    IsZeroBCD mem1,max_size
    jnc     _end_
    mov     sign1, 0
    jmp     _end_
    
_end_:          
	endm

;; Multiplication of BCD numbers
;; Store lower part of result in mem1,
;; higher part --- in mem2 
;; 
;; In:
;; mem1 -- first operand
;; sign1 -- sign of first operand
;;
;; mem2 -- second operand
;; sign2 -- sign of second operand
;;
;; max_size -- maximal size of mem1 and mem2
;; 
;; Out: 
;; len_mem1 -- essential part length of mem1 (result)        
MulBCD	macro	mem1,len_mem1,sign1,pos_dot1, mem2,len_mem2,sign2,pos_dot2, max_size
        local   _mul_,_end_
    ;; determine sign of result
    mov     ah, sign1
    mov     al, sign2
    xor     ah, al
    mov     sign1, ah

    ;; determine dot position of result
    mov     ax, pos_dot1
    add     ax, pos_dot2
    mov     pos_dot1, ax
        
_mul_:  
    ;; copy mem2 number to temporary place
    CpBCD   mem_overhead,mem2,max_size 

    Init	mem1,max_size,mem_overhead,max_size
	call	MulBCDp

    LenBCD  mem1,len_mem1,pos_dot1,max_size

    IsZeroBCD mem1,max_size
    jnc     _end_
    mov     sign1, 0
    jmp     _end_

_end_:  
	endm

;; Division of BCD numbers
;; Store result of division in mem1,
;; rest --- in mem2 
;; 
;; In:
;; mem1 -- first operand
;; sign1 -- sign of first operand
;;
;; mem2 -- second operand
;; sign2 -- sign of second operand
;;
;; max_size -- maximal size of mem1 and mem2
;; 
;; Out: 
;; len_mem1 -- essential part length of mem1 (result)        
DivBCD	macro	mem1,len_mem1,sign1,pos_dot1, mem2,len_mem2,sign2,pos_dot2, max_size
        local   _div_,_end_
    ;; determine sign of result
    mov     ah, sign1
    mov     al, sign2
    xor     ah, al
    mov     sign1, ah

    ;; TODO: determine dot position of result
    ;; mov     ax, pos_dot1
    ;; sub     ax, pos_dot2
    ;; mov     pos_dot1, ax
        
_div_:  
    ;; copy mem2 number to temporary place
    CpBCD   mem_overhead,mem2,max_size
	mov	    di,offset mem1
	mov	    si,offset mem_overhead
	mov	    cx,max_size
	call	DivBCDp

    LenBCD  mem1,len_mem1,pos_dot1, max_size

    IsZeroBCD mem1,max_size
    jnc     _end_
    mov     sign1, 0
    jmp     _end_

_end_:  
	endm

;; Print single character stored in al
OutChar macro char        
    push    ax
    push    dx
    mov     ah, 02h           
    mov     dl,char
    int     21h
    pop     dx
    pop     ax
    endm

;; Print characater string,
;; start address stored in dx
OutStr macro str
    push    ax
    push    dx
    mov     ah, 09h
    mov     dx, offset str
    int     21h
    pop     dx
    pop     ax
    endm

;; Print BCD-number to screen with dot and sign       
OutBCD	macro	mem,max_size,len,pos_dot,sign
        local _minus_,_out_,_integer_,_rational_,_end_
    push    ax
        
    mov     al, sign
    cmp     al, 1
    je      _minus_
    jmp     _out_

_minus_:
    mov     al, 45
    OutChar al
    jmp     _out_

_out_:      
    mov     ax, pos_dot
    cmp     ax, 0
    je      _integer_       
    jmp     _rational_    
        
_integer_:     
    ;; si = (offset mem) + (max_size - len)
    ;; cx = len
    mov     ax, offset mem
    add     ax, max_size
    sub     ax, len
    mov     si, ax
        
    mov     cx, len
        
	call	OutBCDp
    jmp     _end_
        
_rational_:
    ;; print integer part
    ;; si = (offset mem) + (max_size - len)
    ;; cx = len - pos_dot    
    mov     ax, offset mem
    add     ax, max_size
    sub     ax, len
    mov     si, ax

    mov     cx, len
    sub     cx, pos_dot
    call    OutBCDp

    ;; print dot
    mov     al, 46
    OutChar al

    ;; print rest part
    ;; si = (offset mem) + (max_size - pos_dot)
    ;; cx = pos_dot    
    mov     ax, offset mem
    add     ax, max_size
    sub     ax, pos_dot
    mov     si, ax

    mov     cx, pos_dot
    call    OutBCDp
        
_end_:
    OutStr  newline
    pop     ax    
	endm

;; Write BCD-number as string to mem_buffer with dot and sign
;; Set mem_buffer_len = length(str(BCD-number))
BCD2Str	macro	mem,max_size,len,pos_dot,sign, mem_buffer,mem_buffer_len
        local   _minus_,_out_,_integer_,_rational_,_end_
    push    ax
    push    dx                  ; number of wrote chars
        
    xor     dx, dx    
    mov     di, offset mem_buffer
        
    mov     al, sign
    cmp     al, 1
    je      _minus_
    jmp     _out_

_minus_:
    mov     al, 45
    stosb
    inc     dx    
    jmp     _out_

_out_:      
    mov     ax, pos_dot
    cmp     ax, 0
    je      _integer_       
    jmp     _rational_    
        
_integer_:     
    ;; si = (offset mem) + (max_size - len)
    ;; cx = len
    mov     ax, offset mem
    add     ax, max_size
    sub     ax, len
    mov     si, ax
    mov     cx, len

	call	BCD2Strp            ; don't change dx

    jmp     _end_
        
_rational_:
    ;; print integer part
    ;; si = (offset mem) + (max_size - len)
    ;; cx = len - pos_dot    
    mov     ax, offset mem
    add     ax, max_size
    sub     ax, len
    mov     si, ax

    mov     cx, len
    sub     cx, pos_dot
    call    BCD2Strp

    ;; print dot
    mov     al, 46
    stosb
    inc     dx
        
    ;; print rest part
    ;; si = (offset mem) + (max_size - pos_dot)
    ;; cx = pos_dot    
    mov     ax, offset mem
    add     ax, max_size
    sub     ax, pos_dot
    mov     si, ax

    mov     cx, pos_dot
    call    BCD2Strp
        
_end_:
    add     dx, len
    mov     mem_buffer_len, dx
        
    pop     dx
    pop     ax
	endm
        
; Input single character to al        
InChar  macro
        mov	    ah,08h
        int	    21h
        endm

;; Input BCD number to memory
;;
;; In:
;; mem -- place in memory to store number
;; len_input -- maximal length of user input
;; max_size -- maximal size of mem
;;
;; Out:
;; len_read -- length of essential part of number
;; pos_dot -- position of dot, numbered from higher digits 
;; sign -- sign of number
InBCD	macro	mem,len_input,max_size,len_read,pos_dot,sign
	mov	    di,offset mem
	mov	    cx,len_input
	call	InBCDp
    mov     len_read, ax
    mov     pos_dot, bx
    mov     sign, dl

    AlignBCD mem,len_read,max_size
	endm

;; Print main menu 
OutMenu macro
    OutStr  slct_prmpt

    OutStr  var_cf
    OutStr  var_fc
    OutStr  var_quit
    OutStr  newline
    endm

;; Create new file
;; if already exists, truncate it
;; Put in f_handle new file handler
NewFile macro f_name,f_handle
    mov     ah, 3ch
    mov     cx, 0
    mov     dx, offset f_name
    int     21h
    mov     f_handle, ax    
    endm
        
;; Close file with file_handle       
CloseFile macro f_handle
    push    bx
    mov     ah, 3eh
    mov     bx, f_handle
    int     21h
    pop     bx
    endm

;; Write string to file using f_handle
OutFStr macro   f_handle,str,len_str
    mov     ah, 40h
    mov     bx, f_handle
    mov     cx, len_str
    mov     dx, offset str
    int     21h
    endm

OutFBCD macro f_handle, mem,max_size,mem_len,pos_dot,sign, mem_buffer,mem_buffer_len
    BCD2Str     mem,max_size,mem_len,pos_dot,sign, mem_buffer,mem_buffer_len
    OutFStr     f_handle,mem_buffer,mem_buffer_len        
    endm
        
stk segment stack
stk ends
        
data	segment
CR          equ     0Dh
LF          equ     0Ah
EOS         equ     '$'
;; maximal memory size used to store numbers
len_mem     equ     20
;; maximal length of user input
len_input   equ     10
;; maximal memory size used to store number size values
len_size    equ     2                       

newline     db  CR, LF, EOS
len_newline dw  2               ; without EOS
        
prg_desc_1  db  'This program can be used to convert temperature', CR, LF, EOS
prg_desc_2  db  'beetween Celsius and Farengheit scales.', CR, LF, EOS
slct_prmpt  db  'Select direction of convertation (1,2), or press q to exit', CR, LF, EOS  

var_cf      db  '1) Convert Celsius to Farengheit', CR, LF, EOS
var_fc      db  '2) Convert Farengheit to Celsius', CR, LF, EOS
var_quit    db  'q) Quit from program', CR, LF, EOS
        
cf_prpmt    db  'Input temperature level by Celsius scale', CR, LF, EOS
cf_answer   db  'Temperature level by Farengheit scale is: ', EOS
fc_prpmt    db  'Input temperature level by Farengheit scale', CR, LF, EOS     
fc_answer   db  'Temperature level by Celsius scale is: ', EOS        
in_prpmt    db  '(for example, -12345.6789) and press <Enter>: ', EOS

c_i_log     db  'Input (Celsius): '
len_c_i_log dw  $-c_i_log

c_o_log     db  'Output (Celsius): '
len_c_o_log dw  $-c_o_log

f_i_log     db  'Input (Fahrengheit): '
len_f_i_log dw  $-f_i_log

f_o_log     db  'Output (Fahrengheit): '
len_f_o_log dw  $-f_o_log      
        
f_name      db  'C:\result\result.txt',00
f_handle    dw  1 dup(?)
        
; input value
a	        db	len_mem dup(?)
; length of essential part
len_a       dw  0
; dot position
pos_a       dw  0
; sign (0 -- plus, 1 -- minus)
sign_a      db  0                      

; addition
b           db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,2
; length of essential part
len_b       dw  2                      
; dot position
pos_b       dw  0
; sign (0 -- plus, 1 -- minus)
sign_b      db  0

; first coefficient
k1          db  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,5
; length of essential part
len_k1      dw  1                      
; dot position
pos_k1      dw  0
; sign (0 -- plus, 1 -- minus)
sign_k1     db  0
        
; second coefficient
k2          db   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9
; length of essential part
len_k2      dw  1                      
; dot position
pos_k2      dw  0
; sign (0 -- plus, 1 -- minus)
sign_k2     db  0
        
; additional memory for mul and div purpouses
mem_overhead db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0        
buffer       db  512 dup(?)

; special buffer for bcd->str convertion purpouses
len_mem_cnv  equ len_mem+2
mem_cnv      db len_mem_cnv dup(?)
len_cnv      dw 0
        
data	    ends

code	    segment
.386
assume	    cs:code,ds:data,es:data

;; Send bytes from si to di cx times
CpBCDp proc
    std
rep movsb
    ret
    endp

;; Fill specified part of memory with zeros
;; Size of memory specified in cx
SetZerop proc
    cld
    push    ax
    mov     al, 0
rep stosb 
    pop     ax
    ret
    endp

;; Check, if BCD is equal to zero
;; Set CF=1, if true, CF=0 otherwise 
IsZeroBCDp proc
    push    ax
    cld
_is_zero_loop_:  
    lodsb
    cmp     al, 0
    jne     _is_zero_false_
    loop    _is_zero_loop_
        
    jmp     _is_zero_true_

_is_zero_true_:
    stc    
    jmp _is_zero_end_
        
_is_zero_false_:        
    clc                         
    jmp _is_zero_end_

_is_zero_end_:
    pop ax
    ret
    endp
        
;; Determine essential part size of BCD number
;; Store result in ax 
LenBCDp proc
    cld
       
_len_next_:
    lodsb
    cmp     al, 0
    jne     _len_end_           ; first essential digit
    loop    _len_next_

_len_end_:  
    mov     ax, cx
    ret
    endp

;; Add two BCD numbers without signs
AddBCDp	proc
	push	ax	
	push	di
	push	si
	push	cx
	std		
	clc		
_add_:
	lodsb		
	adc	al,[di]	
	aaa		
	stosb	
	loop	_add_
	pop	cx	
	pop	si
	pop	di
	pop	ax
	ret
	endp

;; Subtract two BCD numbers without signs        
SubBCDp	    proc
	push	ax	
	push	di
	push	si
	push	cx
	std		
	clc		
_sub_:
	lodsb	
	sbb	    [di],al	
	mov	    al,[di]
	aas		
	stosb	
	loop	_sub_
	pop	    cx
	pop	    si
	pop	    di
	pop	    ax
	ret
	endp

;; Multiplicate two BCD numbers without signs
MulBCDp	proc
	push	ax
	push	bx
	push	di
	push	si
	push	cx
	std		
	mov	    bx,offset buffer
	mov	    dh,cl
	push	bx
	shl	    cx,1	
	xor	    al,al	

_null_:
	mov	    [bx],al
	inc	    bx
	loop	_null_
	mov	    cl,dh
	pop	    bx

_mul_o_:
	xor	    dl,dl
	push	cx
	push	bx	
	push	si
	mov	    cl,dh

_mul_i_:
	lodsb	
	mul	    byte ptr [di]
	aam
	add	    al,dl
	aaa
	add	    al,[bx]	
			        
	aaa
	mov	    dl,ah	
	xor	    ah,ah
	mov	    [bx],al	
	inc	    bx
	loop	_mul_i_
	mov	    [bx],dl
	pop	    si	
	pop	    bx
	inc	    bx
	dec	    di	

	pop	    cx
	loop	_mul_o_
	mov	    cl,dh
	sub	    bx,cx
	add	    di,cx

_move_l_:
	mov	    al,[bx]
	inc	    bx
	stosb
	loop	_move_l_
	mov	    cl,dh
	mov	    di,si

_move_h_:
	mov	    al,[bx]
	inc	    bx
	stosb
	loop	_move_h_
	pop	    cx
	pop	    si
	pop	    di
	pop	    bx
	pop	    ax
	ret
	endp

SubInvBCDp	proc
	push	si
	push	di
	add 	si,cx
	dec	    si
	add	    di,cx
	dec	    di
	call	SubBCDp
	pop	    di
	pop	    si
	ret
	endp

;; Compare two BCD numbers
;; Set CF=0, if [si]>[di], else CF=1
CmpBCDp	proc
	push	ax
	push	di
	push	si
	push	cx
	cld
_cmp_:
	lodsb
	cmp	al,[di]
	jl	    _less_
	jg	    _greater_
	inc	    di
	loop	_cmp_
_less_:
	stc
	jc	    _cmp_q_
_greater_:
	clc
_cmp_q_:
	pop	    cx
	pop	    si
	pop	    di
	pop	    ax
	ret
	endp

PrepareForDiv	proc
	cld
    ;; 0,[di] -> buffer
	push	di
	push	si
	push	di
	pop	    si
	mov	    di,offset buffer
	xor	    al,al
	push	cx
	stosb
	rep	    movsb
    ;;  0,[si] -> buffer
	pop	    cx
	stosb
	pop	    si
	push	cx
        
_find_:
	lodsb
	dec	    cx
	cmp	    al,0
	je	    _find_
	dec	    si
	inc	    cx
	mov	    dx,cx
	rep     movsb
	pop	    cx
	push	cx

    ;; 0,0..0 -> buffer 
	xor	    al,al
	rep	    stosb

    ;; reassign registers
	mov	    di,offset buffer
	pop	    cx
	mov	    si,di
	inc	    cx
	add	    si,cx
	pop	    bx
	ret
	endp

;; Divide two BCD numbers
DivBCDp	proc
	push	ax	
	push	bx
	push	di
	push	si
	push	cx
	push	di
	call	PrepareForDiv	
	xor	    ax,ax	
	call	CmpBCDp
	jnc	    _next_1_
_div_:
	call	CmpBCDp
	jnc	    _next_
	inc	    al
	call	SubInvBCDp
	jmp	    _div_
_next_:
	mov	    [bx],al
	inc	    bx	
_next_1_:
	inc	    di
	dec	    cx
	xor	    al,al
	inc	    ah
	cmp	    cx,dx	
	jne	    _div_
	dec	    ah
	pop	    di
	pop	    cx
	push	cx
	mov	    si,di
	add	    di,cx
	push	cx
	mov	    cl,ah
	add	    si,cx
	dec	    si
	dec	    di
	std
rep	movsb
	pop	    cx
	sub	    cl,ah
	xor	    al,al
rep	stosb
	pop	    cx
	pop	    si
	push	si
	push	cx
	mov	    di,si
	mov 	si,offset buffer
	inc	    si
	cld
rep	movsb
	pop	    cx	
	pop	    si
	pop	    di
	pop	    bx
	pop	    ax
	ret
	endp
        
OutBCDp	proc
	mov	    ah,06h
	cld
_outbcd_out_:
	lodsb
	or	    al,30h
	mov	    dl,al
	int	    21h
	loop	_outbcd_out_
	ret
	endp

BCD2Strp	proc
	mov	    ah,06h
	cld
_bcd2str_out_:
	lodsb
	or	    al,30h
    stosb
	loop	_bcd2str_out_
	ret
	endp

        
InBCDp	proc
	cld 
    mov     dx, 0                  
    mov     bx, 0                  
    mov     si, 0
_in_:
    InChar
    cmp     al, 0                  
    je      _extended_
    cmp     al, 13                 
    je      _success_ 
    cmp     al, 113                 ; q
    je      _error_
    cmp     al, 81                  ; Q
    je      _error_
    cmp     al, 45                  ; got -
    je      _minus_
    cmp     al,46                   ; got .
    je      _dot_
    cmp     al, 30h                 ; got char with code <= 30h
    jl      _not_digit_
    cmp     al, 3Ah                 ; got char with code >= 40h
    jge     _not_digit_
    jmp     _digit_
        
_digit_:
    OutChar al
        
    sub	    al,30h
    stosb

    inc     dx
    jmp     _loop_

_loop_:
	loop	_in_
    jmp     _success_               ; goto success if cx = 0
        
_not_digit_:
    inc     cx
    jmp     _loop_

_minus_:
    inc     cx
        
    cmp     si, 0                
    jne     _loop_
        
    cmp     dx, 0                
    jne     _loop_

    OutChar al
    mov     si,1
    jmp     _loop_    

_dot_:
    inc     cx
    cmp     dx, 0                 
    je      _loop_
        
    cmp     bx, 0                 
    jne     _loop_

    OutChar al
    mov     bx, dx
    jmp     _loop_
        
_success_:
    mov     ax, dx
    cmp     bx, 0
    jne     _correct_pos_dot_
    jmp     _exit_

_correct_pos_dot_:
     sub    dx, bx
     mov    bx, dx
     jmp    _exit_
        
_extended_:
    InChar
    jmp     _loop_
        
_error_:
    mov     ax, 0
    jmp     _exit_

_exit_:
    mov     dx, si    
    OutStr newline                
    ret
	endp
        
main	proc
	mov	    ax,data
	mov	    ds,ax
	mov	    es,ax

_begin_:
    NewFile  f_name,f_handle
    OutStr  prg_desc_1
    OutStr  prg_desc_2
    OutStr  newline

_main_menu_:    
    OutMenu

_main_menu_choose_variant_:     
    InChar                      ; Choose variant
    cmp al, 31h                 ; '1'
    je _cf_
    cmp al, 32h                 ; '2'
    je _fc_
    cmp al, 113                 ; q
    je _end_    
    cmp al, 81                  ; Q
    je _end_
    jmp _main_menu_choose_variant_
        
_cf_:                           ; Celsius to Farengheit
    OutStr  cf_prpmt
    OutStr  in_prpmt

    OutFStr f_handle,c_i_log,len_c_i_log
        
    InBCD   a, len_input,len_mem, len_a,pos_a,sign_a
        
    cmp     len_a, 0            ; length of input is 0
    je      _main_menu_

    OutFBCD f_handle, a,len_mem,len_a,pos_a,sign_a, mem_cnv,len_cnv
    OutFStr f_handle,newline,len_newline      
        
   	MulBCD	a,len_a,sign_a,pos_a, k2,len_k2,sign_k2,pos_k2, len_mem ; *9       
    DivBCD  a,len_a,sign_a,pos_a, k1,len_k1,sign_k1,pos_k1, len_mem  ; /5
    AddBCD  a,len_a,sign_a,pos_a, b,len_b,sign_b,pos_b, len_mem ; +32
        
    OutStr  cf_answer
    OutBCD  a,len_mem,len_a,pos_a,sign_a        
    OutStr  newline

    OutFStr f_handle, f_o_log,len_f_o_log    
    OutFBCD f_handle, a,len_mem,len_a,pos_a,sign_a, mem_cnv,len_cnv
    OutFStr f_handle, newline,len_newline

    OutFStr f_handle, newline,len_newline   
    jmp     _main_menu_
        
_fc_:                            ; Farengheit to Celsius
    OutStr  fc_prpmt
    OutStr  in_prpmt

    OutFStr f_handle, f_i_log,len_f_i_log
                
    InBCD   a,len_input,len_mem,len_a,pos_a,sign_a
        
    cmp     len_a, 0            ; length of input is 0
    je      _main_menu_

    OutFBCD f_handle, a,len_mem,len_a,pos_a,sign_a, mem_cnv,len_cnv
    OutFStr f_handle, newline,len_newline      
        
    SubBCD  a,len_a,sign_a,pos_a, b,len_b,sign_b,pos_b, len_mem   ; -32 
    MulBCD  a,len_a,sign_a,pos_a, k1,len_k1,sign_k1,pos_k1, len_mem  ; *5
    DivBCD	a,len_a,sign_a,pos_a, k2,len_k2,sign_k2,pos_k2, len_mem  ; /9
        
    OutStr  fc_answer
    OutBCD  a,len_mem,len_a,pos_a,sign_a
    OutStr  newline

    OutFStr f_handle, c_o_log,len_c_o_log    
    OutFBCD f_handle, a,len_mem,len_a,pos_a,sign_a, mem_cnv,len_cnv
    OutFStr f_handle, newline,len_newline

    OutFStr f_handle, newline,len_newline        
    jmp     _main_menu_

_end_:
    CloseFile f_handle
        
	mov	    ax,4c00h
	int	    21h
    main	endp
code	ends
end	main
