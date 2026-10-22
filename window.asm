%include "x11.inc"

extern display

global create_window
global window

section .data
    windowName: db "A window finally", 0x00

section .bss
    screenNum:  resd 1
    rootWindow: resq 1
    window:     resq 1

section .text

; Creates, names and maps the game window
create_window:
    push rbp
    mov rbp, rsp

    ; https://stackoverflow.com/questions/23154955/what-are-the-differences-between-xdefaultscreen-and-xdefaultscreenofdisplay
    ; Get window ID(?)
    ; int XDefaultScreen(Display *display)
    mov rdi, [rel display]      ; Move as a pointer
    call XDefaultScreen         ; Call the XDefaultScreen function
    mov [rel screenNum], eax    ; Save the screen number

    ; Window XRootWindow(Display *display, int screen_number);
    mov rdi, [rel display]      ; Send in the display pointer
    mov esi, eax                ; Screen number from XDefaultScreen
    call XRootWindow            ; Call in the XRootWindow to get the root window
    mov [rel rootWindow], rax   ; Save the rootWindow

    ; Create X Simple Window
    ; Window XCreateSimpleWindow(
    ;     Display *display,           ; rdi
    ;     Window parent,              ; rsi
    ;     int x,                      ; rdx
    ;     int y,                      ; rcx
    ;     unsigned int width,         ; r8
    ;     unsigned int height,        ; r9
    ;     unsigned int border_width,  ; stack
    ;     unsigned long border,       ; stack
    ;     unsigned long background    ; stack
    ; );
    sub rsp, 8                  ; pad (keeps 16-byte alignment)
    push 0xFFFFFF               ; arg 9: background = white
    push 0                      ; arg 8: border = 0
    push 0                      ; arg 7: border_width = 0

    mov rdi, [rel display]      ; arg 1: Display*
    mov rsi, [rel rootWindow]   ; arg 2: root window
    mov edx, 0                  ; arg 3: x
    mov ecx, 0                  ; arg 4: y
    mov r8d, 640                ; arg 5: width
    mov r9d, 480                ; arg 6: height
    call XCreateSimpleWindow
    add rsp, 32                 ; 24 (args) + 8 (pad)

    mov [rel window], rax       ; save the returned Window id

    ; Set the window name to windowName
    ; int XStoreName(Display *display, Window w, char *window_name);
    mov rdi, [rel display]      ; arg 1: Display*
    mov rsi, [rel window]       ; arg 2: Window
    lea rdx, [rel windowName]   ; arg 3: Pointer to windowName
    call XStoreName

    ; int XSelectInput(Display *display, Window w, long event_mask);
    mov edx, KeyPressMask | KeyReleaseMask | ExposureMask | StructureNotifyMask
    mov rdi, [rel display]
    mov rsi, [rel window]
    call XSelectInput

    ; Map the window
    ; int XMapWindow(Display *display, Window w);
    mov rdi, [rel display]      ; arg 1: Display*
    mov rsi, [rel window]       ; arg 2: Window
    call XMapWindow

    ; TODO: This needs to be deleted later
    ; XSync(Dsplay *display, bool discard);
    mov rdi, [rel display]      ; arg 1: Display* = display
    xor esi, esi                ; arg 2: discard = false
    call XSync

    ; mov rdi, [rel display]
    ; call XFlush

    pop rbp
    ret
