
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

%macro print_int_dec 1
    push 10
    push %1
    call print_int
    add esp, 0x8
%endmacro

%macro print_int_hex 1
    push s_hex
    call print_str
    add esp, 0x4

    push 16
    push %1
    call print_int
    add esp, 0x8
%endmacro

;
; DATA
;

; initialized variables - RW
section .data
    grid        times 81 dd 0x0


; ro initialized variables - RO
section .rodata
    SYS_EXIT    equ 1
    SYS_WRITE   equ 4
    STDOUT      equ 1

    s_crlf      db 0xD, 0xA, 0x0
    s_space     db ' ', 0x0
    s_arg       db 'arguments:', 0xD, 0xA, 0x0
    s_hex       db '0x', 0x0
    s_3dash     db '---', 0xD, 0xA, 0x0
    s_error_count db 'Error, expected 2 args', 0xD, 0xA, 0x0
    s_sep       db '.', 0x0


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

    call print_args
    call parse_argv
    call print_grid

    push 0
    call exit ; does not return


; Print argc and argv
print_args:
    PRE_FUNC

    ;
    ; argc
    ;

    mov eax, [argc]
    print_int_dec eax

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
        print_int_dec ecx

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


; Parse argv[1] and store it in grid
parse_argv:
    PRE_FUNC

    mov eax, [argc]
    cmp eax, 2
    jne .error_count

    mov ecx, 0
    .loop:
        cmp ecx, 81
        jge .end

        mov edx, [argv]
        mov edx, [edx + 4]
        mov al, [edx + ecx]

        sub eax, 0x30 ; convert char to int - 0x30 == '0'
        mov [grid + 4*ecx], eax

        inc ecx
        jmp .loop

    .error_count:
    push s_error_count
    call print_str
    add esp, 0x4
    jmp .end

    .end:
    POST_FUNC


; Prints the sudoku grid
print_grid:
    PRE_FUNC

    push s_3dash
    call print_str
    add esp, 0x4

    mov eax, 0
    .loop_1:
        cmp eax, 9
        je .end_1

        mov ebx, 0
        .loop_2:
            cmp ebx, 9
            je .end_2

            ; compute index
            mov ecx, 0
            times 9 add ecx, eax
            add ecx, ebx

            mov edx, [grid + 4*ecx]

            ; print the digit
            cmp edx, 0
            je .print_empty
            jne .print_digit

            .print_empty:
            push s_space
            call print_str
            add esp, 0x4
            jmp .print_end

            .print_digit:
            print_int_dec edx
            jmp .print_end

            ; inc and loop
            .print_end:
            inc ebx
            jmp .loop_2

        .end_2:

        push s_crlf
        call print_str
        add esp, 0x4

        inc eax
        jmp .loop_1

    .end_1:

    push s_3dash
    call print_str
    add esp, 0x4

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
;   an integer (ex: 42)
;   a base (ex: 10 or 16)
print_int:
    PRE_FUNC

    ; load arg
    mov eax, [ebp + 8]
    mov ebx, [ebp + 12] ; base
    mov edx, 0

    ; if n > 10
    ;     push n/10
    ;     recursive call
    cmp eax, ebx
    jl .format_number
    div ebx ; div arg == edx:eax / arg ; quotient in eax, remainder in edx

    push ebx
    push eax
    call print_int
    add esp, 0x8

    ; move remainder in eax, to be printed
    mov eax, edx

    .format_number:

    ; convert int to str
    cmp eax, 10
    jl .convert_dec
    jge .convert_hex
    .convert_dec:
    add eax, 0x31-0x1-0x0 ; 0x31 == '1'
    jmp .print
    .convert_hex:
    add eax, 0x41-0x1-0xA ; 0x41 == 'A'
    jmp .print

    .print:
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

