; Subroutines regarding the management of computers

; See main.asm for an explanation on the %include syntax
%ifdef DCKR
    ; Docker includes
    %include "../libs/io_v6.asm"
    %include "output_msgs.asm"
    %include "misc_subroutines.asm"
%else
    ; SASM includes
    %include "/home/malware/mw_repo/Cw1_management_system/libs/io_v6.asm"
    %include "/home/malware/mw_repo/Cw1_management_system/src/output_msgs.asm"
    %include "/home/malware/mw_repo/Cw1_management_system/src/misc_subroutines.asm"
%endif

; Comp data structure
    ; Comp Name -> In the form of cXXXXXXX, where XXXXXXX is a 7 digit number
    ; IP Address -> In the form XXX.XXX.XXX.XXX where X is a digit
    ; OS -> Any of:
                ; Linux
                ; Windows
                ; Mac OSX
        ; The largest string is 7 chars long!
    ; User ID of the user -> In the form of qXXXXXXX, where XXXXXXX is a 7 digit number
    ; Date of purchase -> In the dd/mm/yyyy format where, d, m and y are digits!

    ; The above suggests we need to reserve: (8 + 1) + (15 + 1) + (7 + 1) + (8 + 1) + (10 + 1) = 53 Bytes per computer
    ; We then need to reserve 53 * 500 = 26500 bytes to fit all the user data
    ;
    ; Record validity ->
        ; TL;DR -> The first byte of the computer ID field marks record validity
            ; Byte == NULL -> Invalidated record
            ; BYTE != NULL -> Valid record
        ; If we think about what we store into memory we'll soon see it's just a succession of strings separated
            ; by NULL charaters (i.e. we are sticking to C's sentinel style). As we are the ones designing the data
            ; structure and interpreting it we can confer the meaning we want to any particular byte. As we'll always
            ; have a computer ID for the records we input given our type checks we can rest assured the first byte of
            ; any valid computer record will be the 'c' character which is definitley NOT NULL. Then, to check if a
            ; given record is valid or not we can just check if this initial byte is NULL or not and act in consequence.
            ; This byte is effectively the record validity flag. Now, in order for this scheme to work we have
            ; defined our record buffer in the data section instead of the bss one because we MUST initialize it to 0
            ; manually. Otherwise we'll see that we have rubbish values (random ones, the last values at a given position)
            ; if we reserve data and we can't realy on the validity flag being correctly set... After that, what we need to
            ; do to delete a record is just update the current computer count and place a NULL character (i.e. 0x0) in a
            ; record's first byte. As the functions printing or looking for records will check to see that byte's value we
            ; can rest assured everything will work correctly. This means deleting a record is a very cheap operation!

; Data section needed for validating and storing computer data
section .data

; Constants regarding the sizes of the elements conforming a user data record

; Maximum number of computers
MAX_COMPS equ 500

; Length in Bytes of each computer record
B_PER_COMP equ 53

; Length in Bytes of the computer ID field
CID_SIZE equ 9

; Length in Bytes of the computer IP address
IP_SIZE equ 16

; Length in Bytes of the OS field
OS_SIZE equ 8

; Lenght in Bytes of the user ID field
UID_SIZE equ 9

; Length in bytes of the date field
DATE_SIZE equ 11

; This quadraword contains the current number of registered computers
curr_comps:
    dq 0x0

; Target strings to check OS validity against
v_os_a: db "Linux", 0x0
v_os_b: db "Windows", 0x0
v_os_c: db "Mac OSX", 0x0

; This area contains all the record data. It's all initialized to 0 thanks to NASM's times keyword which will
    ; repeat the statement it precedes X number of times. In this case, we'll initialize a byte to 0x0
    ; MAX_COMPS * B_PER_COMP times which is the total number of bytes we need for our records. This keyword was
    ; found on section 3.2.5 of the NASM documentation
comp_data:
    times MAX_COMPS * B_PER_COMP db 0x0

; Computer data handling functions
section .text

add_comp:
    ; Input paramters:
        ; NONE

    ; Return value:
        ; NONE

    %ifdef SFRAME
        ; Create a new stack frame
        push rbp
        mov rbp, rsp
        sub rsp, 32
    %endif

    ; Save the callers stack context
    push rdi

    ; Load the current number of computers onto RAX
    mov rax, [curr_comps]
    ; Check if we have reached the computer limit
    cmp rax, MAX_COMPS
    ; If we have, just quit printing an error message. Otherwise we'll continue
        ; in the subroutine
    je .full

    ; Get the first free record to overwrite!
    lea rdi, [comp_data]
    mov r8, B_PER_COMP
    mov r9, MAX_COMPS
    call find_free_record
    lea rbx, [rdi]
    
    ; ***************
    ; * Computer ID *
    ; ***************

    .get_cid:
        ; Print a message asking for the computer ID
        mov rdi, QWORD cid_msg
        call print_string_new
        ; Read the incoming string
        call read_string_new

        ; Validate computer ID. We need to provide the pointer to the read
            ; string on RCX
        mov rcx, rax
        ; Load the first character to look for in DL ('c' == 0x63)
        mov dl, BYTE 'c'
        call validate_id
        ; If the ID wasn't valid just ask for it again as validate_id is in charge
            ; of printing error messages. Otherwise just fall through to the uniqueness
        cmp rax, 0x1
        jne .get_cid

        ; Provide a pointer to the read string on RSI so that find_record finds it
        mov rsi, rcx
        ; Load the address of the first computer ID to check. As the ID is the first field
            ; in the records we don't need to apply any offset!
        lea rdi, [comp_data]
        ; Tell find_record how big the records are so that it knows by how much the pointer
            ; should change
        mov r8, B_PER_COMP
        ; And tell find_record how many computers we currently have
        mov r9, MAX_COMPS
        ; We are looking at the first byte of the coputer ID -> No offset needed
        xor r10, r10
        call find_record
        ; If the ID was found it means the one provided is NOT unique! We'll
            ; print an error message and ask for it again
        cmp rax, 0x1
        je .not_unique
        ; Otherwise just copy the ID and move on to the next piece of data
        jmp .copy_cid

        .not_unique:
            ; Print an error message
            mov rdi, QWORD id_not_unique_msg
            call print_string_new
            ; And unconditionally ask for a new ID
            jmp .get_cid

        .copy_cid:
            ; We'll just copy the ID to the record structure and move on
            mov rdi, rbx
            call copy_string

        ; **************
        ; * IP Address *
        ; **************

        ; Make RBX point to the next field to be filled by adding the previous field's
            ; size to it.
        lea rbx, [rbx + CID_SIZE]
    .get_ip:
        ; Print a message asking for the IP address
        mov rdi, QWORD ip_msg
        call print_string_new
        call read_string_new

        ; Just move the pointer to the read string into RDI so that validate_ip can
            ; find it
        mov rdi, rax
        call validate_ip
        ; If the IP is NOT valid print an error message and ask for it again. Otherwise we'll fall
            ; thorugh and copy the IP to the record itself.
        cmp rax, 0x0
        je .ip_err

        ; Just move the pointer we stored in RDI to RSI and the pointer to the record field to be
            ; filled to RDI so that copy_string performs the copy correctly
        mov rsi, rdi
        mov rdi, rbx
        call copy_string
        ; Time to get the OS info
        jmp .get_os_init

    .ip_err:
        ; Print an error message is the IP is NOT valid
        mov rdi, QWORD ip_err_msg
        call print_string_new
        ; And ask for a new one
        jmp .get_ip

    ; ******
    ; * OS *
    ; ******

    ; NOTE: We haven't coded a subroutine for validating the OS because it was harder to make it reusable for
        ; the user_data.asm file than it was to copy and paste a simple block of code. We would have needed
        ; to pass the pointers to the targets to validate against in the stack or in registers together
        ; with the number of targets to check to write a loop of some sort. That's way too much work
        ; for shaving off a couple of lines from the codebase in our opinion and it's also more error
        ; prone...

    .get_os_init:
        ; As before, make RBX point to the next field we need to fill in. We are using a .get_os_init
            ; tag so that we can jump to .get_os to get a new OS should a non-valid one be provided.
            ; if this increment were applied under .get_os we would copy the OS in a wrong address
            ; if we got a bad option and we need to be able to reference this instruction from
            ; the previous section so that we can continue with the subroutine's execution.
        lea rbx, [rbx + IP_SIZE]
    .get_os:
        ; Print a message asking for the OS
        mov rdi, QWORD os_msg
        call print_string_new
        call read_string_new

        ; IDEA -> Try using test instead of cmp as that's faster given it performs binary arithmetic instead
            ; of a subtraction. Be careful with the result you expect though!

        ; Save the pointer to the read string on RCX so that we can use RAX for strings_are_equal's return codes
        mov rcx, rax
        ; Pass the target to validate again to RDI
        mov rdi, rcx
        mov rsi, v_os_a
        call strings_are_equal
        ; If we have a match we can copy the provided information. Otherwise continue to check
        cmp rax, 0x1
        je .copy_os
        mov rsi, v_os_b
        call strings_are_equal
         ; If we have a match we can copy the provided information. Otherwise continue to check
        cmp rax, 0x1
        je .copy_os
        mov rsi, v_os_c
        call strings_are_equal
         ; If we have a match we can copy the provided information. Otherwise we'll fall through
            ; to printing the error message and asking for a new option
        cmp rax, 0x1
        je .copy_os

        ; Print an error message as none of the targets were provided so a bad option was given
        mov rdi, QWORD os_err_msg
        call print_string_new
        ; Go and ask for the OS again
        jmp .get_os

    .copy_os:
        ; Copy the OS as we know it's correct and fall though to the next section
        mov rsi, rcx
        mov rdi, rbx
        call copy_string

    ; ***********
    ; * User ID *
    ; ***********

    ; Make RBX point to the next field we have to fill
    lea rbx, [rbx + OS_SIZE]
    .get_uid:
        ; Print a message asking for the user ID
        mov rdi, QWORD cuid_msg
        call print_string_new
        call read_string_new

        ; Move the pointer to RCX so that we get ready for calling validate_id
        mov rcx, rax
        ; Move the expected initial letter ('q' == 0x70) to DL
        mov dl, BYTE 0x71
        call validate_id
        ; If the ID is valid fall though but if it's not print an error message and ask
            ; for a new one
        cmp rax, 0x1
        jne .get_uid

        ; IDEA -> Maybe check if the User ID exists?
            ; We would need access to the 'user_data' address though...

        ; Prepare to call copy_string by loading the correct addresses into RSI and RDX
            ; and continue to the next section
        mov rsi, rcx
        mov rdi, rbx
        call copy_string

    ; ********
    ; * Date *
    ; ********

    ; Make RBX point to the next field we have to fill
    lea rbx, [rbx + UID_SIZE]
    .get_date:
        ; Print a message asking for the date
        mov rdi, QWORD date_msg
        call print_string_new
        call read_string_new

        ; Copy the pointer to the read string into RDI so that we can call validate_date
        mov rdi, rax
        call validate_date
        ; If the date is valid fall though to copying it, otherwise ask for the date again as
            ; validate_date takes care of outputing error messages
        cmp rax, 0x1
        jne .get_date

        ; Load the correct values into registers so that we can call copy_string
        mov rsi, rdi
        mov rdi, rbx
        call copy_string

        ; Update the number of computers we have currently registered
        mov rax, [curr_comps]
        inc rax
        mov QWORD [curr_comps], rax

        ; And prepare to exit the function
        jmp .end


    .full:
        ; If we have reached the limit of registered computers just print an error message and quit
            ; by falling through to the end
        mov rdi, QWORD comps_full_msg
        call print_string_new

    .end:
        ; Reset the caller's context
        pop rdi

        %ifdef SFRAME
            ; Reset the frame stack
            add rsp, 32
            pop rbp
        %endif

        ; And return
        ret

del_comp:
    ; Input paramters:
        ; NONE

    ; Return value:
        ; NONE

    %ifdef SFRAME
        ; Prepare a stack frame
        push rbp
        mov rbp, rsp
        sub rsp, 32
    %endif

    ; Save the caller's register context
    push rbx
    push rcx
    push rdi

    ; Load the current number of computers into RCX
    mov rcx, [curr_comps]
    ; If we have none, print an error message and exit, otherwise fall through to the rest of the
        ; subroutine
    cmp rcx, 0x0
    je .err

    .get_target:
        ; Get the User ID to look for
        mov rdi, QWORD comp_del_msg
        call print_string_new
        call read_string_new

        ; We'll now validate the supplied ID. The target ID will be pointed to RAX
            ; save that address to RCX so that we can use RAX for return codes
        mov rcx, rax
        ; Move the target initial letter ('c' == 0x70) to DL to set up the call
            ; to validate_id
        mov dl, BYTE 'c'
        call validate_id
        ; If the ID is NOT valid ask for a new one. Otherwise we'll just fall through
            ; and continue the search
        cmp rax, 0x1
        jne .get_target

    ; Check if the ID is already being used
        ; Get ready to call find_record
            ; RSI -> ID to be added
            ; RDI -> Initial record to look for
            ; R8 -> Size of a data record
            ; R9 -> Number of records to analyze
    mov rsi, rcx
    lea rdi, [comp_data]
    mov r8, B_PER_COMP
    mov r9, MAX_COMPS
    xor r10, r10
    call find_record
    cmp rax, 0x1
    jne .not_found

    ; Decrement the number of computers and save that back to memory
    dec QWORD [curr_comps]

    ; Get the address of the last record's computer ID (i.e. the one we are to delete)
        ; so that we can print it and inform the user it was indeed deleted. We'll load
        ; the address into RBX and then call print_string_new
    lea rbx, [rdi]
    mov rdi, QWORD del_msg
    call print_string_new
    mov rdi, rbx
    call print_string_new
    call print_nl_new

    ; Bomb the computer ID's first byte to invalidate the record
    mov BYTE [rbx], 0x0

    ; Just exit the subroutine
    jmp .end

    .not_found:
        mov rdi, QWORD comp_not_found_msg
        call print_string_new
        jmp .end

    .err:
        ; Print an error message and fall through to the subroutine's end
        mov rdi, QWORD no_comps_msg
        call print_string_new

    .end:
        ; Restore the caller's context
        pop rdi
        pop rcx
        pop rbx

        %ifdef SFRAME
            ; Reset the stack frame
            add rsp, 32
            pop rbp
        %endif

        ; And return
        ret

print_comps:
    ; Input paramters:
        ; NONE

    ; Return value:
        ; NONE

    %ifdef SFRAME
        ; Prepare a stack frame
        push rbp
        mov rbp, rsp
        sub rsp, 32
    %endif

    ; Save the caller's register context
    push rdx
    push rbx
    push rcx
    push rdi

    ; Get the current number of registered computers and store it into RDX
    mov rdx, [curr_comps]
    ; If we have none, print an error message and exit
    cmp rdx, 0x0
    je .err

    ; Register breakdown:
        ; RBX -> Loop counter
        ; RCX -> Pointer to the computer record we are currently printing
        ; RDX -> Current number of computers
        ; R9 -> Auxiliary register for checking for a record's validity

    ; Initialize the loop counter to 0
    xor rbx, rbx

    ; Load the address of the initial record to RCX
    lea rcx, [comp_data]
    .loop:
        ; Check if we have already printed all the records
        cmp rbx, MAX_COMPS
        ; If we have just exit the function
        je .loope

        ; Check the record's validity
        lea r9, [rcx]
        mov r9b, BYTE [r9]
        cmp r9b, 0x0
        je .next_record

        ; Print a message telling the user the index of the current record
        mov rdi, QWORD print_new_comp_msg
        call print_string_new
        mov rdi, rbx
        call print_int_new
        call print_nl_new

        ; Move the pointer to the current record into RDI so that print_comp
            ; know's where to find the data to print
        mov rdi, rcx
        call print_comp

        .next_record:
            ; Make RCX point to the next record by incrementing it by the size of a
                ; computer record. Note we don't use RDI to save these addresses as
                ; we need it for passing parameters to print_string_new
            lea rcx, [rcx + B_PER_COMP]

        ; Increment the loop counter (i.e. the number of records we have already printed)
        inc rbx
        ; And get into the loop again
        jmp .loop

    .err:
        ; Print an error message and fall through to the subroutine's end
        mov rdi, QWORD no_users_msg
        call print_string_new

    .loope:
        ; Reset the caller's register context
        pop rdi
        pop rcx
        pop rbx
        pop rdx

        %ifdef SFRAME
            ; Reset the stack frame
            add rsp, 32
            pop rbp
        %endif

        ; And return from the subroutine
        ret

print_comp:
    ; Input paramters:
        ; RDI -> Address of the record to print

    ; Return value:
        ; NONE

    %ifdef SFRAME
        ; Get a new stack frame
        push rbp
        mov rbp, rsp
        sub rsp, 32
    %endif

    ; Save the caller's register context
    push rsi
    push rdi

    ; Copy the pointer to the current record into RSI so that we can use
        ; RDI to call print_string new
    mov rsi, rdi

    ; Print the corresponding message followed by the string pointed to by RSI
    mov rdi, QWORD print_cid_msg
    call print_string_new
    mov rdi, rsi
    call print_string_new
    call print_nl_new

    ; Make RSI point to the next field of data
    lea rsi, [rsi + CID_SIZE]

    ; And print the next field
    mov rdi, QWORD print_ip_msg
    call print_string_new
    mov rdi, rsi
    call print_string_new
    call print_nl_new

    ; Make RSI point to the next field of data
    lea rsi, [rsi + IP_SIZE]

    ; And print the next field
    mov rdi, QWORD print_os_msg
    call print_string_new
    mov rdi, rsi
    call print_string_new
    call print_nl_new

    ; Make RSI point to the next field of data
    lea rsi, [rsi + OS_SIZE]

    ; And print the next field
    mov rdi, QWORD print_uid_msg
    call print_string_new
    mov rdi, rsi
    call print_string_new
    call print_nl_new

    ; Make RSI point to the next field of data
    lea rsi, [rsi + UID_SIZE]

    ; And print the next field
    mov rdi, QWORD print_date_msg
    call print_string_new
    mov rdi, rsi
    call print_string_new
    call print_nl_new

    ; Reset the caller's context
    pop rdi
    pop rsi

    %ifdef SFRAME
        ; Reset the stack frame
        add rsp, 32
        pop rbp
    %endif

    ; And return
    ret

count_comps:
    ; Input paramters:
        ; NONE

    ; Return value:
        ; NONE

    %ifdef SFRAME
        ; Set a new stack frame
        push rbp
        mov rbp, rsp
        sub rsp, 32
    %endif

    ; Save the caller's register context
    push rdi

    ; Print the first message
    mov rdi, QWORD n_comps_msg_a
    call print_string_new

    ; Move the total number of users into RDI
    mov rdi, [curr_comps]
    call print_int_new

    ; Print the second message
    mov rdi, QWORD n_comps_msg_b
    call print_string_new

    ; Reset the caller's context
    pop rdi

    %ifdef SFRAME
        ; Reset the stack frame
        add rsp, 32
        pop rbp
    %endif

    ; And return
    ret

find_comp:
    ; Input paramters:
        ; NONE

    ; Return value:
        ; NONE

    %ifdef SFRAME
        ; Set a new stack frame
        push rbp
        mov rbp, rsp
        sub rsp, 32
    %endif

    ; Save the caller's register context
    push rsi
    push rax
    push rdx
    push rbx
    push rcx
    push rdi

    ; Move the total number of computers currently registerd to RDX
    mov rdx, [curr_comps]
    ; If we have none, print an error message and exit, otherwise
        ; fall through to the rest of the subroutine's body
    cmp rdx, 0x0
    je .err

    .get_target:
        ; Get the computer ID to look for
        mov rdi, QWORD comp_lookup_msg
        call print_string_new
        call read_string_new

        ; Move the address of the read ID into RCX so that we can
            ; call validate_id
        mov rcx, rax
        ; Move the target first character into DL ('c' == 0x63)
        mov dl, BYTE 0x63
        call validate_id
        ; If the ID is valid fall through, otherwise ask for a new one
        cmp rax, 0x1
        jne .get_target

        ; Prepare to call validate_id
            ; RSI -> Pointer to the string to look for
            ; RDI -> Address of the initial field to analyze (note the ID is the record's first
                ; field so we need not apply any offset)
            ; R8 -> Size of a computer record
            ; R9 -> Total number of records to search
        mov rsi, rcx
        lea rdi, [comp_data]
        mov r8, B_PER_COMP
        ; Note we need to load the current number of users from memory because we are using
            ; the DL register above to pass the target initial letter of the ID...
        mov r9, MAX_COMPS
        xor r10, r10
        call find_record
        ; If the record was found fall thorugh to the next section, otherwise print a message
            ; saying no records were found and exit
        cmp rax, 0x1
        jne .not_found

    .found:
        ; As we have no offset to get rid off we can just call print_comp given find_record returns the
            ; address of the matching record on RDI. We'll then just quit.
        call print_comp
        jmp .end

    .err:
        ; If there were no computers registered in the system output an error message
            ; and exit
        mov rdi, QWORD no_comps_msg
        call print_string_new
        jmp .end

    .not_found:
        ; If the record couldn't be found print a message informing the user and fall through
            ; to the subroutine's end
        mov rdi, QWORD comp_not_found_msg
        call print_string_new

    .end:
        ; Restore the caller's register context
        pop rdi
        pop rcx
        pop rbx
        pop rdx
        pop rax
        pop rsi

        %ifdef SFRAME
            ; Reset the stack frame
            add rsp, 32
            pop rbp
        %endif

        ; And return
        ret
