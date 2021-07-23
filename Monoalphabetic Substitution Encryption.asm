org 100h   

jmp start        


;in encryption a->q, in decryption q->a
;              'abcdefghijklmnopqrstvuwxyz'  
table1      DB 'qwertyuiopasdfghjklzxcvbnm'   
table2      DB 'kxvmcnophqrszyijadlegwbuft' 
  
msg1        DB  'Enter the message: ', '$'      ;$ is end of string
msg2        DB  'Encrypted message: ', '$'
msg3        DB  'Decrypted message: ', '$'
n_line      DB  0DH,0AH,'$'                     ;for new line....0AH-> line feed, 0DH->carriage return
str         DB  128,?,128 DUP('$')              ;buffer string (Reserving a byte for buffer size, a byte for number of characters that are read and 128 byte initialized as $)
enc_str     DB  128 DUP('$')                    ;encrypted string
dec_str     DB  128 DUP('$')                    ;decrypted string



start:

           
; print message
LEA    DX, msg1      ;loading effective address of msg1 in DX to print it
MOV    AH, 09h       ;used in string display
INT    21h           ;call the interrupt handler


;scan input             ;0AH requires  this syntax:  str  DB  128,?,128 DUP('$') where 128->max buffer size
                        ;? is already read bytes and 128 dup('$') mean initialize 128 bytes with $
MOV    AH, 0AH          ;used to scan input from user
MOV    DX, offset str   ;will write in str
INT    21h              ;call the interrupt handler 
                        ;0AH doesn't put $ at the end of the string

; print new line
LEA    DX, n_line      ;new line \n , loading effective address of n_line in DX to print it
MOV    AH, 09h        ;string must end with $
INT    21h            ;call the interrupt handler      
           
                    
; encrypt:
LEA    BX, table1     ;Base register = effective address of table 1  
LEA    SI, str[2]     ;Source index = effective address of str+2 ,because characters are stored starting from 3rd byte
LEA    DI, enc_str    ;Destination index = effective address of enc_str
CALL   parse

                                          
; print message :
LEA    DX, msg2        ;loading effective address of msg2 in DX to print it
MOV    AH, 09h         ;used in string display
INT    21h             ;call the interrupt handler  


; print enc_str :
LEA    DX, enc_str     ;loading effective address of enc_str in DX to print it
MOV    AH, 09h         ;ah=09H used in string display(display string inside DX where DX contain offset address of string"string ends with $")
INT    21h             ;call the interrupt handler
MOV    [DI],0DH        ;[DI]= carriage return as it will be used in parse

; print new line :
LEA    DX, n_line      ;new line \n , loading effective address of n_line in DX to print it
MOV    AH, 09h         ;used in string display
INT    21h             ;call the interrupt handler
                
           
                
; decrypt:
LEA    BX, table2      ;Base register = effective address of table2
LEA    SI, enc_str     ;Source index = effective address of enc_str (source)
LEA    DI, dec_str     ;Destination index = effective address of dec_str (destination)
CALL   parse           ;call subroutine parse

               
; print message :
LEA    DX, msg3        ;loading effective address of msg3 in DX to print it
MOV    AH, 09h         ;used in string display
INT    21h             ;call the interrupt handler
              
; print dec_str :             
LEA    DX, dec_str     ;loading effective address of dec_str in DX to print it
MOV    AH, 09h         ;used in string display
INT    21h             ;call the interrupt handler

; print new line :
LEA    DX, n_line      ;loading effective address of n_line in DX to print it
MOV    AH, 09h         ;used in string display
INT    21h             ;call the interrupt handler to print string
           
           
; wait for any key...
mov AH, 0
int 16h                ;call the interrupt handler to wait for keystroke from keyboard
           
ret                    ;return 


; subroutine to encrypt/decrypt
; parameters: 
;             si - source address of string     
;             di - destination address of encrypted or decrypted string
;             bx - table to use.


;              'abcdefghijklmnopqrstvuwxyz'  
;              'qwertyuiopasdfghjklzxcvbnm'   
;              'kxvmcnophqrszyijadlegwbuft'

parse proc

next_char:
	CMP    [SI], 0DH      ; is it carriage return?
	JE     end_of_string
	CMP    [SI], ' '      ;if it is a space skip it
	JE     skip           
	
	MOV    AL, [SI]       
	CMP    AL, 'a'        ;if the input isnt between a and z then skip it
	JB     skip
	CMP    AL, 'z'
	JA     skip
	SUB    AL, 61H ;Subtracting 61 to get correct offset in tables example: a=61H so to get offset=0 we need 
	;to subtract 61h	
	; xlat algorithm: al = ds:[bx + unsigned al]
	XLAT                  
	MOV    [DI], AL       ;store encrypted or decrypted byte in (enc_str or dec_str)
	INC    DI

skip:
	INC    SI	
	JMP    next_char

end_of_string:
    MOV [SI],'$'         ;string end with $
                         
ret
parse endp


END