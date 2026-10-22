%include "x11.inc"
%include "linux.inc"

global openXDisplay
global display

; https://www.nasm.us/doc/nasm03.html#section-3.2.1
section .data
    displayName: db 0

    displayFailedMessage: db "Display failed to create", 0x0A
    displayFailedMessageLength: equ $ - displayFailedMessage

    displaySuccessMessage: db "Display was successfully created", 0x0A
    displaySuccessMessageLength: equ $ - displaySuccessMessage

section .bss
    display:    resq 1          ; 8 bytes (quadword), zero-initialized

section .text

openXDisplay:
    sub rsp, 8               ; 16-byte align before call
    ;mov rdi, 0              ; Pass NULL to use the DISPLAY environment variable
    xor edi, edi
    ; lea rdi, [rel displayName]
    call XOpenDisplay
    add rsp, 8

    test rax, rax                   ; Test whether XOpenDisplay failed or not
    jz .openXDisplayFailed

    ; XOpenDisplay successed
    mov [rel display], rax          ; Save the Display*

    ; Print a message
    ; sys_write(uint fd, const char *buf, size_t count)
    ; sys_write(1, message, 13)
    mov rax, sys_write      ; sys_write syscall number
    mov rdi, stdout         ; Fle descriptor 1 (stdout)
    lea rsi, [rel displaySuccessMessage]  ; Pointer to message
    mov rdx, displaySuccessMessageLength  ; Number of bytes to write
    syscall

    ret

.openXDisplayFailed:
    ; Print a message
    ; sys_write(uint fd, const char *buf, size_t count)
    ; sys_write(1, message, 13)
    mov rax, sys_write      ; sys_write syscall number
    mov rdi, stdout         ; Fle descriptor 1 (stdout)
    lea rsi, [rel displayFailedMessage]  ; Pointer to message
    mov rdx, displayFailedMessageLength  ; Number of bytes to write
    syscall                 ; Invoke kernel

    ret
