; Window stuff

; Display *XOpenDisplay(char *display_name)
extern XOpenDisplay

; int XDefaultScreen(Display *display)
extern XDefaultScreen                    ; Returns an ID representing the default screen number

; Window XRootWindow(Display *display, int screen_number)
extern XRootWindow

; int XStoreName(Display *display, Window w, char *window_name);
extern XStoreName

; int XSelectInput(Display *display, Window w, long event_mask);
extern XSelectInput
%define NoEventMask               0x00000000
%define KeyPressMask              0x00000001
%define KeyReleaseMask            0x00000002
%define ButtonPressMask           0x00000004
%define ButtonReleaseMask         0x00000008
%define EnterWindowMask           0x00000010
%define LeaveWindowMask           0x00000020
%define PointerMotionMask         0x00000040
%define PointerMotionHintMask     0x00000080
%define Button1MotionMask         0x00000100
%define Button2MotionMask         0x00000200
%define Button3MotionMask         0x00000400
%define Button4MotionMask         0x00000800
%define Button5MotionMask         0x00001000
%define ButtonMotionMask          0x00002000
%define KeymapStateMask           0x00004000
%define ExposureMask              0x00008000
%define VisibilityChangeMask      0x00010000
%define StructureNotifyMask       0x00020000
%define ResizeRedirectMask        0x00040000
%define SubstructureNotifyMask    0x00080000
%define SubstructureRedirectMask  0x00100000
%define FocusChangeMask           0x00200000
%define PropertyChangeMask        0x00400000
%define ColormapChangeMask        0x00800000
%define OwnerGrabButtonMask       0x01000000

; int XMapWindow(Display *display, Window w);
extern XMapWindow

; Window XCreateSimpleWindow(
;     Display *display,
;     Window parent,
;     int x,
;     int y,
;     unsigned int width,
;     unsigned int height,
;     unsigned int border_width,
;     unsigned long border,
;     unsigned long background
; );
extern XCreateSimpleWindow

extern XSync
extern XFlush

; int XNextEvent(Display *display, XEvent *event_return);
extern XNextEvent
%define KeyPressEventType              2
%define KeyReleaseEventType            3
%define ButtonPressEventType           4
%define ButtonReleaseEventType         5
%define MotionNotifyEventType          6
%define EnterNotifyEventType           7
%define LeaveNotifyEventType           8
%define FocusInEventType               9
%define FocusOutEventType              10
%define KeymapNotifyEventType          11
%define ExposeEventType                12
%define GraphicsExposeEventType        13
%define NoExposeEventType              14
%define VisibilityNotifyEventType      15
%define CreateNotifyEventType          16
%define DestroyNotifyEventType         17
%define UnmapNotifyEventType           18
%define MapNotifyEventType             19
%define MapRequestEventType            20
%define ReparentNotifyEventType        21
%define ConfigureNotifyEventType       22
%define ConfigureRequestEventType      23
%define GravityNotifyEventType         24
%define ResizeRequestEventType         25
%define CirculateNotifyEventType       26
%define CirculateRequestEventType      27
%define PropertyNotifyEventType        28
%define SelectionClearEventType        29
%define SelectionRequestEventType      30
%define SelectionNotifyEventType       31
%define ColormapNotifyEventType        32
%define ClientMessageEventType         33
%define MappingNotifyEventType         34
%define GenericEventEventType          35

; int XLookupString(XKeyEvent *ev, char *buf, int nbytes, KeySym *ks_return, XComposeStatus *status)
extern XLookupString

; GC XCreateGC(Display *display, Drawable d, unsigned long valuemask, XGCValues *values);
extern XCreateGC
%define GCFunction          0x00000001
%define GCPlaneMask         0x00000002
%define GCForeground        0x00000004
%define GCBackground        0x00000008
%define GCLineWidth         0x00000010
%define GCLineStyle         0x00000020
%define GCCapStyle          0x00000040
%define GCJoinStyle         0x00000080
%define GCFillStyle         0x00000100
%define GCFillRule          0x00000200
%define GCTile              0x00000400
%define GCStipple           0x00000800
%define GCTileStipXOrigin   0x00001000
%define GCTileStipYOrigin   0x00002000
%define GCFont              0x00004000
%define GCSubwindowMode     0x00008000
%define GCGraphicsExposures 0x00010000
%define GCClipXOrigin       0x00020000
%define GCClipYOrigin       0x00040000
%define GCClipMask          0x00080000
%define GCDashOffset        0x00100000
%define GCDashList          0x00200000
%define GCArcMode           0x00400000

; XFontStruct *XLoadQueryFont(Display *display, const char *name);
extern XLoadQueryFont                    ; Returns NULL if the font fails to load (XLoadFont doesn't)

; int XSetFont(Display *display, GC gc, Font font);
extern XSetFont

; int XSetForeground(Display *display, GC gc, unsigned long foreground);
extern XSetForeground

; int XDrawString(Display *display, Drawable d, GC gc, int x, int y, const char *string, int length);
extern XDrawString

; int XDestroyWindow(Display *display, Window w);
extern XDestroyWindow

; int XCloseDisplay(Display *display);
extern XCloseDisplay

extern printf

global main

%define stdin  0
%define stdout 1

%define O_RDONLY 0

; https://github.com/las-nish/NASM-Assembly-Collection/blob/main/Linux%20System%20Call.MD

; sys_read(uint fd, char *buf, size_t count)
%define sys_read 0

; sys_write(uint fd, const char *buf, size_t count)
%define sys_write 1

; sys_ioctl (uint fd, uint cmd, ulong arg)
%define sys_ioctl 16
%define TCGETS 0x5401
%define TCSETS 0x5402

; sys_exit(int error_code)
%define sys_exit 60

; sys_fcntl (uint fd, uint cmd, ulong arg)
%define sys_fcntl 72
%define F_SETFL 4
%define O_NONBLOCK 0x800

; sys_openat (int dfd, const char *filename, int flags, int mode)
%define sys_openat 257
%define AT_FDCWD -100   ; in /usr/include/linux/fcntl.h: #define AT_FDCWD -100

; https://www.nasm.us/doc/nasm03.html#section-3.2.1
section .data
    windowName: db "A window finally", 0x00
    displayName: db 0
    
    displayFailedMessage: db "Display failed to create", 0x0A
    displayFailedMessageLength: equ $ - displayFailedMessage
    
    displaySuccessMessage: db "Display was successfully created", 0x0A
    displaySuccessMessageLength: equ $ - displaySuccessMessage

    gcCreationFailedMessage: db "Graphics context failed to create", 0x0A
    gcCreationFailedMessageLength: equ $ - gcCreationFailedMessage

    loadingFontFailedMessage: db "Font failed to load", 0x0A
    loadingFontFailedMessageLength: equ $ - loadingFontFailedMessage

    keyPressFormat: db "Pressed: %c", 0x0A, 0

    drawText: db "Finally some text!"
    drawTextLength: equ $ - drawText
    
    ; xlsfonts
    fontName: db "-misc-fixed-medium-r-normal--13-120-75-75-c-70-iso10646-1", 0x00

section .bss
    display:    resq 1          ; 8 bytes (quadword), zero-initialized
    screenNum:  resd 1
    rootWindow: resq 1
    window:     resq 1
    gc:         resq 1
    font:       resq 1

    curEvent    resq 192        ; Current window event (that'll be processed)
    keyBuf:     resb 32

; Arguments seems to be in this format:
; rax -> syscall number
; rdi -> first  argument
; rsi -> second argument
; rdx -> third  argument
; r10.. r8.. r9..
; Unsure why it's R8 THEN r9 but ok

; https://github.com/las-nish/NASM-Assembly-Collection/blob/main/Linux%20System%20Call.MD

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

main:
    push rbp
    mov rbp, rsp

    call openXDisplay
    
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
    
    ; Create the grpahics context
    ; GC XCreateGC(Display *display, Drawable d, unsigned long valuemask, XGCValues *values);
    mov rdi, [rel display]      ; arg 1: Display* = display
    mov rsi, [rel window]       ; arg 2: Drawable = window (Pixmap)
    xor edx, edx                ; arg 3: valuemask = 0
    xor ecx, ecx                ; arg 4; XGCValues* = null
    call XCreateGC

    ; Check if failed
    test rax, rax
    je .gcCreationFailed
    
    mov [rel gc], rax           ; Save the returned GC
    
    ; Load a font
    ; XFontStruct *XLoadQueryFont(Display *display, const char *name);
    mov rdi, [rel display]      ; arg 1: Display* = display
    lea rsi, [rel fontName]     ; arg 2: name = fontName
    call XLoadQueryFont
    
    ; Check if failed
    test rax, rax
    je .loadingFontFailed
    
    mov rax, [rax + 8]          ; XFontStruct->fid (after the 8 byte ext_data pointer)
    mov [rel font], rax         ; Save the loaded font
    
    ; Set the GC's font
    ; int XSetFont(Display *display, GC gc, Font font);
    mov rdi, [rel display]      ; arg 1: Display* = display
    mov rsi, [rel gc]           ; arg 2: GC = gc
    mov rdx, [rel font]         ; arg 3: Font = font
    call XSetFont
    
    ; Set the GC's foreground color
    ; int XSetForeground(Display *display, GC gc, unsigned long foreground);
    mov rdi, [rel display]      ; arg 1: Display* = display
    mov rsi, [rel gc]           ; arg 2: GC = gc
    mov edx, 0xFF0000           ; arg 3: foreground = red
    call XSetForeground
    
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
    je .exit                        ; For now just exit for any message

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
    ; Draw the text
    ; int XDrawString(
    ;     Display *display,           ; rdi
    ;     Drawable d,                 ; rsi
    ;     GC gc,                      ; rdx
    ;     int x,                      ; rcx
    ;     int y,                      ; r8
    ;     const char *string,         ; r9
    ;     int length                  ; stack
    ; );
    sub rsp, 8                  ; pad (keeps 16-byte alignment)
    push drawTextLength         ; arg 7: length = drawTextLength

    mov rdi, [rel display]      ; arg 1: Display*
    mov rsi, [rel window]       ; arg 2: Drawable = window
    mov rdx, [rel gc]           ; arg 3: GC = gc
    mov ecx, 20                 ; arg 4: x
    mov r8d, 20                 ; arg 5: y (baseline)
    lea r9, [rel drawText]      ; arg 6: string = drawText
    call XDrawString
    add rsp, 16                 ; 8 (arg) + 8 (pad)

    jmp .loop

.gcCreationFailed:
    ; Print a message
    ; sys_write(uint fd, const char *buf, size_t count)
    ; sys_write(1, message, 13)
    mov rax, sys_write      ; sys_write syscall number
    mov rdi, stdout         ; Fle descriptor 1 (stdout)
    lea rsi, [rel gcCreationFailedMessage]  ; Pointer to message
    mov rdx, gcCreationFailedMessageLength  ; Number of bytes to write
    syscall                 ; Invoke kernel

    jmp .exit

.loadingFontFailed:
    ; Print a message
    ; sys_write(uint fd, const char *buf, size_t count)
    ; sys_write(1, message, 13)
    mov rax, sys_write      ; sys_write syscall number
    mov rdi, stdout         ; Fle descriptor 1 (stdout)
    lea rsi, [rel loadingFontFailedMessage]  ; Pointer to message
    mov rdx, loadingFontFailedMessageLength  ; Number of bytes to write
    syscall                 ; Invoke kernel

    jmp .exit

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

