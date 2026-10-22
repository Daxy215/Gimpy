%include "x11.inc"
%include "linux.inc"

extern openXDisplay
extern create_window
extern create_graphics_context
extern run_event_loop
extern start_multiplayer

extern display
extern window
extern serverSocket

global main

section .text

main:
    push rbp
    mov rbp, rsp

    ; Make the server socket non blocking
    ; sys_fcntl(uint fd, uint cmd, ulong arg)
    ; sys_fcntl(serverSocket, F_SETFL, O_NONBLOCK)
    ;mov eax, sys_fcntl              ; sys_fcntl syscall number
    ;mov edi, [rel serverSocket]     ; arg 1: fd  = serverSocket
    ;mov esi, F_SETFL                ; arg 2: cmd = F_SETFL (set the file status flags)
    ;mov edx, O_NONBLOCK             ; arg 3: arg = O_NONBLOCK (non blocking)
    ;syscall                         ; Invoke kernel

    call openXDisplay
    call create_window
    call start_multiplayer

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
