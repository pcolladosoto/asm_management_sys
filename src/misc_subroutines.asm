; Miscellaneous subroutines implementing several common functionalities

; We'll be including the output messages so that we can provide valuable feedback to the user.
    ; Please refer to the main.asm file for an explanation on why we use the DCKR macro.
%ifdef DCKR
    %include "output_msgs.asm"
%else
    %include "/home/malware/mw_repo/Cw1_management_system/src/output_msgs.asm"
%endif

; As we'll be %including this file more than once we need to employ the "macro trick". Please refer
    ; to output_msgs.asm for a more comprehensive explanation of the technique.
%ifndef MISC_SUBS
    %define MISC_SUBS

section .data
    sys_fork equ 2
    sys_read equ 3
    sys_write equ 4
    sys_waitpid equ 7
    sys_execve equ 11

    ; Account for the different compilation environments!
    %ifdef DCKR
        cls:
            db "/mw_repo/bin/cls", 0x0
    %else
        cls:
            db "/home/malware/mw_repo/bin/cls", 0x0
    %endif

; We are just wrinting subroutines!
section .text

validate_ip:
    ; Input paramters:
        ; RDI -> Pointer to the string containing the IP address to be validated

    ; Return value:
        ; RAX ->
            ; 0x0 -> The IP address pointed to by RDI IS NOT valid
            ; 0x1 -> The IP address pointed to by RDI IS valid

    %ifdef SFRAME
        ; Create a stack frame
        push rbp
        mov rbp, rsp
        sub rsp, 32
    %endif

    ; Push all the registers we'll use so that the caller can be sure it's register
        ; state won't change after the call
    push rdi
    push rcx
    push rdx
    push r11
    push r12

    ; Register breakdown:
        ; AL -> 8-bit addressing of RAX. It'll hold the string character we're currently analyzing.
        ; RDX -> It'll contain a pointer to the incoming string and will be incremented until we find
                    ; a dot ('.') so that we can pop-out the IP's octect values
        ; R11 -> Number of read octects
        ; R12 -> Flag telling us if we have detected an octect by reading a NULL character instead of a
                    ; dot ('.')

    ; Initialize the registers. Note we'll call some other I/O functions so we'll need to use
        ; RDI ourselves. That's why we save the input address on RCX so that we can later
        ; reference it. We are also zeroing RAX so that we know we are loading character
        ; values into a "clean" register. You never know...
    mov rcx, rdi
    mov rdx, rdi
    xor rax, rax
    xor r11, r11
    xor r12, r12

    .loop:
        ; Read the character currently pointed to by RDX. Note the BYTE keyword makes us
            ; read only a BYTE instead of a QWORD. That's crucial as we are interested in
            ; only analyzing individual characters.
        mov al, BYTE [rdx]

        ; Check if the character we read is a dot ('.' == 0x2E)
        cmp al, 0x2E
        ; If it is, check if it's a valid octect value
        je .validate_octect
        ; If on the other hand it's a NULL character (string termination)
        cmp al, 0x0
        ; Validate the octect too but set the "found NULL" flag in R12
        je .validate_octect_null
        ; If we haven't found a terminating character just move RDX to the next byte
            ; and inconditionally jump to the beginning of the loop again.
        inc rdx
        jmp .loop

    ; If we terminated the octect by reading a NULL character just set the "found NULL" flag
    .validate_octect_null:
        mov r12, 0x1

    .validate_octect:
        ; Check if we have two dots back to back by seeing if both RCX and RDX point to the same byte
        cmp rcx, rdx
        je .err_end
        ; Swap the dot ('.') by a NULL character (NULL == 0x0) so that we can call the
            ; atoi I/O function on the octect. Remember atoi needs to find a NULL delimiting
            ; teh string to try and convert to an integer.
        mov BYTE [rdx], 0x0
        ; Store the address pointing at the beginning of the octect in RDI for calling
            ; atoi as that where it expects to find teh pointer to the string. This is why
            ; we need to use 2 registers as pointers: one needs to walk the string until it
            ; finds a dot or NULL and the other one needs to retain the address where the
            ; octect really begins!
        mov rdi, rcx
        call atoi
        ; If the result is NOT a number just quit saying the IP is NOT valid
        cmp rax, 0xFFFFFFFFFFFFFFFF
        je .err_end
        ; Do the same if the octect is lower than 0
        cmp rax, 0x0
        jl .err_end
        ; And if it's larger than 255
        cmp rax, 0xFF
        jg .err_end
        ; If the octect is valid we need to swap the NULL we added by the dot again
        mov BYTE [rdx], 0x2E
        ; Increment the valid octect count
        inc r11
        ; Check if we already have the four valid octects we need and if we do try to run
            ; the final check on the IP address. If we have more than 4 octects then the
            ; IP address is NOT valid (we assume IPv4) and we'll quit with an error. This
            ; final jump to .err_end should never take place actually but we added it just
            ; to be safe in case something work's a little different than expected as it only
            ; meant adding one more code line.
        cmp r11, 0x4
        je .check_ok
        jg .err_end
        ; If we still don't have 4 octects just move both pointers to the beginning of the
            ; next octect and begin the loop once again
        lea rcx, [rdx + 1]
        inc rdx
        jmp .loop

    .check_ok:
        ; We'll only jump here once we have 4 valid octects. If the last one was delimited by
            ; a NULL charcter (as shown by the "found NULL" flag in R12) we can then say
            ; we have a valid IP address and signal that to the caller. If the foruth octect
            ; was NOT delimited by a NULL we have something more than 4 octects and so we need
            ; to quit with an error.
        cmp r12, 0x1
        je .ok_end
        jmp .err_end

    .err_end:
        ; Just zero out RAX to signal the caller the IP pointed to by RDI is NOT valid
            ; and quit the function
        xor rax, rax
        jmp .end

    .ok_end:
        ; If the IP is valid set RAX to 1. Don't forget to reset the NULL we forcibly
            ; set to a dot within the .validate_octect tag.
        mov rax, 0x1
        mov BYTE [rdx], 0x0

    .end:
        ; Just recover the context we saved
        pop r12
        pop r11
        pop rdx
        pop rcx
        pop rdi

        %ifdef SFRAME
            ; Reset the stack frame and return
            add rsp, 32
            pop rbp
        %endif

        ret

string_len:
    ; Input paramters:
        ; RSI -> Pointer to the string whose length we want to know

    ; Return value:
        ; RAX -> Computed string length

    %ifdef SFRAME
        ; Prepare a stack frame
        push rbp
        mov rbp, rsp
        sub rsp,32
    %endif

    ; Save the registers we are going to use on the stack so that we don't disturb the caller
    push rbx
    push rcx

    ; Register breakdown:
        ; RAX -> Current detected number of bytes in the string
        ; BL -> Current character
        ; RCX -> Address of the character we are currently analyzing

    ; Initialize the byte count
    xor rax, rax

    .loop:
        ; Load the address of the next character to read
        lea rcx, [rsi + rax]
        ; Move that character to BL to be analyzed
        mov bl, BYTE [rcx]
        ; Check if the character is NULL
        test bl, bl
        ; If it is, just exit
        je .end
        ; Otherwise, increment the byte count and continue in the loop
        inc rax
        jmp .loop

    .end:
        ; Reset the caller's status
        pop rcx
        pop rbx

        %ifdef SFRAME
            ; Reset the stack frame
            add rsp, 32
            pop rbp
        %endif

        ; And return
        ret

validate_id:
    ; Input paramters:
        ; RCX -> Address of the string to validate
        ; DL -> Needed first character

    ; Return value:
        ; RAX ->
            ; 0x0 -> The ID pointed to by RCX IS NOT valid
            ; 0x1 -> The ID pointed to by RCX IS valid

    %ifdef SFRAME
        ; Prepare a stack frame
        push rbp
        mov rbp, rsp
        sub rsp, 32
    %endif

    ; Save the caller's registry layout
    push rdi
    push rsi
    push rcx

    ; Check if the first letter is the appropriate one
        ; Load it in AL and check with the value provided in DL
    mov al, BYTE [rcx]
    cmp al, dl
    ; If it's not equal, quit with an error message
    jne .id_err_a

    ; Forget about the first character, which is a letter and load the number
        ; address into RDI so that we can check if it's indeed a number!
    lea rdi, [rcx + 0x1]
    call atoi

    ; If the last eight characters aren't a number
    cmp rax, 0xFFFFFFFFFFFFFFFF
    ; Quit with an error message
    je .id_err_c
    ; Load the ID string into RSI to check it's length
    mov rsi, rcx
    call string_len
    ; If the string is 8 chacraters long we'll fall thorugh the inconditional jump
        ; to the .ok_end tag
    cmp rax, 0x8
    ; Otherwise, just quit with an error
    jne .id_err_b
    jmp .ok_end

    ; The following just print an error message and inconditionally jump to .err_end
    .id_err_a:
        mov rdi, QWORD id_err_msg_a
        call print_string_new
        jmp .err_end

    .id_err_b:
        mov rdi, QWORD id_err_msg_b
        call print_string_new
        jmp .err_end

    .id_err_c:
        mov rdi, QWORD id_err_msg_c
        call print_string_new
        jmp .err_end

    ; Zero out RAX to signal an invalid ID and quit
    .err_end:
        xor rax, rax
        jmp .end

    ; Load 0x1 on RAX to signal a valid ID and fall thorugh to the end
    .ok_end:
        mov rax, 0x1 

    .end:
        ; Restore the caller's state
        pop rcx
        pop rsi
        pop rdi

        %ifdef SFRAME
            ; Reset the stack frame
            add rsp, 32
            pop rbp
        %endif

        ; And return
        ret

validate_date:
    ; Input paramters:
        ; RDI -> Pointer to the stirng containing the date to be validated

    ; Return value:
        ; RAX ->
            ; 0x0 -> The date pointed to by RDI IS NOT valid
            ; 0x1 -> The date pointed to by RDI IS valid

    %ifdef SFRAME
        ; Create a stack frame
        push rbp
        mov rbp, rsp
        sub rsp, 32
    %endif

    ; Save the caller's context
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11

    ; Register breakdown:
        ; RSI -> Store the pointer to the data as we need RDI for calling other subroutines
        ; R11 -> Number of elements read
        ; R8 -> Day number
        ; R9 -> Month number
        ; R10 -> Year number

    ; Initialize the registers
    xor r11, r11

    ; Check the length is 10 characters
    mov rsi, rdi
    call string_len
    cmp rax, 0xA
    ; Otherwise, quit with an error
    jne .err_end

    ; Zero out RAX so that loading characters into
        ; AL plays nicely
    xor rax, rax

    ; Pretty much like in the validate_ip subroutine we'll
        ; have two pointers traversing the date string
    mov rcx, rdi
    mov rdx, rdi

    .loop:
        ; Move the current character into AL
        mov al, BYTE [rdx]
        ; Check if the read character is a forward slash ('/' == 0x2F)
        cmp al, 0x2F
        ; If it is, extract the number
        je .get_number
        ; If we get a NULL charcter get the number and check if we have already
            ; got 2 other values before!
        cmp al, 0x00
        je .get_number_null
        ; Otherwise just increment RDX to point to the next charcter and stay in the loop
            ; with the inconditional jump
        inc rdx
        jmp .loop

    ; As the number we are about to get should be the year, check if we already have the
        ; day and month information. Otherwise just quit with an error
    .get_number_null:
        cmp r11, 0x2
        jne .err_end

    .get_number:
        ; Swap the slash ('/') by a NULL charcter so that we can call atoi
        mov BYTE [rdx], 0x0
        mov rdi, rcx
        call atoi
        ; If the detected number is actually not a number quit with an error
        cmp rax, 0xFFFFFFFFFFFFFFFF
        je .err_end
        ; If we have got no data (R11 == 0), then the incoming information is the day.
            ; Jump to .get_day and get it
        cmp r11, 0x0
        je .get_day
        ; If we have only got the day data (R11 == 1), then the incoming information is the month.
            ; Jump to .get_month and get it
        cmp r11, 0x1
        je .get_month
        ; If we have got both the day and month (R11 == 2), then the incoming information is the year.
            ; Jump to .get_year and get it
        cmp r11, 0x2
        je .get_year
        ; This inconditional jump should never be reached but we have it as a failsafe just in case!
        jmp .err_end

    ; Check the day is not less than 1 and save it on R8. As the valid days depend on the provided
        ; month, we'll valdidate it further afterwards. We'll then jump into the loop.
    .get_day:
        cmp rax, 0x1
        jl .err_end
        mov r8, rax
        ; Get ready to get back in the loop
        jmp .loop_reentry

    ; Check 1 <= month <= 12 and save the value on R9. Jump back into the loop then.
    .get_month:
        cmp rax, 0x1
        jl .err_end
        cmp rax, 12
        jg .err_end
        mov r9, rax
        ; Get ready to get back in the loop
        jmp .loop_reentry

    ; Check 1 <= year <= 9999 and save the value onto R10. Then go on to validate the date
    .get_year:
        cmp rax, 0x1
        jl .err_end
        ; Don't allow the use of future dates!
            ; We could write the .check_past section to validate the date
            ; but we don't really feel like it...
        cmp rax, 2020
        jg .err_end
        mov r10, rax
        ; Time to verify our data
        jmp .verify_date

    .loop_reentry:
        ; Increment the number of found data
        inc r11
        ; Put the slash ('/') back where it should be
        mov BYTE [rdx], 0x2F
        ; Move both pointers to the beginning of the next integer
        lea rcx, [rdx + 1]
        inc rdx
        ; And jump back to the loop
        jmp .loop

    ; Check the month and based on that call the appropriate validating insstructions
    .verify_date:
        cmp r9, 1
        je .verify_31_day
        cmp r9, 2
        je .verify_28_day
        cmp r9, 3
        je .verify_31_day
        cmp r9, 4
        je .verify_30_day
        cmp r9, 5
        je .verify_31_day
        cmp r9, 6
        je .verify_30_day
        cmp r9, 7
        je .verify_31_day
        cmp r9, 8
        je .verify_31_day
        cmp r9, 9
        je .verify_30_day
        cmp r9, 10
        je .verify_31_day
        cmp r9, 11
        je .verify_30_day
        cmp r9, 12
        je .verify_31_day
        jmp .err_end

    ; Just check day <= 31 as we already checked day >= 1 in .get_day. If this doesn't hold
        ; then quit with an error
    .verify_31_day:
        cmp r8, 31
        jg .err_end
        jmp .ok_end

    ; Just check day <= 30 as we already checked day >= 1 in .get_day. If this doesn't hold
        ; then quit with an error
    .verify_30_day:
        cmp r8, 30
        jg .err_end
        jmp .ok_end

    ; Just check day <= 28 as we already checked day >= 1 in .get_day. We'll also take a look at
        ; if the provided year was a leap year in case we are working with 29/02... If the day is
        ; larger than 29 quit with an error
    .verify_28_day:
        cmp r8, 29
        je .leap_year
        cmp r8, 28
        jg .err_end
        jmp .ok_end

    ; Leap yer condition:
        ; It MUST be divisible by 4 -> year % 4 == 0
        ; It CAN'T be divisible by 100 -> year % 100 != 0
            ; Unless it's also divisible by 400 -> year % 100 == 0 and year % 400 == 0 is a leap year!

    .leap_year:
        ; Zero out RDX so it won't disturb our division
        xor rdx, rdx
        ; Load the year into RAX
        mov rax, r10
        ; Load 4 into RCX
        mov rcx, 0x4
        ; Carry out year / 4
        div rcx
        ; If the remainder is not 0 quit with an error
        cmp rdx, 0x0
        jne .err_end
        ; Load the year into RAX again
        mov rax, r10
        ; Load 100 into RCX. Remeber RDX is 0 for sure given the check above!
        mov rcx, 100
        ; Divide year / 100
        div rcx
        ; If the remainder is 0 check if it's also divisible by 400
            ; otherwise it's a leap yer and we'll fall through the inconditional jump
        cmp rdx, 0x0
        je .check_400
        jmp .ok_end
        .check_400:
            ; Load the year into RAX
            mov rax, r10
            ; Load 400 into RCX
            mov rcx, 400
            ; And carry out year / 400. Remember RDX is still 0 for sure!
            div rcx
            ; If the year is also divisible by 400 then it's a leap year
            cmp rdx, 0x0
            je .ok_end
            ; Otherwise quit with an error
            jmp .err_end

    ; Just print an error message and quit after zeroing out RAX
    .err_end:
        mov rdi, QWORD date_err_msg
        call print_string_new
        xor rax, rax
        jmp .end

    ; Move a 1 into RAX and quit
    .ok_end:
        mov rax, 0x1

    .end:
        ; Restore the caller's satate
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdi
        pop rsi
        pop rdx
        pop rcx

        %ifdef SFRAME
            ; Reset the frame satck
            add rsp, 32
            pop rbp
        %endif

        ; And return
        ret

find_record:
    ; Input paramters:
        ; RSI -> String to test against
        ; RDI -> Initial address to begin searching. Return the record's address
        ; R8 -> Pointer Increment
        ; R9 -> Number of records
        ; R10 -> Offset for record validation

    ; Return value:
        ; RAX ->
            ; 0x0 -> The record pointed to by RSI HASN'T been found
            ; 0x1 -> The record pointed to by RSI HAS been found
        ; RDI -> Address of the string that matched

    %ifdef SFRAME
        ; Prepare a stack frame
        push rbp
        mov rbp, rsp
        sub rsp, 32
    %endif

    ; Save the caller's context
    push rbx

    ; Zero out RBX
    xor rbx, rbx
    xor rax, rax

    .loop:
        ; Check if we have more records to search. Otherwise just quit with an error
        cmp r9, rbx
        je .err_end

        ; Check if the record is valid!
        mov r11, rdi
        sub r11, r10
        mov al, BYTE [r11]
        test al, al
        je .next_record

        ; Check if the current string is the one we are looking for
        call strings_are_equal
        cmp rax, 0x1
        ; If it is just quit, we know RAX has a 1 on it!
        je .end

        .next_record:
            ; Otherwise look at the next record. Remember R8 contains the increment we need to apply
            lea rdi, [rdi + r8]

        ; Increment the number of records we have looked at
        inc rbx
        ; And back to the loop
        jmp .loop

    ; Just zero out RAX and quit if we haven't found the reocrd
    .err_end:
        xor rax, rax
    .end:
        ; Reset the caller's state
        pop rbx

        %ifdef SFRAME
            ; Reset the stack frame
            add rsp, 32
            pop rbp
        %endif

        ; And return
        ret

find_free_record:
    ; Input paramters:
        ; RDI -> Initial address to begin searching. Return the free record's address
        ; R8 -> Pointer Increment (i.e. record size)
        ; R9 -> Number of records to search

    ; Return value:
        ; RAX ->
            ; 0x1 -> A free record HASN'T been found
            ; 0x0 -> A free record HAS been found
                ; Note this value shouldn't be used as this functions callees
                    ; won't call it if we have reached the user maximum.
        ; RDI -> Address of the first free record

    %ifdef SFRAME
        ; Prepate a new stack frame
        push rbp
        mov rbp, rsp
        sub rsp,32
    %endif

    ; Save the caller's register context
    push rbx

    ; Zero out RAX and RBX
    xor rax, rax
    xor rbx, rbx

    .loop:
        ; Check if we have more records to search. Otherwise just quit with an error
        cmp r9, rbx
        je .err_end

        ; Check if the current character is NULL
        mov al, BYTE [rdi]
        cmp rax, 0x0
        ; If it is just quit, as we have found an empty record!
        je .end

        ; Otherwise look at the next record. Remember R8 contains the increment we need to apply
        lea rdi, [rdi + r8]

        ; Increment the number of records we have looked at
        inc rbx
        ; And back to the loop
        jmp .loop

    ; Just zero out RAX and quit if we haven't found the reocrd
    .err_end:
        mov rax, 0x1
    .end:
        ; Retrieve the caller's context
        pop rbx

        %ifdef SFRAME
            ; Reset everything to the way it was
            add rsp, 32
            pop rbp
        %endif

        ret

clear_screen:
    %ifdef SFRAME
        ; Prepate a new stack frame
        push rbp
        mov rbp, rsp
        sub rsp,32
    %endif

    %ifdef DCKR
        ; Save the context of the registers we'll employ
        push rbx
        push rcx
        push rdx
        push rdi

        ; Fork the process
        mov rax, sys_fork
        int 0x80

        ; Condition ->
            ; Kid -> Returned value is 0
            ; Dad -> Returned value is NOT 0
        cmp rax, 0
        je .kid
        jne .dad

        .kid:
            ; Remember we won't come back from execve(); we need no more code after the call!
                ; Args ->
                    ; RAX -> Entrypoint
                    ; RBX -> Address of program to execute
                    ; RCX -> argv (0 == NULL)
                    ; RDX -> envp (0 == NULL)
            mov rax, sys_execve
            mov rbx, cls
            mov rcx, 0
            mov rdx, 0
            int 0x80

        .dad:
            ; Wait till the kid finishes with a wait()
                ; NOTE -> wait(NULL) == waitpid(-1, NULL, 0)
            mov rax, sys_waitpid
            mov rbx, -1
            mov rcx, 0
            mov rdx, 0
            int 0x80

        ; Return zero on RAX if everything went well
        xor rax, rax

        ; Reset the stack
        pop rbx
        pop rcx
        pop rdx
        pop rdi
    %else
        ; If we are not in the docker environment assume we don't have access to the executable
            ; and just convert this into a dummy subroutine!
        nop
    %endif

    %ifdef SFRAME
        ; Reset everything to the way it was
        add rsp, 32
        pop rbp
    %endif

    ret
%endif
