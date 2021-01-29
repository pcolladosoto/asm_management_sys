; Output Messages

; This file contains only a .data section in which we define all the messages we are using throughout the
    ; program. This let's us easily change messages as needed and would allow for an easier translation
    ; process for example. We'll just need to include the file wherever its messages are needed and,
    ; as we are including it more than once we actually need to define a macro to stop the strings defined
    ; in it from being redefined with the second include. That's why we check to see if the OUT_MSGS macro
    ; is defined. As the first time this file is to be included it WON'T be defined it'll be treated normally
    ; and the macro will be defined BUT the second time it's included in another place the OUT_MSGS macro will
    ; already be defined which will cause this file not to be including, thus avoiding rewriting all the strings
    ; we have already defined. Nonetheless, including it in a second file will let subroutines in it find the
    ; pertinent addresses. All in all, we can find the strings from anywhere we include the file BUT we only feed
    ; them once to nasm so that there are no redefinition errors. This technique has been found on section 4.6.1 of
    ; the NASM Documentation. Please note that we need to end the %ifndef clause with an %endif directive at the end.
    ; We'll refer to this comment from other files so that we don't add redundant information to the codebase.

; Note many of the messages include a newline character ('\n' == 0xA == 10) so that we avoid having to call the I/O
    ; function print_nl_new after every call to print_string_new, therefor reducing the code size.

%ifndef OUT_MSGS
    %define OUT_MSGS

    ; We are just defining data regions
    section .data

    ; *************************
    ; * User related messages *
    ; *************************
    users_full_msg:
        db "We already have 100 users...", 0xA, 0x0

    surename_msg:
        db "Please enter a surename -> ", 0x0

    long_str_err:
        db "The input string was too long and has been chopped down to 64 bytes!", 0xA, 0x0

    firstname_msg:
        db "Please enter a first name -> ", 0x0

    dep_msg:
        db "Please enter a department -> ", 0x0

    dep_err_msg:
        db "This department name is NOT supported... Choose one of:", 0xA, \
            0x9, "Development", 0xA, 0x9, "IT Support", 0xA, 0x9, "HR", 0xA, \
            0x9, "Finance", 0xA, 0x0

    uid_msg:
        db "Please enter a User ID -> ", 0x0

    id_err_msg_a:
        db "Invalid initial letter!", 0xA, 0x0

    id_err_msg_b:
        db "The ID is NOT 8 characters long... Input a new one!", 0xA, 0x0

    id_err_msg_c:
        db "Invalid ID... Input a new one!", 0xA, 0x0

    id_not_unique_msg:
        db "The ID has already been registered!", 0xA, 0x0

    email_msg:
        db "The email has been automatically generated based on the user ID!", 0xA, 0x0

    print_new_user_msg:
        db "User number: ", 0x0

    print_surename_msg:
        db 0x9, "Surename", 0x9, "-> ", 0x0

    print_name_msg:
        db 0x9, "Name", 0x9, 0x9, "-> ", 0x0

    print_dep_msg:
        db 0x9, "Department", 0x9, "-> ", 0x0

    print_uid_msg:
        db 0x9, "User ID", 0x9, 0x9, "-> ", 0x0

    print_email_msg:
        db 0x9, "E-mail", 0x9, 0x9, "-> ", 0x0

    n_users_msg_a:
        db "We currently have ", 0x0

    n_users_msg_b:
        db " registered user(s) on the system!", 0xA, 0x0

    del_msg:
        db "Deleted -> ", 0x0

    no_users_msg:
        db "There are no users currently on the system!", 0xA, 0x0

    user_lookup_msg:
        db "Provide the User ID to look for -> ", 0x0

    user_not_found_msg:
        db "The requested user couldn't be found...", 0xA, 0x0


    user_del_msg:
        db "User ID of the record to delete -> ", 0x0

    ; *****************************
    ; * Computer related messages *
    ; *****************************
    comps_full_msg:
        db "We already have 500 computers...", 0xA, 0x0

    cid_msg:
        db "Please enter the Computer ID (a.k.a. computer name) -> ", 0x0

    ip_msg:
        db "Please enter the computer's IP -> ", 0x0

    ip_err_msg:
        db "Invalid IP...", 0xA, 0x0

    os_msg:
        db "Please enter the computer's OS -> ", 0x0

    os_err_msg:
        db "This OS name is NOT supported... Choose one of:", 0xA, \
            0x9, "Linux", 0xA, 0x9, "Windows", 0xA, 0x9, "Mac OSX", 0xA, 0x0

    cuid_msg:
        db "Please enter a this computer's user's User ID -> ", 0x0

    date_msg:
        db "Please enter the date of purchase (dd/mm/yyyy) -> ", 0x0

    print_new_comp_msg:
        db "Computer number: ", 0x0

    print_cid_msg:
        db 0x9, "Computer ID", 0x9, "-> ", 0x0

    print_ip_msg:
        db 0x9, "IP", 0x9, 0x9, "-> ", 0x0

    print_os_msg:
        db 0x9, "OS", 0x9, 0x9, "-> ", 0x0

    print_date_msg:
        db 0x9, "Purch. date", 0x9, "-> ", 0x0

    n_comps_msg_a:
        db "We currently have ", 0x0

    n_comps_msg_b:
        db " registered computer(s) on the system!", 0xA, 0x0

    no_comps_msg:
        db "There are no computers currently on the system!", 0xA, 0x0

    comp_lookup_msg:
        db "Provide the Computer ID to look for -> ", 0x0

    comp_not_found_msg:
        db "The requested computer couldn't be found...", 0xA, 0x0

    date_err_msg:
        db "The provided date is NOT valid!", 0xA, 0x0

    comp_del_msg:
        db "Computer ID of the record to delete -> ", 0x0
%endif
