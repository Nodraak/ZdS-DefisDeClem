
; STACK
; [ebp + 16]    - third function parameter
; [ebp + 12]    - second function parameter
; [ebp + 8]     - first function parameter
; [ebp + 4]     - old %EIP (the function's "return address")
; [ebp + 0]     - old %EBP (previous function's base pointer)
; [ebp - 4]    - first local variable
; [ebp - 8]    - second local variable
; [ebp - 12]   - third local variable

; REGISTERS
; es, fs, gs
; esi, edi
; eax accumulator
; ebx base
; ecx counter
; edx data


[BITS 32]

global _start


;
; MACROS
;

%macro PRE_FUNC 0
    push ebp
    mov ebp, esp
    pushad
%endmacro

%macro POST_FUNC 0
    popad
    leave ; leave == mov esp, ebp + pop ebp
    ret
%endmacro


;
; DATA
;

; initialized variables - RW
section .data
    grille      times 81 db 0x0


; ro initialized variables - RO
section .rodata
    SYS_EXIT    equ 1
    SYS_WRITE   equ 4
    STDOUT      equ 1

    s_crlf      db 0xD, 0xA, 0x0
    s_space     db ' ', 0x0
    s_arg       db 'arguments:', 0xD, 0xA, 0x0


; uninitialized variables - RW
section .bss
    argc    resb 0x4
    argv    resb 0x4


;
; CODE
;

; code - RO
section .text

_start:
    ; save argc and argv
    mov eax, [esp]
    mov [argc], eax
    lea eax, [esp+4]
    mov [argv], eax

    ; push argc and argv (from right to left - reverse order) to print them
    mov eax, [argv]
    push eax
    mov eax, [argc]
    push eax
    call print_args
    add esp, 0x8

    push 0
    call exit ; does not return


; Print argc and argv
; Arg
;   argc
;   argv
print_args:
    PRE_FUNC

    ;
    ; argc
    ;

    mov eax, [argc]
    push eax
    call print_int
    add esp, 0x4

    push s_space
    call print_str
    add esp, 0x4

    push s_arg
    call print_str
    add esp, 0x4

    ;
    ; argv
    ;

    ; eax argc
    ; ecx counter
    ; edx strings (s_space, argv, ...)

    mov ecx, 0x0 ; counter
    .loop:
        cmp ecx, eax
        jge .end

        ; counter
        push ecx
        call print_int
        add esp, 0x4

        ; space
        push s_space
        call print_str
        add esp, 0x4

        ; argv
        mov edx, [argv]
        mov edx, [edx + 4*ecx]
        push edx
        call print_str
        add esp, 0x4

        ; \n
        push s_crlf
        call print_str
        add esp, 0x4

        inc ecx
        jmp .loop
    .end:

    POST_FUNC


; Prints a string to stdout
; Args:
;   a string's address, '\0' terminated
print_str:
    PRE_FUNC

    mov ecx, [ebp + 8]

    ; while *s != '\0', print one char
    .loop:
        mov eax, [ecx]
        cmp al, 0x0
        je .end

        mov eax, SYS_WRITE
        mov ebx, STDOUT
        mov edx, 1
        int 0x80

        inc ecx
        jmp .loop
    .end:

    POST_FUNC


; Prints a integer to stdout
; Args:
;   an integer
print_int:
    PRE_FUNC

    ; convert int to str
    mov eax, [ebp + 8]
    add eax, 0x30 ; 0x30 == '0'
    push eax

    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, esp ; needs an addr to print
    mov edx, 1
    int 0x80

    pop eax

    POST_FUNC


; Quit the program
; Arg:
;   return value
exit:
    PRE_FUNC

    mov eax, SYS_EXIT
    mov ebx, [ebp + 8] ; return value
    int 0x80

    POST_FUNC

