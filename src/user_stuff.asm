; Subroutines regarding the management of users

; See main.asm for an explanation on the %include syntax
%ifdef DCKR
    ; Docker includes
    %include "../libs/io_v6.asm"
    %include "output_msgs.asm"
    %include "misc_subroutines.asm"
%else
    ; SASM Includes
    %include "/home/malware/mw_repo/Cw1_management_system/libs/io_v6.asm"
    %include "/home/malware/mw_repo/Cw1_management_system/src/output_msgs.asm"
    %include "/home/malware/mw_repo/Cw1_management_system/src/misc_subroutines.asm"
%endif

; User data structure
    ; Surename -> A string of at most 64 chars
    ; First Name -> A string of at most 64 chars
    ; Dep -> Any of:
                ; Development
                ; IT Support
                ; Finance
                ; HR
        ; The largest string is "Development" which is 11 chars long!
    ; User ID -> In the form of qXXXXXXX, where XXXXXXX is a 7 digit number
    ; Email -> With the userID@faa.fii.fuu.fe ending

    ; The above suggests we need to reserve: (64 + 1) * 2 + (11 + 1) + (8 + 1) + (23 + 1) = 175 Bytes per user
    ; We then need to reserve 175 * 100 = 17500 bytes to fit all the user data
    ; Record validity ->
        ; TL;DR -> The first byte of the department field marks record validity:
            ; Byte == NULL -> Invalidated record
            ; BYTE != NULL -> Valid record
        ; If we think about what we store into memory we'll soon see it's just a succession of strings separated
            ; by NULL charaters (i.e. we are sticking to C's sentinel style). As we are the ones designing the data
            ; structure and interpreting it we can confer the meaning we want to any particular byte. As we'll always
            ; have a department for the records we input given our type checks we can rest assured the first byte of
            ; the departmentt field in any valid user record will be a NON NULL. Then, to check if a given
            ; record is valid or not we can just check if this initial byte is NULL or not and act in consequence.
            ; This byte is effectively the record validity flag. Now, in order for this scheme to work we have
            ; defined our record buffer in the data section instead of the bss one because we MUST initialize it to 0
            ; manually. Otherwise we'll see that we have rubbish values (random ones, the last values at a given position)
            ; if we reserve data and we can't realy on the validity flag being correctly set... After that, what we need to
            ; do to delete a record is just update the current user count and place a NULL character (i.e. 0x0) in a
            ; record's department first byte. As the functions printing or looking for records will check to see that byte's
            ; value we can rest assured everything will work correctly. This means deleting a record is a very cheap operation!

; Data section needed for validating and storing user data
section .data

; Constants regarding the sizes of the elements conforming a user data record

; Maximum number of users
MAX_USERS equ 100

; Lenght in Bytes of each user record
B_PER_USER equ 175

; Size of both name fields in the record
NAME_SIZE equ 65

; Size of the department field in the record
DEP_SIZE equ 12

; Size of the user ID in the record
UID_SIZE equ 9

; Size of the e-mail in the reocord
EMAIL_SIZE equ 24

; This cuadraword contains the current number of registered users
curr_users:
    dq 0x0

; Target strings to check department validity against
v_dep_a: db "Development", 0x0
v_dep_b: db "IT Support", 0x0
v_dep_c: db "Finance", 0x0
v_dep_d: db "HR", 0x0

; General user data
email_end:
    db "@faa.fii.fuu.fe", 0x0

; This area contains all the record data. It's all initialized to 0 thanks to NASM's times keyword which will
    ; repeat the statement it precedes X number of times. In this case, we'll initialize a byte to 0x0
    ; MAX_USERS * B_PER_USER times which is the total number of bytes we need for our records. This keyword was
    ; found on section 3.2.5 of the NASM documentation
user_data:
    times MAX_USERS * B_PER_USER db 0x0

; User data handling functions
section .text

add_user:
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

    ; Load the current number of users onto RAX
    mov rax, [curr_users]
    ; Check if we have reached the user limit
    cmp rax, MAX_USERS
    ; If we have, just quit printing an error message. Otherwise we'll continue
        ; in the subroutine
    je .full

    ; Get the first free record to overwrite!
    lea rdi, [user_data + 2 * NAME_SIZE + DEP_SIZE]
    mov r8, B_PER_USER
    mov r9, MAX_USERS
    call find_free_record
    lea rbx, [rdi - (2 * NAME_SIZE + DEP_SIZE)]

    ; ************
    ; * Surename *
    ; ************

    ; Output a message asking for the surename
    mov rdi, QWORD surename_msg
    call print_string_new
    ; Read the string. A pointer to it is returned in RAX
    call read_string_new
    ; Save the pointer in RCX as we'll be using RAX for checking the
        ; length...
    mov rcx, rax
    mov rsi, rax
    call string_len
    cmp rax, 64
    jle .good_surename
    ; If the surename is longer than 64 chars print an error message
        ; othwerwise just continue normal operation
    mov rdi, QWORD long_str_err
    call print_string_new

    .good_surename:
        ; Chop the string down to 65 Bytes by forcing a NULL character
            ; in the reading buffer defined in the I/O library file
        lea rdx, [rcx + NAME_SIZE - 1]
        mov BYTE [rdx], 0x0

        ; After forcibly chopping the string copy it to the
            ; data record
        mov rsi, rcx
        mov rdi, rbx
        call copy_string

    ; **************
    ; * First Name *
    ; **************

    ; Make RBX point to the next string we have to fill out
    lea rbx, [rbx + NAME_SIZE]

    ; Output a message asking for the first name
    mov rdi, QWORD firstname_msg
    call print_string_new
    ; Read that into the I/O buffer. The pointer to the read string
        ; will be on RAX
    call read_string_new

    ; Save the pointer in RCX as we'll be using RAX for checking the
        ; length...
    mov rcx, rax
    mov rsi, rax
    call string_len
    cmp rax, 64
    jle .good_name
    ; If the name is longer than 64 chars print an error message
        ; othwerwise just continue normal operation
    mov rdi, QWORD long_str_err
    call print_string_new

    .good_name: 
        ; Chop the string down to 65 Bytes by forcing a NULL character
            ; in the reading buffer defined in the I/O library file
        lea rdx, [rcx + NAME_SIZE - 1]
        mov BYTE [rdx], 0x0

        ; Just copy the string to the user record
        mov rsi, rcx
        mov rdi, rbx
        call copy_string

    ; **************
    ; * Department *
    ; **************

    ; NOTE: We haven't coded a subroutine for validating the department because it was harder to make it reusable for
        ; the comp_data.asm file than it was to copy and paste a simple block of code. We would have needed
        ; to pass the pointers to the targets to validate against in the stack or in registers together
        ; with the number of targets to check to write a loop of some sort. That's way too much work
        ; for shaving off a couple of lines from the codebase in our opinion and it's also more error
        ; prone...

    ; Make RBX point to the next string we have to fill out
    lea rbx, [rbx + NAME_SIZE]
    .get_dep:
        ; Output a message asking for the department
        mov rdi, QWORD dep_msg
        call print_string_new
        call read_string_new

        ; As we are going to call strings_are_equal we need to save the pointer
            ; to the read string into RCX to save it! We'll then make RSI point
            ; to the targets we defined in the .data section to check if any
            ; of them check out. If they do we'll copy the string to the record
            ; area.
        mov rcx, rax
        mov rdi, rcx
        mov rsi, v_dep_a
        call strings_are_equal
        cmp rax, 0x1
        je .copy_dep
        mov rsi, v_dep_b
        call strings_are_equal
        cmp rax, 0x1
        je .copy_dep
        mov rsi, v_dep_c
        call strings_are_equal
        cmp rax, 0x1
        je .copy_dep
        mov rsi, v_dep_d
        call strings_are_equal
        cmp rax, 0x1
        je .copy_dep
        ; If none of the targets were found we'll fall through here, printing an error
            ; message and asking for the department again
        mov rdi, QWORD dep_err_msg
        call print_string_new
        jmp .get_dep

    .copy_dep:
        ; Copy the department as we know it's correct!
        mov rsi, rcx
        mov rdi, rbx
        call copy_string

        ; ***********
        ; * User ID *
        ; ***********

        ; Make RBX point to the next string we have to fill out
        lea rbx, [rbx + DEP_SIZE]
    .get_id:
        ; Output a message asking for the department
        mov rdi, QWORD uid_msg
        call print_string_new
        call read_string_new

        ; Prepare to call validate_id
            ; RCX -> Pointer to the read ID
            ; DL -> The first char we need in the ID
        mov rcx, rax
        ; mov dl, BYTE 0x70
        mov dl, BYTE 'q'
        call validate_id
        ; If the ID is indeed valid fall through. Otherwise
            ; ask for the ID again
        cmp rax, 0x1
        jne .get_id

        ; Check if the ID is already being used
            ; Get ready to call find_record
                ; RSI -> ID to be added
                ; RDI -> Initial record to llok for
                ; R8 -> Size of a data record
                ; R9 -> Number of records to analyze
                ; R10 -> Offset for validation
        mov rsi, rcx
        lea rdi, [user_data + 2 * NAME_SIZE + DEP_SIZE]
        mov r8, B_PER_USER
        mov r9, MAX_USERS
        mov r10, DEP_SIZE
        call find_record
        ; If we found the record print an error message and ask for the ID
            ; again...
        cmp rax, 0x1
        je .not_unique
        ; Otherwise just copy it and move on
        jmp .copy_id

        .not_unique:
            ; Print the error message
            mov rdi, QWORD id_not_unique_msg
            call print_string_new
            ; And ask for the ID once more
            jmp .get_id

        .copy_id:
            ; RSI is still pointing to the read ID!
            mov rdi, rbx
            call copy_string

    ; **********
    ; * E-mail *
    ; **********

    .build_email:
        ; Print a message saying we'll automatically generate the email
        mov rdi, QWORD email_msg
        call print_string_new
        ; Make RSI to the User ID we have just read
        mov rsi, rbx
        ; Make RBX point to the e-mail record area
        lea rbx, [rbx + UID_SIZE]
        mov rdi, rbx
        ; Copy the user ID into the email area
        call copy_string

        ; Copy the e-mail termination into the record area
        mov rsi, email_end
        lea rdi, [rdi + UID_SIZE - 1]
        call copy_string

        ; Update the number of users by incrementing *curr_users
        mov rax, [curr_users]
        inc rax
        mov QWORD [curr_users], rax

        ; Exit the function
        jmp .end

    .full:
        ; If we have already reached the limit of registered users print an error
            ; and exit
        mov rdi, QWORD users_full_msg
        call print_string_new

    .end:
        ; Reset the caller's context, reste the stack frame and exit
        pop rdi

        %ifdef SFRAME
            add rsp, 32
            pop rbp
        %endif

        ret

del_user:
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

    ; Save the caller's context
    push rbx
    push rcx
    push rdi

    ; IDEA -> Just delete a user by invalidating the first byte in the department name
        ; as we know that will ALWAYS be different than NULL given how we add users

    ; Load the current number of users and copy it into RAX
    mov rcx, [curr_users]

    ; If we have none, just exit with an error
    cmp rcx, 0x0
    je .err

    .get_target:
        ; Get the User ID to look for
        mov rdi, QWORD user_del_msg
        call print_string_new
        call read_string_new

        ; We'll now validate the supplied ID. The target ID will be pointed to RAX
            ; save that address to RCX so that we can use RAX for return codes
        mov rcx, rax
        ; Move the target initial letter ('q' == 0x71) to DL to set up the call
            ; to validate_id
        mov dl, BYTE 'q'
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
        lea rdi, [user_data + 2 * NAME_SIZE + DEP_SIZE]
        mov r8, B_PER_USER
        mov r9, MAX_USERS
        mov r10, DEP_SIZE
        call find_record
        cmp rax, 0x1
        jne .not_found

    ; Delete the user
    ; We are just setting the first byte of the Department name to 0
        ; to mark the record as invalid. This is NOT yet used in the code
        ; however, as we would need to traverse all MAX_USERS evvery time
        ; we are to print them for this to be employed...
    lea rcx, [rdi - DEP_SIZE]
    mov BYTE [rcx], 0x0

    ; Decrement the total number of users
    dec QWORD [curr_users]

    ; Print a message containing the deleted user's ID which is pointed
        ; to by RBX.
    lea rcx, [rcx + DEP_SIZE]
    mov rdi, QWORD del_msg
    call print_string_new
    mov rdi, rcx
    call print_string_new
    call print_nl_new

    ; Bomb the userID with a NULL character so that it doesn't act up later on!
    mov BYTE [rcx], 0x0
    jmp .end

    .not_found:
        mov rdi, QWORD user_not_found_msg
        call print_string_new
        jmp .end

    ; Quit with an error message if there are no users
    .err:
        mov rdi, QWORD no_users_msg
        call print_string_new

    .end:
        ; Reset the caller's register context
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

print_users:
    ; Input paramters:
        ; NONE

    ; Return value:
        ; NONE

    %ifdef SFRAME
        ; Set up a stack frame
        push rbp
        mov rbp, rsp
        sub rsp, 32
    %endif

    ; Save the caller's register context
    push rdx
    push rbx
    push rcx
    push rdi
    push r9

    ; Get the current number of users
    mov rdx, [curr_users]

    ; If we have none quit with an error
    cmp rdx, 0x0
    je .err

    ; Register breakdown:
        ; RBX -> Loop counter
        ; RCX -> Pointer to each user record
        ; RDX -> Total number of users
        ; R9 -> Aux register for checking record validity

    ; Initialize the loop counter
    xor rbx, rbx

    ; Make RCX point to the first record
    lea rcx, [user_data]
    .loop:
        ; If we have already printed all the users exit the loop
        cmp rbx, MAX_USERS
        je .loope

        ; Check the record's validity
        lea r9, [rcx + 2 * NAME_SIZE]
        mov r9b, BYTE [r9]
        cmp r9b, 0x0
        je .next_record

        ; Print a message telling us the user index we are about to print
        mov rdi, QWORD print_new_user_msg
        call print_string_new
        mov rdi, rbx
        call print_int_new
        call print_nl_new

        ; Prepare to call print_user. It expects a pointer to the user data record
            ; on RDI so we'll just copy RCX into it
        mov rdi, rcx
        call print_user

        .next_record:
            ; After the call we make RCX point to the same record
            lea rcx, [rcx + B_PER_USER]

            ; Increment the number of users we have already printed
            inc rbx

            ; And inconditionally jump back to the loop
            jmp .loop

    .err:
        ; If we had no registered users print the error message and fall through to
            ; the subroutine's end
        mov rdi, QWORD no_users_msg
        call print_string_new

    .loope:
        ; Reset the caller's register context
        pop r9
        pop rdi
        pop rcx
        pop rbx
        pop rdx

        %ifdef SFRAME
            ; Reset the stack frame
            add rsp, 32
            pop rbp
        %endif

        ; And return
        ret

print_user:
    ; Input paramters:
        ; RDI -> Pointer to the user data record to print

    ; Return value:
        ; NONE

    %ifdef SFRAME
        ; Set up a stack frame
        push rbp
        mov rbp, rsp
        sub rsp, 32
    %endif

    ; Save the caller's register context
    push rsi
    push rdi

    ; Move the pointer to the user data record onto RSI as we need
        ; to modify RDI for calling print_string new
    mov rsi, rdi

    ; Print the corresponding message followed by the string pointed to by RSI
    mov rdi, QWORD print_surename_msg
    call print_string_new
    mov rdi, rsi
    call print_string_new
    call print_nl_new

    ; Make RSI point to the next field of data
    lea rsi, [rsi + NAME_SIZE]

    ; And print the next field
    mov rdi, QWORD print_name_msg
    call print_string_new
    mov rdi, rsi
    call print_string_new
    call print_nl_new

    ; Make RSI point to the next field of data
    lea rsi, [rsi + NAME_SIZE]

    ; And print the next field
    mov rdi, QWORD print_dep_msg
    call print_string_new
    mov rdi, rsi
    call print_string_new
    call print_nl_new

    ; Make RSI point to the next field of data
    lea rsi, [rsi + DEP_SIZE]

    ; And print the next field
    mov rdi, QWORD print_uid_msg
    call print_string_new
    mov rdi, rsi
    call print_string_new
    call print_nl_new

    ; Make RSI point to the next field of data
    lea rsi, [rsi + UID_SIZE]

    ; And print the next field
    mov rdi, QWORD print_email_msg
    call print_string_new
    mov rdi, rsi
    call print_string_new
    call print_nl_new

    ; Reset the caller's context
    pop rdi
    pop rsi

    %ifdef SFRAME
        ; Get rid of the stack frame
        add rsp, 32
        pop rbp
    %endif

    ; And return
    ret

count_users:
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

    ; Save the caller's context
    push rdi

    ; Print the first message
    mov rdi, QWORD n_users_msg_a
    call print_string_new

    ; Move the total number of users into RDI
    mov rdi, [curr_users]
    call print_int_new

    ; And print the second message
    mov rdi, QWORD n_users_msg_b
    call print_string_new

    ; Retrieve the caller's context
    pop rdi

    %ifdef SFRAME
        ; Reset the frame stack
        add rsp, 32
        pop rbp
    %endif

    ; And return
    ret

find_user:
    ; Input paramters:
        ; NONE

    ; Return value:
        ; NONE

    %ifdef SFRAME
        ; Set up a new stack frame
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

    ; Move the current number of users into RDX
    mov rdx, [curr_users]
    ; If we have none print an error message and exit
    cmp rdx, 0x0
    je .err

    .get_target:
        ; Get the User ID to look for
        mov rdi, QWORD user_lookup_msg
        call print_string_new
        call read_string_new

        ; We'll now validate the supplied ID. The target ID will be pointed to RAX
            ; save that address to RCX so that we can use RAX for return codes
        mov rcx, rax
        ; Move the target initial letter ('q' == 0x70) to DL to set up the call
            ; to validate_id
        mov dl, BYTE 'q'
        call validate_id
        ; If the ID is NOT valid ask for a new one. Otherwise we'll just fall through
            ; and continue the search
        cmp rax, 0x1
        jne .get_target

        ; Get tready to call find_record:
            ; RSI -> Pointer to the supplied ID
            ; RDI -> Pointer to the User ID of the first record
            ; R8 -> The byte offset between records
            ; R9 -> The current number of user records
        mov rsi, rcx
        lea rdi, [user_data + 2 * NAME_SIZE + DEP_SIZE]
        mov r8, B_PER_USER
        ; Note we need to load the current number of users from memory because we are using
            ; the DL register above to pass the target initial letter of the ID...
        ; mov r9, [curr_users]
        mov r9, MAX_USERS
        mov r10, DEP_SIZE
        call find_record
        ; If the record is NOT found we'll jump to the .not_found tag. Otherwise
            ; we'll fall through to the .found tag.
        cmp rax, 0x1
        jne .not_found

    .found:
        ; Get rid of the offset we introduced in RDI for printing the user information.
            ; We applied the offset because the serach was based on the user ID BUT we
            ; now want to take a look at the entire record! Note find_record returns
            ; the address of the matching field in RDI.
        lea rdi, [rdi - (2 * NAME_SIZE + DEP_SIZE)]
        ; Print the user
        call print_user
        ; And quit
        jmp .end

    .err:
        ; Print an error message and quit
        mov rdi, QWORD no_users_msg
        call print_string_new
        jmp .end

    .not_found:
        ; Inform the user we couldn't find the target and fall through to the
            ; subroutine's end
        mov rdi, QWORD user_not_found_msg
        call print_string_new

    .end:
        ; Reset the caller's register state
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
