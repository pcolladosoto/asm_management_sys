; Management System implementation on ASM

; NOTE -> We are NOT saving RAX as part of the caller's register context
            ; as it's commonly used for the calle's return code!

; The following directives control what libraries to include so that
    ; we can compile the program both on our Docker and Lubuntu environments
    ; as the %include directives fed to SASM should use absolute paths to avoid
    ; headaches.

%ifdef DCKR
    ; Docker includes
        ; Note we pass the -dDCKR flag to nasm in our Makefile!
        ; We have seen this technique in section 2.1.20 of the
        ; NASM Documentation.

    ; I/O functions
    %include "../libs/io_v6.asm"

    ; Subroutines performing operations on the user data
    %include "user_stuff.asm"

    ; Subroutines performing operations on the computer data
    %include "comp_stuff.asm"
%else
    ; SASM includes
    %include "/home/malware/mw_repo/Cw1_management_system/libs/io_v6.asm"
    %include "/home/malware/mw_repo/Cw1_management_system/src/user_stuff.asm"
    %include "/home/malware/mw_repo/Cw1_management_system/src/comp_stuff.asm"
%endif

; Define the program's entrypoint!
global main

; Define main's data
section .data

; Note that by inspecting any ASCII table we see how:
    ; + ---------------------------------------------------- +
    ; | Special Character     --   Dec Value   --  Hex Value |
    ; | Horizontal Tab (HT)   --      9        --    0x9     |
    ; | Newline/Linefeed (LF) --      10       --    0xA     |
    ; |        NULL           --      0        --    0x0     |
    ; + ---------------------------------------------------- +

; This string will print out the entire menu. Note the line continuation characters '\' which
    ; make nasm interpret the string as a single line so that it's easier to read in the source
menu_str:
    db "Menu:", 0xA, \
        0x9, " 1. Add user", 0xA, \
        0x9, " 2. Delete user", 0xA, \
        0x9, " 3. Search for user", 0xA, \
        0x9, " 4. List all users", 0xA, \
        0x9, " 5. Count users", 0xA, \
        0x9, " 6. Add computer", 0xA, \
        0x9, " 7. Delete computer", 0xA, \
        0x9, " 8. Search for computer", 0xA, \
        0x9, " 9. List all computers", 0xA, \
        0x9, "10. Count computers", 0xA, \
        0x9, "11. Exit", 0xA, \
        "Please enter an option --> ", 0x0

; The menu's prompt
reply:
    db "Given option --> ", 0x0

; Goodbye message
bye_msg:
    db "Thanks for using our program! :)", 0xA, 0x0

; Begin writing main's code
section .text

main:
    %ifdef MSFRAME
        ; Prepare a stack frame for the function
        push rbp
        mov rbp, rsp
        sub rsp, 32
    %endif

; Tags beginning with a dot '.' have a local scope. That let's us have tags with similar names
    ; in different subroutines without them conflicting as their scope is limited to that of the
    ; subroutine containing it. This tag let's us reprint the menu as much as we need to.
.menu:
    ; Print the menu string
    mov rdi, QWORD menu_str
    call print_string_new

    ; Read the option. Note it'll be returned on RAX
    call read_int_new

    ; As RAX contains the input value we'll just compare with several targets to see what we need to do
    cmp rax, 1
        ; If the selected option is 1 -> Jump to the .add_usr tag
        je .add_usr
    cmp rax, 2
        ; If the selected option is 2 -> Jump to the .del_usr tag
        je .del_usr
    cmp rax, 3
        ; If the selected option is 3 -> Jump to the .find_usr tag
        je .find_usr
    cmp rax, 4
        ; If the selected option is 4 -> Jump to the .ls_usrs tag
        je .ls_usrs
    cmp rax, 5
        ; If the selected option is 5 -> Jump to the .cnt_usrs tag
        je .cnt_usrs
    cmp rax, 6
        ; If the selected option is 6 -> Jump to the .add_comp tag
        je .add_comp
    cmp rax, 7
        ; If the selected option is 7 -> Jump to the .del_comp tag
        je .del_comp
    cmp rax, 8
        ; If the selected option is 8 -> Jump to the .find_comp tag
        je .find_comp
    cmp rax, 9
        ; If the selected option is 9 -> Jump to the .ls_comps tag
        je .ls_comps
    cmp rax, 10
        ; If the selected option is 10 -> Jump to the .cnt_comps tag
        je .cnt_comps
    cmp rax, 11
        ; If the selected option is 11 -> Jump to the .end tag
        je .end

    ; If we didn't jump to any of the above it means we got an incorrect option...
        ; We'll just fall through here, clearing the screen and printing the menu again
        ; as we are inconditionally jumping to the .menu tag!
    call clear_screen
    jmp .menu

.end:
    ; Print the goodbye message
    mov rdi, QWORD bye_msg
    call print_string_new

    %ifdef MSFRAME
        ; Remove the stack frame
        add rsp, 32
        pop rbp
    %endif

    ; Set the 0 return code (a.k.a it all went well!)
    xor rax, rax

    ; Exit the program
    ret

; All the following tags will just call a funtion to do the heavy lifting
    ; and then inconditionally jump to the .clear_screen tag to get ready
    ; for printing the menu again
.add_usr:
    call add_user
    jmp .clear_screen

.del_usr:
    call del_user
    jmp .clear_screen

.find_usr:
    call find_user
    jmp .clear_screen

.ls_usrs:
    call print_users
    jmp .clear_screen

.cnt_usrs:
    call count_users
    jmp .clear_screen

.add_comp:
    call add_comp
    jmp .clear_screen

.del_comp:
    call del_comp
    jmp .clear_screen

.find_comp:
    call find_comp
    jmp .clear_screen

.ls_comps:
    call print_comps
    jmp .clear_screen

.cnt_comps:
    call count_comps
    jmp .clear_screen

; We'll just call read_int_new to "freeze" the screen and wait until the user presses enter
    ; so that the displayed information is not outright deleted. We don't care about the
    ; read value so we'll just ignore it and then clear the screen. With all that done we'll
    ; then jump to the .menu tag to ask for a new option.
.clear_screen:
    call read_int_new
    call clear_screen
    jmp .menu
