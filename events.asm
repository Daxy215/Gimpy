%include "x11.inc"
%include "linux.inc"

extern display
extern draw_text
extern accept_client
extern isServer
extern serverSocket
extern printf

global run_event_loop

section .data
    keyPressFormat: db "Pressed: %c", 0x0A, 0

section .bss
    curEvent    resq 192        ; Current window event (that'll be processed)
    keyBuf:     resb 32

    ; struct pollfd { int fd; short events; short revents; } pollFds[2];
    pollFds:                    ; [0] = X server connection, [1] = server socket
    xFd:        resd 1          ; pollFds[0].fd
    xEvents:    resw 1          ; pollFds[0].events
    xRevents:   resw 1          ; pollFds[0].revents
    socketFd:   resd 1          ; pollFds[1].fd
    socketEvents:  resw 1       ; pollFds[1].events
    socketRevents: resw 1       ; pollFds[1].revents

section .text

; Processes window events until the window is closed
run_event_loop:
    push rbp
    mov rbp, rsp

    ; Get the fd of the X server connection to wait on it
    ; int XConnectionNumber(Display *display);
    mov rdi, [rel display]      ; arg 1: Display*
    call XConnectionNumber
    mov [rel xFd], eax          ; pollFds[0].fd     = X server fd
    mov word [rel xEvents], POLLIN  ; pollFds[0].events = POLLIN

    mov eax, [rel serverSocket]
    mov [rel socketFd], eax     ; pollFds[1].fd     = serverSocket
    mov word [rel socketEvents], POLLIN ; pollFds[1].events = POLLIN (a player is waiting to join)

.loop:
    ; Accept a new player if we're the server (doesn't block)
    cmp byte [rel isServer], 1  ; Check if we're the server
    jne .checkPending
    call accept_client

.checkPending:
    ; Check if there are events already waiting
    ; int XPending(Display *display);
    mov rdi, [rel display]      ; arg 1: Display*
    call XPending
    test eax, eax               ; Check if there are any events
    jnz .nextEvent

    ; Wait until the X server sends an event or a player joins
    ; poll(pollFds, 1 + isServer, -1);
    ; sys_poll(struct pollfd *ufds, uint nfds, int timeout_msecs)
    mov eax, sys_poll           ; sys_poll syscall number
    lea rdi, [rel pollFds]      ; arg 1: ufds          = pollFds
    movzx esi, byte [rel isServer]
    inc esi                     ; arg 2: nfds          = 1 + isServer (the client only waits on X)
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
    pop rbp
    ret
