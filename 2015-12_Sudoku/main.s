[BITS 32]

global _start

section .data
    ; align 0x4
    s_hello:        db ' - Hello, world!', 0xA, 0x0
    s_hello_len:    equ $-s_hello

    SYS_EXIT:   equ 1
    SYS_WRITE:  equ 4
    STDOUT:     equ 1

; section .bss


section .text

_start:
    pop eax     ; argv
    push eax
    call print_int
    add esp, 4

    pop ebx     ; argv
    push 15
    push ebx
    call print_str
    add esp, 8

    push s_hello_len
    lea eax, [s_hello]
    push eax
    call print_str
    add esp, 8

    push 0
    call exit
    add esp, 4


print_str:
; Prints a string to stdout
; Args:
;   a string's address
;   len

    push ebp
    mov ebp, esp

    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, [ebp + 8]   ; string
    mov edx, [ebp + 12]  ; len
    int 0x80

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
