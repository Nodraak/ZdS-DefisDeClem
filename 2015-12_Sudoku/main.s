[BITS 32]

global _start

section .data
    s_crlf      db 0xD, 0xA, 0x0

    SYS_EXIT:   equ 1
    SYS_WRITE:  equ 4
    STDOUT:     equ 1


section .text

_start:
    pop eax     ; argv
    push eax
    ;call print_int
    add esp, 4

    pop ebx     ; argv
    push ebx
    call print_str
    add esp, 4

    lea eax, [s_crlf]
    push eax
    call print_str
    add esp, 0x4

    add ebx, 0x1
    call print_str
    add esp, 4

    lea eax, [s_crlf]
    push eax
    call print_str
    add esp, 0x4

    push 0
    call exit
    add esp, 4


print_str:
; Prints a string to stdout
; Args:
;   a string's address, '\0' terminated

    push ebp
    mov ebp, esp

    mov ecx, [ebp + 8]

    ; while *s != '\0', print one char
    loop:
        mov eax, [ecx]
        cmp al, 0x0
        je end

        mov eax, SYS_WRITE
        mov ebx, STDOUT
        mov edx, 1
        int 0x80

        inc ecx
        jmp loop
    end:

    mov esp, ebp
    pop ebp
    ret


print_int:
; Prints a integer to stdout
; Args:
;   an integer

    push ebp
    mov ebp, esp

    ; convert int to str
    mov eax, [ebp + 8]
    add eax, 0x30
    push eax

    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, esp
    mov edx, 1
    int 0x80

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
