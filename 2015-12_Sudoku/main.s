
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


bits 32

global _start

;
; DEFINES
;

%define CHECK_ROW 0
%define CHECK_COLUMNS 1
%define CHECK_BLOCK 2


;
; MACROS
;

%macro PRE_FUNC 0
    push ebp
    mov ebp, esp
%endmacro

%macro POST_FUNC 0-1
    ; if we have an argument, mov it to eax as return code
    %if %0 == 1
        mov eax, %1
    %endif

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

%macro print_str_crlf 1
    push %1
    call print_str
    add esp, 0x4

    push s_crlf
    call print_str
    add esp, 0x4
%endmacro


; Return if a condition if true
; Args:
;   an int
;   another int
;   a conditional jmp: jne, jl, jge, ...
;   a return value (optional)
; If the conditional jmp is true, the function returns
; (with the optional retrun value in eax if specified)
%macro ret_if_true 3-4
    cmp %1, %2
    %3 %%ret
    jmp %%skip

    %%ret:
        %if %0 == 3
            POST_FUNC
        %else
            POST_FUNC %4
        %endif
    %%skip:
%endmacro


; Get a cell of the grid
; Args: y, x coordinates
; Returns value in eax
%macro get_cell_at 2
    mov eax, %1
    imul eax, 9
    add eax, %2
    mov eax, [grid + 4*eax]
%endmacro


; Get a cell of the grid via a block and a cell id
; Args: block id and cell id
; Returns value in eax (uses get_cell_at macro)
%macro get_cell_at_block 2
    ; div arg
    ;   edx:eax -> quotient
    ;   edx -> remainder (modulus)

    ; y = y1 + y2 = (blk/3)*3 + cell/3
    ; x = x1 + x2 = (blk%3)*3 + cell%3
    ; compute each [y1, x1, y2, x2] (in this order cause of DIV properties)
    ; while pushing each result and then pop and add to compute y and x

    ; y1, x1
    mov edx, 0
    mov eax, %1
    mov ecx, 3
    div ecx
    imul eax, 3
    imul edx, 3
    push eax ; y1
    push edx ; x1

    ; y2, x2
    mov edx, 0
    mov eax, %2
    mov ecx, 3
    div ecx ; eax = y2, edx = x2

    pop ebx ; x1
    pop ecx ; y1

    add eax, ecx ; y = y2 + y1
    add edx, ecx ; x = x2 + x1

    get_cell_at eax, edx
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

    s_3dashes       db '---', 0x0
    s_arg           db ' arguments:', 0x0
    s_crlf          db 0xD, 0xA, 0x0
    s_error_count   db 'Error, expected 10 args', 0x0
    se_grid_check_args db 'Error, unexpected argument', 0x0
    s_hex           db '0x', 0x0
    s_sep           db '.', 0x0
    s_space         db ' ', 0x0
    s_solved        db 'Solved \o/', 0x0


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

    call grid_is_valid
    print_int_dec eax
    push s_crlf
    call print_str
    add esp, 0x4

    push 0
    call grid_solve
    add esp, 0x4

    print_int_dec 0
    print_str_crlf s_space

    push 0
    call exit ; does not return


; Print argc and argv
print_args:
    PRE_FUNC

    ; [ebp-4] counter
    sub esp, 0x4
    mov DWORD [ebp-4], 0

    ;
    ; print argc
    ;

    print_int_dec DWORD [argc]
    print_str_crlf s_arg

    ;
    ; print every argv
    ;

    .loop:
        mov eax, [ebp-4]
        cmp eax, [argc]
        jge .end

        ; counter
        print_int_dec DWORD [ebp-4]

        ; space
        push s_space
        call print_str
        add esp, 0x4

        ; argv
        mov ecx, [ebp-4]
        mov ebx, [argv]
        mov edx, [ebx + 4*ecx]
        print_str_crlf edx

        inc DWORD [ebp-4]
        jmp .loop
    .end:

    POST_FUNC


; Parse argv[1] and store it in grid
parse_argv:
    PRE_FUNC

    cmp DWORD [argc], 10
    jne .error_count

    ; eax: tmp data
    ; ebx: argv array index
    ; ecx: string index
    ; edx: tmp data: current digit

    mov ebx, 0+1 ; skip argv[0]
    .loop_1:
        cmp ebx, 9+1
        jge .end

        mov ecx, 0
        .loop_2:
            cmp ecx, 9
            jge .end_2

            ; get the current char
            mov eax, [argv]
            mov eax, [eax + 4*ebx]
            mov dl, [eax + ecx]
            ; convert to int
            cmp edx, 0x2E ; 0x2E == '.'
            jne .convert_digit
            je .convert_empty
            .convert_empty:
            mov edx, 0
            jmp .save
            .convert_digit:
            sub edx, 0x30 ; convert char to int - 0x30 == '0'
            jmp .save
            .save:

            ; save it (edx is index)
            mov eax, ebx
            dec eax ; hack because skip argv[0]
            imul eax, 9
            add eax, ecx

            mov [grid + 4*eax], edx

            inc ecx
            jmp .loop_2

        .end_2:

        inc ebx
        jmp .loop_1

    .error_count:
    print_str_crlf s_error_count
    jmp .end

    .end:
    POST_FUNC


; Prints the sudoku grid
print_grid:
    PRE_FUNC

    ; [ebp-4] first level counter (rows)
    ; [ebp-8] second level counter (columns)
    sub esp, 0x8
    mov DWORD [ebp-4], 0
    mov DWORD [ebp-8], 0

    print_str_crlf s_3dashes

    .loop_1:
        cmp DWORD [ebp-4], 9
        je .end_1

        mov DWORD [ebp-8], 0
        .loop_2:
            cmp DWORD [ebp-8], 9
            je .end_2

            ; get cell value
            get_cell_at DWORD [ebp-4], DWORD [ebp-8]

            ; print the digit or a space if cell is empty
            cmp eax, 0
            je .print_empty
            jne .print_digit

            .print_empty:
            push s_space
            call print_str
            add esp, 0x4
            jmp .print_end

            .print_digit:
            print_int_dec eax
            jmp .print_end

            ; inc and loop
            .print_end:
            inc DWORD [ebp-8]
            jmp .loop_2

        .end_2:

        push s_crlf
        call print_str
        add esp, 0x4

        inc DWORD [ebp-4]
        jmp .loop_1

    .end_1:

    print_str_crlf s_3dashes

    POST_FUNC


; Returns in eax 1 if the (row|column|block) is valid, 0 otherwise
; Arg:
;   An static id (ex: a row id)
;   [0, 1, 2] = [row, columns, block]
; For check row: for n from 1 to 9, we iterate over the whole row to count the
; number of occurence of the current n in the row
grid_check:
    PRE_FUNC

    ; [ebp-4] column counter
    ; [ebp-8] number (n) counter
    ; [ebp-12] occurence counter
    sub esp, 12

    ; loop every n
    mov DWORD [ebp-8], 1
    .loop_n:
        cmp DWORD [ebp-8], 10
        jge .end_n

        ; loop every columns and count occurences of n
        mov DWORD [ebp-4], 0
        mov DWORD [ebp-12], 0
        .loop_c:
            cmp DWORD [ebp-4], 9
            jge .end_c

            cmp DWORD [ebp+12], CHECK_ROW
            je .check_row
            cmp DWORD [ebp+12], CHECK_COLUMNS
            je .check_column
            cmp DWORD [ebp+12], CHECK_BLOCK
            je .check_block
            jmp .error

            .check_row:
            ; get_cell_at row id, column id
            get_cell_at DWORD [ebp+8], DWORD [ebp-4] ; use arg1 as row_id
            jmp .all
            .check_column:
            ; get_cell_at row id, column id
            get_cell_at DWORD [ebp-4], DWORD [ebp+8] ; use arg1 as column_id
            jmp .all
            .check_block:
            get_cell_at_block [ebp+8], [ebp-4]
            jmp .all

            .all:
            ; if equal, inc counter
            cmp eax, [ebp-8]
            jne .skip
            inc DWORD [ebp-12]
            .skip:

            inc DWORD [ebp-4]
            jmp .loop_c
        .end_c:
        ; check row

        ret_if_true DWORD [ebp-12], 2, jge, 0

        inc DWORD [ebp-8]
        jmp .loop_n
    .end_n:
    jmp .end

    .error:
    print_str_crlf se_grid_check_args
    jmp .end

    .end:
    POST_FUNC 1


; Returns in eax 1 if the grid is valid, 0 otherwise
grid_is_valid:
    PRE_FUNC

    ; [ebp-4] counter
    sub esp, 0x4

    ;
    ; check each id (used as row id, column id and block id)
    ;

    mov DWORD [ebp-4], 0
    .loop:
        cmp DWORD [ebp-4], 10
        jge .end

        %macro GRID_CHECK 1
            push %1
            push DWORD [ebp-4]
            call grid_check
            add esp, 0x4
            ret_if_true eax, 0, je, 0
        %endmacro

        GRID_CHECK CHECK_ROW
        GRID_CHECK CHECK_COLUMNS
        GRID_CHECK CHECK_BLOCK

        inc DWORD [ebp-4]
        jmp .loop
    .end:

    POST_FUNC 1


; main recursive function that solve the grid
; Arg:
;   an id from 0 to 80 indicating the current cell to fill
grid_solve:
    PRE_FUNC

    %macro RECURSE 0
        push DWORD [ebp + 8]
        inc DWORD [esp]
        call grid_solve
        add esp, 0x4
    %endmacro

    ; [ebp - 4]: counter
    sub esp, 0x4

    ; if grid is full (ie solved)
    cmp DWORD [ebp + 8], 81
    je .solved

; debug print
    print_str_crlf s_sep
    print_int_dec DWORD [ebp + 8]
    print_str_crlf s_space
    call print_grid

    ; if cell is not 0, it is already filled, just recurse
    ; else try every number
    mov eax, [ebp + 8]
    cmp DWORD [grid + 4*eax], 0
    jne .recurse
    je .try

    .recurse:
    RECURSE
    jmp .end

    .try:
    mov DWORD [ebp - 4], 1
    .loop:
        cmp DWORD [ebp - 4], 10
        jge .loop_end

        ; try a number
        mov eax, [ebp + 8]
        mov ebx, [ebp - 4]
        mov [grid + 4*eax], ebx

        ; if grid.is_valid(), recurse
        call grid_is_valid
        cmp eax, 1
        jne .not_valid
        RECURSE
        .not_valid:

        inc DWORD [ebp - 4]
        jmp .loop
    .loop_end:

    ; restore cell's value before returning (which was 0)
    mov eax, [ebp + 8]
    mov DWORD [grid + 4*eax], 0

    jmp .end

    .solved:
    print_str_crlf s_solved
    call print_grid

    call grid_is_valid
    print_int_dec eax
    push s_crlf
    call print_str
    add esp, 0x4

    push 0
    call exit
    jmp .end

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
        cmp BYTE [ecx], 0
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

