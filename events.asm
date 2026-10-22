%include "x11.inc"

extern display
extern draw_text
extern printf

global run_event_loop

section .data
    keyPressFormat: db "Pressed: %c", 0x0A, 0

section .bss
    curEvent    resq 192        ; Current window event (that'll be processed)
    keyBuf:     resb 32

section .text

; Processes window events until the window is closed
run_event_loop:
    push rbp
    mov rbp, rsp

.loop:
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
