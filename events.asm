%include "x11.inc"
%include "linux.inc"
%include "multiplayer.inc"

extern display
extern draw_text
extern update_server
extern fill_server_poll_fds
extern isServer
extern printf

global run_event_loop

section .data
    keyPressFormat: db "Pressed: %c", 0x0A, 0

section .bss
    curEvent    resq 192        ; Current window event (that'll be processed)
    keyBuf:     resb 32

    ; struct pollfd { int fd; short events; short revents; } pollFds[2 + MAX_CLIENTS];
    ; [0] = X server connection, [1] = server socket, [2..] = players' sockets
    pollFds:    resb 8 * (2 + MAX_CLIENTS)

section .text

; Processes window events until the window is closed
run_event_loop:
    push rbp
    mov rbp, rsp
    push rbx                    ; Save rbx (callee saved), used for nfds
    sub rsp, 8                  ; pad (keeps 16-byte alignment)

    ; Get the fd of the X server connection to wait on it
    ; int XConnectionNumber(Display *display);
    mov rdi, [rel display]      ; arg 1: Display*
    call XConnectionNumber
    mov [rel pollFds], eax      ; pollFds[0].fd     = X server fd
    mov word [rel pollFds + 4], POLLIN  ; pollFds[0].events = POLLIN

.loop:
    ; Accept new players and receive their messages if we're the server (doesn't block)
    cmp byte [rel isServer], 1  ; Check if we're the server
    jne .checkPending
    call update_server

.checkPending:
    ; Check if there are events already waiting
    ; int XPending(Display *display);
    mov rdi, [rel display]      ; arg 1: Display*
    call XPending
    test eax, eax               ; Check if there are any events
    jnz .nextEvent

    ; The client only waits on X
    mov ebx, 1                  ; nfds = 1
    cmp byte [rel isServer], 1  ; Check if we're the server
    jne .poll

    ; The server also waits on its socket and the players' sockets
    lea rdi, [rel pollFds + 8]  ; arg 1: &pollFds[1]
    call fill_server_poll_fds
    lea ebx, [eax + 1]          ; nfds = 1 + number of server pollfds

.poll:
    ; Wait until the X server sends an event, a player joins, or a player sends something
    ; poll(pollFds, nfds, -1);
    ; sys_poll(struct pollfd *ufds, uint nfds, int timeout_msecs)
    mov eax, sys_poll           ; sys_poll syscall number
    lea rdi, [rel pollFds]      ; arg 1: ufds          = pollFds
    mov esi, ebx                ; arg 2: nfds          = nfds
    mov edx, -1                 ; arg 3: timeout_msecs = -1 (wait forever)
    syscall                     ; Invoke kernel

    jmp .loop

.nextEvent:
    ; Get next event
    ; int XNextEvent(Display *display, XEvent *event_return);
    mov rdi, [rel display]      ; arg 1: Display*
    lea rsi, [rel curEvent]     ; arg 2: event_return*
    call XNextEvent

    mov eax, [rel curEvent]     ; Save current event into eax
    cmp eax, KeyPressEventType  ; Check if it's a keypress event
    je .handle_on_keypress
    cmp eax, ExposeEventType    ; Check if it's an expose event (window needs redrawing)
    je .handle_on_expose
    cmp eax, ClientMessageEventType ; Check if it's a client message (E.G., close window)
    je .done                        ; For now just exit for any message

    jmp .loop

.handle_on_keypress:
    ; int XLookupString(XKeyEvent *ev, char *buf, int nbytes, KeySym *ks_return, XComposeStatus *status)
    lea rdi, [rel curEvent]     ; arg 1: event*    = curEvent
    lea rsi, [rel keyBuf]       ; arg 2: char buf* = keyBuf
    mov edx, 32                 ; arg 3: nbytes    = 32
    xor ecx, ecx                ; arg 4: ks_return = null
    xor r8d, r8d                ; arg 5: status*   = null
    call XLookupString

    test eax, eax
    jz .loop

    ; printf("Pressed %c\n", keyBuf[0])
    lea rdi, [rel keyPressFormat]
    movsx esi, byte [rel keyBuf]        ; First byte as int (vararg)
    xor eax, eax
    call printf

    jmp .loop

.handle_on_expose:
    call draw_text
    jmp .loop

.done:
    add rsp, 8                  ; Remove the pad
    pop rbx                     ; Restore rbx
    pop rbp
    ret
