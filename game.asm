%include "x11.inc"
%include "linux.inc"

extern openXDisplay
extern create_window
extern create_graphics_context
extern run_event_loop

extern display
extern window

global main

section .text

main:
    push rbp
    mov rbp, rsp

    call openXDisplay
    call create_window

    call create_graphics_context
    test eax, eax               ; Check if failed
    jz .exit

    call run_event_loop

.exit:
    
    ; Clean up
    ; int XDestroyWindow(Display *display, Window w);
    mov rdi, [rel display]      ; arg 1: Display*
    mov rsi, [rel window]       ; arg 2: Window
    call XDestroyWindow
    
    ; int XCloseDisplay(Display *display);
    mov rdi, [rel display]      ; arg 1: Diplay*
    call XCloseDisplay
    
    mov rsp, rbp
    pop rbp
    xor eax, eax
    
    ; Exit program with no errors
    ; sys_exit(int error_code)
    ; sys_exit(0)
    mov rax, sys_exit       ; sys_exit syscall number
    xor rdi, rdi            ; Exit code 0
    syscall                 ; Invoke kerenl
