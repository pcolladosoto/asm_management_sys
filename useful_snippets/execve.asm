global main

section .data

bash db "/bin/bash", 0x0

cls db "/mw_repo/useful_notes/cls", 0x0

tput_exec:
    db "/usr/bin/tput", 0x0

tput_arga:
    db "-Txterm", 0x0

tput_argb:
    db "clear", 0x0

tput_args:
    db "/usr/bin/tput", 0x0, "-Txterm", 0x0, "clear", 0x0

section .text

main:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov rax, tput_exec
    mov [rbp - 16], rax
    mov rax, tput_arga
    mov [rbp - 12], rax
    mov rax, tput_argb
    mov [rbp - 8], rax
    mov rax, 0
    mov [rbp - 4], rax
    ; mov rax, 0
    ; push rax
    ; mov rax, tput_argb
    ; push rax
    ; mov rax, tput_arga
    ; push rax
    ; mov rax, tput_exec
    ; push rax

    mov rax, 11
    mov rbx, cls
    ; lea rcx, [rbp - 16]
    mov rcx, 0
    mov rdx, 0
    int 0x80
    ; Exit!
    ; mov rax, 1
    ; mov rbx, 0
    ; int 0x80
    jmp .cend

.cend:
    ; Return zero if everything went well
    xor rax, rax
    pop rbx
    pop rcx
    pop rdx
    pop rdi

    ; Reset everything to the way it was
    add rsp, 32
    pop rbp
    ret