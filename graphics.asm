%include "x11.inc"
%include "linux.inc"

extern display
extern window
extern isServer
extern playerId
extern sprintf

global create_graphics_context
global draw_text

section .data
    gcCreationFailedMessage: db "Graphics context failed to create", 0x0A
    gcCreationFailedMessageLength: equ $ - gcCreationFailedMessage

    loadingFontFailedMessage: db "Font failed to load", 0x0A
    loadingFontFailedMessageLength: equ $ - loadingFontFailedMessage

    hostText: db "u r host"
    hostTextLength: equ $ - hostText

    clientTextFormat: db "u r client: %d", 0

    serverFullText: db "server is full"
    serverFullTextLength: equ $ - serverFullText

    ; xlsfonts
    fontName: db "-misc-fixed-medium-r-normal--13-120-75-75-c-70-iso10646-1", 0x00

section .bss
    gc:         resq 1
    font:       resq 1

    clientText: resb 32         ; "u r client: id" gets written here

section .text

; Creates the graphics context and sets its font and color
; Returns 1 in eax on success, 0 on failure
create_graphics_context:
    push rbp
    mov rbp, rsp

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

    mov eax, 1                  ; Success
    pop rbp
    ret

.gcCreationFailed:
    ; Print a message
    ; sys_write(uint fd, const char *buf, size_t count)
    ; sys_write(1, message, 13)
    mov rax, sys_write      ; sys_write syscall number
    mov rdi, stdout         ; Fle descriptor 1 (stdout)
    lea rsi, [rel gcCreationFailedMessage]  ; Pointer to message
    mov rdx, gcCreationFailedMessageLength  ; Number of bytes to write
    syscall                 ; Invoke kernel

    xor eax, eax            ; Failure
    pop rbp
    ret

.loadingFontFailed:
    ; Print a message
    ; sys_write(uint fd, const char *buf, size_t count)
    ; sys_write(1, message, 13)
    mov rax, sys_write      ; sys_write syscall number
    mov rdi, stdout         ; Fle descriptor 1 (stdout)
    lea rsi, [rel loadingFontFailedMessage]  ; Pointer to message
    mov rdx, loadingFontFailedMessageLength  ; Number of bytes to write
    syscall                 ; Invoke kernel

    xor eax, eax            ; Failure
    pop rbp
    ret

; Draws the text onto the window ("u r host", "u r client: id" or "server is full")
draw_text:
    push rbp
    mov rbp, rsp

    ; Pick the text based on if we're the host or a client
    lea r9, [rel hostText]      ; string = hostText
    mov eax, hostTextLength     ; length = hostTextLength
    cmp byte [rel isServer], 1  ; Check if we're the server
    je .drawString

    lea r9, [rel serverFullText]    ; string = serverFullText
    mov eax, serverFullTextLength   ; length = serverFullTextLength
    cmp dword [rel playerId], 0     ; Check if we couldn't join (no id)
    je .drawString

    ; int sprintf(char *str, const char *format, ...);
    ; sprintf(clientText, "u r client: %d", playerId)
    lea rdi, [rel clientText]       ; arg 1: str    = clientText
    lea rsi, [rel clientTextFormat] ; arg 2: format = clientTextFormat
    mov edx, [rel playerId]         ; arg 3: playerId
    xor eax, eax
    call sprintf                    ; Returns the length of the text
    lea r9, [rel clientText]        ; string = clientText

.drawString:
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
    push rax                    ; arg 7: length = length of the text

    mov rdi, [rel display]      ; arg 1: Display*
    mov rsi, [rel window]       ; arg 2: Drawable = window
    mov rdx, [rel gc]           ; arg 3: GC = gc
    mov ecx, 20                 ; arg 4: x
    mov r8d, 20                 ; arg 5: y (baseline)
                                ; arg 6: string = the text (already in r9)
    call XDrawString
    add rsp, 16                 ; 8 (arg) + 8 (pad)

    pop rbp
    ret
