.386
.model flat,stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\gdiplus.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\msvcrt.inc

includelib c:\masm32\lib\gdi32.lib
includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\msvcrt.lib


.DATA
; Initialized variables
pathSuffix	db	"\*",0
dot			db	".",0
ddot		db	"..",0
progName    db    "CipherVault.exe"
pathFormat	db	"%s\%s",0
errStr		db	"Error, stoping program...",13,10,0
pauseStr	db	"pause",13,10,0	
clearStr	db	"cls",13,10,0	
scanfStr	db	"%s",0 
promtStr	db	"Path:",13,10,">>> ",0
printFormat	db	"files that successful finished /s %s",13,10,0
pathSeparator   db      "\",0

scanfChoiceStr     db  "%d", 0

; strings for printing purposes
tabIndent	db	"    ",0
fileStr		db	"<FILE>",0
dirStr		db	"<DIR>",0
formatStr	db	"%s %s",13,10,0
choicePromptStr    db  "Choose an option:", 13, 10, "1. Encrypt", 13, 10, "2. Decrypt", 13, 10, ">>> ", 0
encryptPromptStr   db  "Enter Path to encrypt files: ", 13, 10, 0
decryptPromptStr   db  "Enter Path to decrypt files: ", 13, 10, 0
invalidChoiceStr   db  "Invalid choice. Program will now exit.", 13, 10, 0


l1  db     "   ______    _              __                  _    __                    __   __",13,10,0 
l2  db     "  / ____/   (_)    ____    / /_   ___    _____ | |  / /  ____ _  __  __   / /  / /_",13,10,0
l3  db     " / /       / /    / __ \  / __ \ / _ \  / ___/ | | / /  / __ `/ / / / /  / /  / __/",13,10,0
l4  db     "/ /___    / /    / /_/ / / / / //  __/ / /     | |/ /  / /_/ / / /_/ /  / /  / /_  ",13,10,0
l5  db     "\____/   /_/    / .___/ /_/ /_/ \___/ /_/      |___/   \__,_/  \__,_/  /_/   \__/  ",13,10,0
l6  db     "        /_/                                                                        ",13,10,0

; Variables for tests purposes
defaultPath	db	".",0
projectPath	db	"C:\Users\Moustafa\Desktop\Testing",0

tempPath DWORD ?
bytes_read DWORD ?
bytes_written DWORD ?
file_size DWORD ?
file_handle DWORD 0

.DATA?
; Non-initialized variables
depth	 DWORD	?



.CODE
; Functions and main
; ------------------

; REMINDER:
; 	WIN32_FIND_DATA = 	318o	--> [ebp - WIN32_FIND_DATA]
; 	PATH			=	260o	--> [ebp - 578]
; 	HANDLE			= 	4o		--> [ebp - 582]
; 	new PATH		=	260o	--> [ebp - 842]
; 	Total			=	842o


listE PROC
	; -------------------------------
	; List the content of a directory
	; -------------------------------
	; Parameters
	; 	[ebp + 8]:		address for the given path
	; Variables
	; 	[ebp - 318]: 	struct that recieves the current file data
	;	[ebp - 578]: 	current path
	;	[ebp - 582]:	space for the handle returned by FindFirstFile
	; 	[ebp - 842]: 	new path
	
	push	ebp
	mov		ebp, esp
	sub		esp, 842			; save space for the variables

	inc		depth				; increment the depth
								; this value will be used during printing
	
	
	; Prepare the path so it fits the program's conditions.
	; ----------------------------------------------------

	; Copy the path into the stack so it can be modified
	push 	MAX_PATH			; maximum path size
	push 	[ebp + 8]			; address of the string passed in argument
	lea 	ebx, [ebp - 578]	; address of the path
	push	ebx
	call	crt_strncpy
	
	; Concatenate the path in parameter with "\*" to list
	; every file in the directory.
	push	MAX_PATH
	push	offset pathSuffix
	push	ebx					; address of the path
								; crt_strncpy does not modify %ebx
	call	crt_strncat
	
	
	; Call FindFirstFile.
	; ------------------
	
	; The fonction returns the first file's
	; data in the struct passed in parameter.
	lea		ebx, [ebp - WIN32_FIND_DATA]
	push 	ebx					; %ebx contains the address of the file data
	sub		ebx, MAX_PATH
	push	ebx					; %ebx now contains the address of the path
	call	FindFirstFile
	mov		[ebp - 582], eax	; save the handler in the stack
	
	; If anything goes wrong, signal error and quit.
	cmp 	eax, INVALID_HANDLE_VALUE 
	jne		no_error
	push	offset errStr
	call	crt_printf
	je 		error
	no_error:
	
	
	; Print the file/dir name and call FindNextFile
	; while theres entries in the given path.
	; --------------------------------------
	
	; do ... while()
	do:
		push    ecx				; save the value of %ecx
		
		; Get rid of the the dots so the program
		; does not start looping on the current file (.).
		; ----------------------------------------------
		
		; Call to ctr_strcmp to compare the
		; file name with "." and "..".
		lea		ebx, [ebp - WIN32_FIND_DATA]
		add 	ebx, 44
		
		push	ebx				; file name, e.g. "."
		push 	offset dot		; %s: "."
		call 	crt_strcmp		; strcmp() returns 0 if the strings are the same
		add		esp, 8
		cmp 	eax, NULL
		je		skip			; jump to the end of the function
		
		push	ebx
		push	offset ddot		; %s: ".."
		call 	crt_strcmp
		add		esp, 8
		cmp 	eax, NULL
		je		skip
		
		
            push	ebx
		push	offset progName		
		call 	crt_strcmp
		add		esp, 8
		cmp 	eax, NULL
		je		skip
    
		; Call the print function to display
		; the file/dir name.
		push 	[ebp - WIN32_FIND_DATA]
		lea		ebx, [ebp - WIN32_FIND_DATA]
		add 	ebx, 44
		push	ebx
		call	print
		add		esp, 8
		
		; If object is directory, call the list function
		; again, else skip to the next file.
		lea		ebx, [ebp - WIN32_FIND_DATA]
		cmp 	DWORD PTR [ebx], FILE_ATTRIBUTE_DIRECTORY
		jne 	nodir
		
		; Format the new path so it can be
		; understood by th OS.
		lea	ebx, [ebp - WIN32_FIND_DATA]
		add 	ebx, 44
		push	ebx
		push	[ebp + 8]		; current path
		push 	offset pathFormat
		lea		ebx, [ebp - 842]
		push	ebx
		call	crt_sprintf
		add		esp, 16
		
		; Call the function with the new path
		push 	ebx 		; %ebx contains the adress of the path
		call	listE
            add  esp, 4
	nodir:
	   
        
; Construct full path: path = original_path + '\' + file_name
		lea	ebx, [ebp - WIN32_FIND_DATA]
		add 	ebx, 44
		push	ebx
		push	[ebp + 8]		; current path
		push 	offset pathFormat
		lea	ebx, [ebp - 842]
		push	ebx
		call	crt_sprintf
		add		esp, 16	
            mov tempPath, ebx


; Open file for reading
    push    NULL
    push    FILE_ATTRIBUTE_NORMAL
    push    OPEN_EXISTING
    push    NULL
    push    0
    push    GENERIC_READ
    push    tempPath                               ; push the full path
    call    CreateFileA                       ; open the file for reading
    mov     file_handle, eax
    cmp     file_handle, INVALID_HANDLE_VALUE
    je      skip

   
; Get file size
    push    NULL
    push    file_handle
    call    GetFileSize
    mov     file_size, eax
    
; Allocate buffer based on file size
    push    file_size
    push    GMEM_ZEROINIT
    call    GlobalAlloc
    mov     ebx, eax      
    
; Read file contents into buffer
    push    NULL
    push    offset bytes_read
    push    file_size
    push    ebx                               ; buffer to store file content
    push    file_handle
    call    ReadFile    

; Close file handle after reading
    push    file_handle
    call    CloseHandle

; Modify ASCII values in the buffer\
    mov     ecx, bytes_read
    xor     edx, edx                          ; clear index register
modify_loop:
    cmp     edx, ecx
    jge     write_file                        ; exit loop if done

    add     byte ptr [ebx + edx], 169         ; modify ASCII value
    inc     edx
    jmp     modify_loop

write_file:
    ; Open file for writing (overwrite)
    push    NULL
    push    FILE_ATTRIBUTE_NORMAL
    push    CREATE_ALWAYS
    push    NULL
    push    0
    push    GENERIC_WRITE
    push    tempPath                               ; full path
    call    CreateFileA
    mov     file_handle, eax

    cmp     file_handle, INVALID_HANDLE_VALUE
    je      skip

    ; Write modified content back to the file
    push    NULL
    push    offset bytes_written
    push    bytes_read
    push    ebx                               ; buffer with modified content
    push    file_handle
    call    WriteFile

    ; Close the file handle after writing
    push    file_handle
    call    CloseHandle

    ; Free allocated buffer
    push    ebx
    call    GlobalFree
        
	skip:
		; Call FindNextFile on the handler given by
		; the FindFirstFile function.
		; --------------------------
		
		lea	ebx, [ebp - WIN32_FIND_DATA] 
		push 	ebx 			; %ebx contains the address of the struct
		push 	[ebp - 582]		; result of FindFirstFile
		call	FindNextFile
		
		pop 	ecx
		cmp 	eax, NULL 
	jne	do
	
	error:
	dec 	depth				; decrement the depth to restore it previous state
	
	mov		esp, ebp
	pop		ebp
	ret
listE ENDP




listD PROC
	; -------------------------------
	; List the content of a directory
	; -------------------------------
	; Parameters
	; 	[ebp + 8]:		address for the given path
	; Variables
	; 	[ebp - 318]: 	struct that recieves the current file data
	;	[ebp - 578]: 	current path
	;	[ebp - 582]:	space for the handle returned by FindFirstFile
	; 	[ebp - 842]: 	new path
	
	push	ebp
	mov		ebp, esp
	sub		esp, 842			; save space for the variables

	inc		depth				; increment the depth
								; this value will be used during printing
	
	
	; Prepare the path so it fits the program's conditions.
	; ----------------------------------------------------

	; Copy the path into the stack so it can be modified
	push 	MAX_PATH			; maximum path size
	push 	[ebp + 8]			; address of the string passed in argument
	lea 	ebx, [ebp - 578]	; address of the path
	push	ebx
	call	crt_strncpy
	
	; Concatenate the path in parameter with "\*" to list
	; every file in the directory.
	push	MAX_PATH
	push	offset pathSuffix
	push	ebx					; address of the path
								; crt_strncpy does not modify %ebx
	call	crt_strncat
	
	
	; Call FindFirstFile.
	; ------------------
	
	; The fonction returns the first file's
	; data in the struct passed in parameter.
	lea		ebx, [ebp - WIN32_FIND_DATA]
	push 	ebx					; %ebx contains the address of the file data
	sub		ebx, MAX_PATH
	push	ebx					; %ebx now contains the address of the path
	call	FindFirstFile
	mov		[ebp - 582], eax	; save the handler in the stack
	
	; If anything goes wrong, signal error and quit.
	cmp 	eax, INVALID_HANDLE_VALUE 
	jne		no_error
	push	offset errStr
	call	crt_printf
	je 		error
	no_error:
	
	
	; Print the file/dir name and call FindNextFile
	; while theres entries in the given path.
	; --------------------------------------
	
	; do ... while()
	do:
		push    ecx				; save the value of %ecx
		
		; Get rid of the the dots so the program
		; does not start looping on the current file (.).
		; ----------------------------------------------
		
		; Call to ctr_strcmp to compare the
		; file name with "." and "..".
		lea		ebx, [ebp - WIN32_FIND_DATA]
		add 	ebx, 44
		
		push	ebx				; file name, e.g. "."
		push 	offset dot		; %s: "."
		call 	crt_strcmp		; strcmp() returns 0 if the strings are the same
		add		esp, 8
		cmp 	eax, NULL
		je		skip			; jump to the end of the function
		
		push	ebx
		push	offset ddot		; %s: ".."
		call 	crt_strcmp
		add		esp, 8
		cmp 	eax, NULL
		je		skip
		
		
            push	ebx
		push	offset progName		
		call 	crt_strcmp
		add		esp, 8
		cmp 	eax, NULL
		je		skip
    
		; Call the print function to display
		; the file/dir name.
		push 	[ebp - WIN32_FIND_DATA]
		lea		ebx, [ebp - WIN32_FIND_DATA]
		add 	ebx, 44
		push	ebx
		call	print
		add		esp, 8
		
		; If object is directory, call the list function
		; again, else skip to the next file.
		lea		ebx, [ebp - WIN32_FIND_DATA]
		cmp 	DWORD PTR [ebx], FILE_ATTRIBUTE_DIRECTORY
		jne 	nodir
		
		; Format the new path so it can be
		; understood by th OS.
		lea	ebx, [ebp - WIN32_FIND_DATA]
		add 	ebx, 44
		push	ebx
		push	[ebp + 8]		; current path
		push 	offset pathFormat
		lea		ebx, [ebp - 842]
		push	ebx
		call	crt_sprintf
		add		esp, 16
		
		; Call the function with the new path
		push 	ebx 		; %ebx contains the adress of the path
		call	listD
            add  esp, 4
	nodir:
	   
        
; Construct full path: path = original_path + '\' + file_name
		lea	ebx, [ebp - WIN32_FIND_DATA]
		add 	ebx, 44
		push	ebx
		push	[ebp + 8]		; current path
		push 	offset pathFormat
		lea	ebx, [ebp - 842]
		push	ebx
		call	crt_sprintf
		add		esp, 16	
            mov tempPath, ebx


; Open file for reading
    push    NULL
    push    FILE_ATTRIBUTE_NORMAL
    push    OPEN_EXISTING
    push    NULL
    push    0
    push    GENERIC_READ
    push    tempPath                               ; push the full path
    call    CreateFileA                       ; open the file for reading
    mov     file_handle, eax
    cmp     file_handle, INVALID_HANDLE_VALUE
    je      skip

   
; Get file size
    push    NULL
    push    file_handle
    call    GetFileSize
    mov     file_size, eax
    
; Allocate buffer based on file size
    push    file_size
    push    GMEM_ZEROINIT
    call    GlobalAlloc
    mov     ebx, eax      
    
; Read file contents into buffer
    push    NULL
    push    offset bytes_read
    push    file_size
    push    ebx                               ; buffer to store file content
    push    file_handle
    call    ReadFile    

; Close file handle after reading
    push    file_handle
    call    CloseHandle

; Modify ASCII values in the buffer\
    mov     ecx, bytes_read
    xor     edx, edx                          ; clear index register
modify_loop:
    cmp     edx, ecx
    jge     write_file                        ; exit loop if done

    sub     byte ptr [ebx + edx], 169         ; modify ASCII value
    inc     edx
    jmp     modify_loop

write_file:
    ; Open file for writing (overwrite)
    push    NULL
    push    FILE_ATTRIBUTE_NORMAL
    push    CREATE_ALWAYS
    push    NULL
    push    0
    push    GENERIC_WRITE
    push    tempPath                               ; full path
    call    CreateFileA
    mov     file_handle, eax

    cmp     file_handle, INVALID_HANDLE_VALUE
    je      skip

    ; Write modified content back to the file
    push    NULL
    push    offset bytes_written
    push    bytes_read
    push    ebx                               ; buffer with modified content
    push    file_handle
    call    WriteFile

    ; Close the file handle after writing
    push    file_handle
    call    CloseHandle

    ; Free allocated buffer
    push    ebx
    call    GlobalFree
        
	skip:
		; Call FindNextFile on the handler given by
		; the FindFirstFile function.
		; --------------------------
		
		lea	ebx, [ebp - WIN32_FIND_DATA] 
		push 	ebx 			; %ebx contains the address of the struct
		push 	[ebp - 582]		; result of FindFirstFile
		call	FindNextFile
		
		pop 	ecx
		cmp 	eax, NULL 
	jne	do
	
	error:
	dec 	depth				; decrement the depth to restore it previous state
	
	mov		esp, ebp
	pop		ebp
	ret
listD ENDP




print PROC
	; --------------------------------
	; Display a file/dir name with the
	; correct indentation.
	; --------------------------------
	; Parameters
	; 	[ebp + 8]: address for the file name
	; 	[ebp + 12]: object type
	
	push	ebp
	mov		ebp, esp
	
	; Print as many tabs its required.
	; for(i = 0; i < depth; i++)
	mov		ecx, depth
	next:
		push 	ecx				; save ecx on the stack
	
		push 	offset tabIndent
		call 	crt_printf
		
		add 	esp, 4
		pop 	ecx
		loop 	next
	
	; Chose the right prefix according to the
	; value of dwFileAttributes.
	mov 	edx, offset fileStr
	cmp 	DWORD PTR [ebp + 12], FILE_ATTRIBUTE_DIRECTORY
	jne 	file
	mov 	edx, offset dirStr
	file:
	
	
	; Print object's type and name
	push	[ebp + 8] ; file name
	push	edx       ; register for type
	push	offset formatStr
	call	crt_printf
	
	mov		esp, ebp
	pop		ebp
	ret
print ENDP

start:
    sub	esp, MAX_PATH		; save space for the input path
    mov 	depth, 0 			; set depth to zero
	
; Display Program Name:
    push offset l1
    call crt_printf
    push offset l2
    call crt_printf
    push offset l3
    call crt_printf
    push offset l4
    call crt_printf
    push offset l5
    call crt_printf
    push offset l6
    call crt_printf

; Display the choice prompt for Encrypt or Decrypt
    push    offset choicePromptStr
    call    crt_printf

    ; Call scanf() to get the user input for choice
    lea     ebx, [ebp - 4]         ; Reserve space for choice input
    push    ebx                    ; address to store user choice
    push    offset scanfChoiceStr  ; format string
    call    crt_scanf
    add     esp, 8                 ; restore stack

    ; Load the choice into a register and compare
    mov     eax, [ebp - 4]
    cmp     eax, 1                 ; If choice == 1
    je      encrypt_path           ; Jump to encryption flow
    cmp     eax, 2                 ; If choice == 2
    je      decrypt_path           ; Jump to decryption flow

    ; Invalid choice handling
    push    offset invalidChoiceStr
    call    crt_printf
    jmp     end_program
    

encrypt_path:
    push    offset encryptPromptStr    ; display encrypt prompt
    call    crt_printf

	push 	offset promtStr		; display the prompt
	call	crt_printf
	
	; Call scanf() to get the user input
	lea 	ebx, [ebp - MAX_PATH]
	push	ebx					; address where to store the path
	push 	offset scanfStr		; format
	call	crt_scanf
	add		esp, 8				; restore stack
	
	invoke	crt_system, offset clearStr
								; clear the window
	
	push	ebx
	push	offset printFormat
	call	crt_printf			; print the given path
	
	push	ebx					; push given path
	call	listE
        jmp end_program

decrypt_path:
    push    offset decryptPromptStr    ; display decrypt prompt
    call    crt_printf

	push 	offset promtStr		; display the prompt
	call	crt_printf
	
	; Call scanf() to get the user input
	lea 	ebx, [ebp - MAX_PATH]
	push	ebx					; address where to store the path
	push 	offset scanfStr		; format
	call	crt_scanf
	add		esp, 8				; restore stack
	
	invoke	crt_system, offset clearStr
								; clear the window
	
	push	ebx
	push	offset printFormat
	call	crt_printf			; print the given path
	
	push	ebx					; push given path
	call	listD
	
end_program:
	invoke	crt_system, offset pauseStr      
	mov		eax, 0
	invoke	ExitProcess,eax
end start