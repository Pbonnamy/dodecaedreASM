; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XNextEvent

extern printf
extern scanf

; external functions from stdio library (ld-linux-x86-64.so.2)    
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1

global main


section .bss
display_name:	resq	1
screen:		resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		resq	1
gc:		resq	1

section .data


event:		times	24 dq 0

; Un point par ligne sous la forme X,Y,Z
dodec:	dd	0.0,50.0,80.901699		; point 0
		dd 	0.0,-50.0,80.901699		; point 1
		dd 	80.901699,0.0,50.0		; point 2
		dd 	80.901699,0.0,-50.0		; point 3
		dd 	0.0,50.0,-80.901699		; point 4
		dd 	0.0,-50.0,-80.901699	; point 5
		dd 	-80.901699,0.0,-50.0	; point 6
		dd 	-80.901699,0.0,50.0		; point 7
		dd 	50.0,80.901699,0.0		; point 8
		dd 	-50.0,80.901699,0.0		; point 9
		dd 	-50.0,-80.901699,0.0	; point 10
		dd	50.0,-80.901699,0.0		; point 11
		
xy: 	dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0
		dd 0,0

visiblefaces:	dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
				dd 0
		
df: dd 200.0
xoff: dd 200.0
yoff: dd 200.0
zoff: dd 400.0
A: dd 0
B: dd 0
C: dd 0
xA: dd 0
yA: dd 0
xB: dd 0
yB: dd 0
xC: dd 0
yC: dd 0
xBA: dd 0
yBA: dd 0
xBC : dd 0
yBC : dd 0
normalBool : dd 0
; Une face par ligne, chaque face est composée de 3 points tels que numérotés dans le tableau dodec ci-dessus
; Les points sont donnés dans le bon ordre pour le calcul des normales.
; Exemples :
; pour la première face (0,8,9), on fera le produit vectoriel des vecteurs 80 (vecteur des points 8 et 0) et 89 (vecteur des points 8 et 9)	
; pour la deuxième face (0,2,8), on fera le produit vectoriel des vecteurs 20 (vecteur des points 2 et 0) et 28 (vecteur des points 2 et 8)
; etc...
faces:	dd	0,8,9,0
		dd	0,2,8,0
		dd	2,3,8,2
		dd	3,4,8,3
		dd	4,9,8,4
		dd	6,9,4,6
		dd	7,9,6,7
		dd	7,0,9,7
		dd	1,10,11,1
		dd	1,11,2,1
		dd	11,3,2,11
		dd	11,5,3,11
		dd	11,10,5,11
		dd	10,6,5,10
		dd	10,7,6,10
		dd	10,1,7,10
		dd	0,7,1,0
		dd	0,1,2,0
		dd	3,5,4,3
		dd	5,6,4,5


section .text


;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
    mov rbp, rsp; for correct debugging

;####################################
;## Code de création de la fenêtre ##
;####################################
xor     rdi,rdi
call    XOpenDisplay	; Création de display
mov     qword[display_name],rax	; rax=nom du display

mov     rax,qword[display_name]
mov     eax,dword[rax+0xe0]
mov     dword[screen],eax

mov rdi,qword[display_name]
mov esi,dword[screen]
call XRootWindow
mov rbx,rax

mov rdi,qword[display_name]
mov rsi,rbx
mov rdx,10
mov rcx,10
mov r8,400	; largeur
mov r9,400	; hauteur
push 0xFFFFFF	; background  0xRRGGBB
push 0x00FF00
push 1
call XCreateSimpleWindow
mov qword[window],rax

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,131077 ;131072
call XSelectInput

mov rdi,qword[display_name]
mov rsi,qword[window]
call XMapWindow

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,0
mov rcx,0
call XCreateGC
mov qword[gc],rax

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov rdx,0x000000	; Couleur du crayon
call XSetForeground

; boucle de gestion des évènements
boucle: 
	mov rdi,qword[display_name]
	mov rsi,event
	call XNextEvent

	cmp dword[event],ConfigureNotify
	je prog_principal
	cmp dword[event],KeyPress
	je closeDisplay
jmp boucle

;###########################################
;## Fin du code de création de la fenêtre ##
;###########################################

;############################################
;##	Ici commence VOTRE programme principal ##
;############################################ 
prog_principal:
mov rax,0
mov rbx,0
mov rcx,0


processxy :

	movss XMM0,dword[dodec+eax*DWORD] ; -> x
	mulss XMM0,dword[df] ; -> x*df
	movss XMM1,dword[dodec+(eax+2)*DWORD] ; -> z
	addss XMM1,dword[zoff] ; -> z+zoff
	divss XMM0,XMM1 ; -> (x*df)/(z+zoff)
	addss XMM0,dword[xoff] ; -> (x*df)/(z+zoff) + xoff
	cvtss2si ebx,XMM0 ; convertion en entier
	mov dword[xy+ecx*DWORD],ebx ; rangement
	movss XMM0,dword[dodec+(eax+1)*DWORD] ; -> y
	mulss XMM0,dword[df] ; -> y*df
	divss XMM0,XMM1 ; (y*df)/(z+zoff)
	addss XMM0,dword[yoff] ; (y*df)/(z+zoff) + yoff
	cvtss2si ebx,XMM0 ; convertion en entier
	mov dword[xy+(ecx+1)*DWORD],ebx ; rangement
	add eax,3 ; ligne dodec += 1
	add ecx,2 ; ligne xy += 1
	cmp ecx,22 ; tableau xy rempli
	jbe processxy


mov rax,0
mov ebx,0
mov ecx,0
mov r8,0
mov r9,0
mov r10,0

isvisible:
	mov eax,dword[faces+ebx*DWORD] ; point A
	mov dword[A],eax
	mov eax,dword[faces+(ebx+1)*DWORD] ; point B
	mov dword[B],eax
	mov eax,dword[faces+(ebx+2)*DWORD] ; point C
	mov dword[C],eax

	add ebx,4
	
	mov eax,dword[A]
	mov r8d,dword[xy+eax*2*DWORD] ; xA
	mov dword[xA],r8d
	mov r8d,dword[xy+(eax*2+1)*DWORD] ; yA
	mov dword[yA],r8d
	mov eax,dword[B]
	mov r8d,dword[xy+eax*2*DWORD] ; xB
	mov dword[xB],r8d
	mov r8d,dword[xy+(eax*2+1)*DWORD] ; yB
	mov dword[yB],r8d
	mov eax,dword[C]
	mov r8d,dword[xy+eax*2*DWORD] ; xC
	mov dword[xC],r8d
	mov r8d,dword[xy+(eax*2+1)*DWORD] ; yC
	mov dword[yC],r8d
	
	mov r9d,dword[xA]
	mov r10d,dword[xB]
	sub r9d,r10d ;xA-xB
	mov dword[xBA],r9d ;xBA
	
	mov r9d,dword[yA]
	mov r10d,dword[yB]
	sub r9d,r10d ;yA-yB
	mov dword[yBA],r9d ;yBA
	
	mov r9d,dword[xC]
	mov r10d,dword[xB]
	sub r9d,r10d ;xC-xB
	mov dword[xBC],r9d ;xBC
	
	mov r9d,dword[yC]
	mov r10d,dword[yB]
	sub r9d,r10d ;yC-yB
	mov dword[yBC],r9d ;yBC
	
	mov r9d,dword[xBA]
	imul r9d,dword[yBC] ;xBA*yBC
	
	mov r10d,dword[yBA]
	imul r10d,dword[xBC] ;yBA*xBC
	
	sub r9d,r10d ; (xBA*yBC)-(yBA*xBC)
	mov dword[normalBool],r9d
	
	cmp dword[normalBool],0
	jbe nextTest ; inférieur ou égal -> on laisse à 0
	mov dword[visiblefaces+ecx*DWORD],1 ; sinon on met 1
	nextTest:
	add ecx,1 ; on avance dans le tableau visibleFaces
	cmp ecx,20 ; tableau visiblefaces remplie
	jb isvisible ; tableau non remplie -> continuer


mov rax,0
mov rbx,0
mov rcx,0
mov r8,0
mov r9,0
mov r10,0
mov r12,0
mov r13,0

display:
	cmp dword[visiblefaces+r13d*DWORD],0 ;si 0 : on passe le dessin
	je skipdraw
	mov eax,dword[faces+ebx*DWORD] ; point src
	mov r10d,dword[faces+(ebx+1)*DWORD] ; point dst
	mov rdi,qword[display_name]
	mov rsi,qword[window]
	mov rdx,qword[gc]
	mov ecx,dword[xy+eax*2*DWORD] ; x1
	mov r8d,dword[xy+(eax*2+1)*DWORD] ; y1
	mov r9d,dword[xy+r10d*2*DWORD] ; x2
	push qword[xy+(r10d*2+1)*DWORD] ; y2
	call XDrawLine ; tracé de la ligne
	add ebx,1 ; avancée dans faces
	add r12d,1 ; compteur nb lignes
	cmp r12d,3 ; 3 lignes = 1 face
	je nextFace
	testend: cmp ebx,80 ; 80 cases du tableau faces
	jb display
	jmp end
	
nextFace:
	mov r12d,0 ; réinitialisation compteur
	add ebx,1 ; face suivante
        add r13d,1
	jmp testend

skipdraw:
	mov r12d,0
	add ebx,4
	add r13d,1
	jmp testend
	
end:
;##############################################
;##	Ici se termine VOTRE programme principal ##
;##############################################																																																																																																																																	     		     		jb boucle
jmp flush



flush:
mov rdi,qword[display_name]
call XFlush
jmp boucle
mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit

	