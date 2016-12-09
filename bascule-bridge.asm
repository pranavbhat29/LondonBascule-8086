//program to implement the bridge using 8255 interfacing
include io.h
.model small

d1 segment
pa equ 2400h
pb equ 2402h
pc equ 2404h
cw equ 2406h
shotimer db 0h
shitimer db 0h
caotimer db 0h
caitimer db 0h
padata db 0h
pbdata db 0h
pcdata db 0h
ic db 0h
opencheck db 0h
limit db ?
rlim db ?
slim db ?

msgl db 13,10,'***********************************************************************************************',13,10,0
msg1 db 13,10,'                         Welcome to the bridge programme operations',13,10,0
msg2a db 13,10,'Please enter the maximum limit on the bridge load :',0
msg2b db 13,10,'Please enter the restoring limit on bridge load :',0
msg2c db 13,10,'Please enter the shipstop carcount :',0
msg4 db 13,10,'Thank You for using team rocket systems.GOODBYE',13,10,0
msgw db 13,10,'Please stop the cars!!!!!!!!!!',13,10,0
msgs db 13,10,'Please stop the Ship',13,10,0
msgg db 13,10,'!!!!!!!!!!!! Press any key to stop the programme !!!!!!!!!!!!',13,10,0


d1 ends


s1 segment stack
    dw 40dup(?)
top label word
s1 ends


c1 segment

assume cs:c1,ds:d1,ss:s1


;***************************************************************************************************************************************
;;aim : to open the bridge once a ship enters the scene



iship proc
push  ax
push  dx

mov dx,pa
in al,dx
mov padata,al 

test padata,01h  ;to see if ship has come
jnz noiship    ;if ship has not come 
cmp timer,0h                                                                                ;;to see if ship has passed or not == 1 
                                                                                            ;;ship  is still passing and 0 if ship 
                                                                                            ;;already passed or not there in the signal
jnz rest                                                                                    ;;to reset timer
mov shitimer,01h                                                                             ;;if ship just entered
or pbdata,01h                                                                                ;;to open the bridge  ;;clockwise rotation
and pbdata,fdh
mov opencheck db 1h                                                                         ;;to stop anticlockwiserotation

mov al,pbdata
mov dx,pb
out dx,al                                                                                                                

jmp noiship

rest:
mov shitimer,00h                                                                             ;;if ship just crossed  
mov al,pbdata
mov dx,pb
out dx,al

noiship:
pop  dx
pop  ax
ret

iship ends

;*********************************************************************************************************************************************
;;aim : to increment the count as a car enters the bridge



incount proc
push  ax
push  dx

mov dx,pa
in al,dx
mov padata,al 

test padata,04h                                                                             ;to see if car has come
jnz noicar                                                                                  ;if car has not come 
cmp caitimer,0h                                                                             ;;to see if car has passed or not == 1 
                                                                                            ;;car  is still passing and 0 if ship 
                                                                                            ;;already passed or not there in the entry
jnz resti                                                                                   ;;to reset timer
mov caitimer,01h                                                                            ;;if car just entered
                                                                                ;;to increment car count
inc ic   

jmp noicar

resti:
mov caitimer,00h                                                                             ;;if car just crossed  
and padata,fbh                                                                               ;;avoid clockwise rotation
                                                                                            
noicar:
pop  dx
pop  ax
ret

incount ends
;*********************************************************************************************************************************************
aim : to decrement the count as a car exits the bridge 



ocount proc
push  ax
push  dx

mov dx,pa
in al,dx
mov padata,al 

test padata,08h                                                                             ;to see if car has come
jnz noocar                                                                                  ;if car has not come 
cmp caotimer,0h                                                                             ;;to see if car has passed or not == 1 
                                                                                            ;;car  is still passing and 0 if ship 
                                                                                            ;;already passed or not there in the exitgate
jnz resti                                                                                   ;;to reset timer
mov caotimer,01h                                                                             ;;if car just entered exitgate
or padata,8h                                                                                ;;to decrement car count
dec ic   
                                                                                                               

jmp noocar

resti:
mov caotimer,00h                                                                             ;;if car just crossed  
and padata,f7h                                                                              
                                                                                            
noocar:
pop  dx
pop  ax
ret

ocount ends
;********************************************************************************************************************************************
aim : to stop entering cars into the bridge once the count exceeds certain value



weight proc
push ax
push dx

mov al,limit
cmp ic,al
jnge ignore

or pbdata,8h
output msgw                                                                                  ;;to set the car traffic light on
jmp term

ignore:
mov al,ic
cmp al,rlim
jg term
and pbdata,f7h                                                                                ;;to reset car traffic light off

term:

mov al,pbdata
mov dx,pb                                                                                         ;;perform port
out pb,al
 
pop dx
pop ax
weight ends

;*******************************************************************************************************************************************
aim : to  stop cars from entering the bridge if it is open



coming proc
push ax
push dx

cmp opencheck,01h 
jnz ignore

or pbdata,8h
output msgw                                                                                  ;;to set the car traffic light on
jmp term

ignore:
and pbdata,f7h                                                                                ;;to reset car traffic light off

term:

mov al,pbdata
mov dx,pb                                                                                         ;;perform port
out pb,al
 
pop dx
pop ax
coming ends

;*********************************************************************************************************************************************
;;aim : to close the bridge once the ship goes away 



oship proc
push  ax
push  dx


mov dx,pa
in al,dx
mov padata,al 

test padata,02h  ;to see if ship has come
jnz nooship    ;if ship has not come 
cmp timer,0h                                                                                ;;to see if ship has passed or not == 1 
                                                                                            ;;ship  is still passing and 0 if ship 
                                                                                            ;;already passed or not there in the signal
jnz restos                                                                                    ;;to reset timer
mov shotimer,01h                                                                             ;;if ship just entered exit gate
                                                                         

mov al,pbdata
mov dx,pb
out dx,al                                                                                                                

jmp nooship

restos:
mov shotimer,00h                                                                             ;;if ship just crossed  
and pbdata,feh                                                                              ;;avoid clockwise rotation
or pbdata,02h                                                                               ;;start clockwise rotation
mov opencheck,00h                                                                           ;;bring-back bridge and close lite


mov al,pbdata
mov dx,pb
out dx,al

nooship:
pop  dx
pop  ax
ret

oship ends

;*******************************************************************************************************************************************
;;aim - to stop the ship if bridge is closed due to traffic on it(congestion control)


shipstop proc
push ax
push dx

mov al,ic
cmp ic,slim 
jnge ignore

or pbdata,04h
output msgs                                                                                  ;;to set the ship traffic light on
jmp term

ignore:
and pbdata,fbh                                                                                ;;to reset ship traffic light off

term:

mov al,pbdata
mov dx,pb                                                                                         ;;perform port
out pb,al
 
pop dx
pop ax
coming ends
;*******************************************************************************************************************************************

start:
mov ax,seg d1
mov ds,ax
mov ax,seg s1
mov ss,ax
lea sp,top

output msgl
output msg1
output msgl

output msg2a
inputs limit,6h
atoi limit
mov limit,al

output msg2b
inputs rlim,6h
atoi rlim
mov rlim,al

output msg2c
inputs slim,6h
atoi slim
mov slim,al

output msgl
output msgg

;;;to set the controlword register porta is input and portb is output
mov al,90h
mov dx,cw
out dx,al

;;cw is set

repeat:

mov ah,01h
int 16h                                               ;;to exit the programme if any key is typed
jnz ext
call iship
call oship
call coming
call icount
call ocount
call weight
call shipstop
jmp repeat

ext:
output msgl
output msg4
output msgl
mov ax,4c00h
int 21h 

c1 ends
end start








