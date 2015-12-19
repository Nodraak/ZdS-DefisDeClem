
; [ebp + 16]    - third function parameter
; [ebp + 12]    - second function parameter
; [ebp + 8]     - first function parameter
; [ebp + 4]     - old %EIP (the function's "return address")
; [ebp + 0]     - old %EBP (previous function's base pointer)
; [ebp - 4]    - first local variable
; [ebp - 8]    - second local variable
; [ebp - 12]   - third local variable

[BITS 32]

global _start

section .data
    s_crlf      db 0xD, 0xA, 0x0
    s_space     db ' ', 0x0
    s_arg       db 'arguments:', 0xD, 0xA, 0x0

    SYS_EXIT:   equ 1
    SYS_WRITE:  equ 4
    STDOUT:     equ 1


section .text

_start:
    ; argc [esp]
    ; argv [esp+4]

    ;
    ; argc
    ;

    mov eax, [esp] ; get argc

    push eax
    call print_int
    add esp, 0x4

    lea ebx, [s_space]
    push ebx
    call print_str
    add esp, 0x4

    lea ebx, [s_arg]
    push ebx
    call print_str
    add esp, 0x4

    ;
    ; argv
    ;

    ; eax argc
    ; ebx garbage
    ; ecx counter
    ; edx argv

    mov ecx, 0x0 ; counter
    s_loop:
        cmp ecx, eax
        jge s_end

        ; counter
        push ecx
        call print_int
        add esp, 0x4

        ; space
        lea ebx, [s_space]
        push ebx
        call print_str
        add esp, 0x4

        ; argv
        mov edx, [esp + 4 + 4*ecx] ; get argv
        push edx
        call print_str
        add esp, 0x4

        ; \n
        lea ebx, [s_crlf]
        push ebx
        call print_str
        add esp, 0x4

        inc ecx
        inc edx
        jmp s_loop
    s_end:

    push 0
    call exit
    add esp, 4


print_str:
; Prints a string to stdout
; Args:
;   a string's address, '\0' terminated

    push ebp
    mov ebp, esp
    pushad

    mov ecx, [ebp + 8]

    ; while *s != '\0', print one char
    ps_loop:
        mov eax, [ecx]
        cmp al, 0x0
        je ps_end

        mov eax, SYS_WRITE
        mov ebx, STDOUT
        mov edx, 1
        int 0x80

        inc ecx
        jmp ps_loop
    ps_end:

    popad
    mov esp, ebp
    pop ebp
    ret


print_int:
; Prints a integer to stdout
; Args:
;   an integer

    push ebp
    mov ebp, esp
    pushad

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

    popad
    mov esp, ebp
    pop ebp
    ret


exit:
; Quit the program
; Arg:
;   return value

    push ebp
    mov ebp, esp

    mov eax, SYS_EXIT
    mov ebx, [ebp + 8] ; return value
    int 0x80

    mov esp, ebp
    pop ebp
    ret
