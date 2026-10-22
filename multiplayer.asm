%include "linux.inc"

extern host_server
extern connect_to_server

global start_multiplayer
global isServer
global playerId
global serverAddress
global serverAddressLength

section .data
    ; sockaddr_in serverAddress;
    serverAddress:
        dw AF_INET              ; sin_family = AF_INET
        dw 0x901F               ; sin_port   = htons(8080) (big endian, so the bytes are swapped)
        dd INADDR_ANY           ; sin_addr   = INADDR_ANY
        dq 0                    ; Padding to the size of sockaddr
    serverAddressLength: equ $ - serverAddress

    hostingFailedMessage: db "Failed to host the server", 0x0A
    hostingFailedMessageLength: equ $ - hostingFailedMessage

    joiningServerMessage: db "Server is already running, joining as a client", 0x0A
    joiningServerMessageLength: equ $ - joiningServerMessage

section .bss
    isServer:   resb 1          ; 1 = server (host), 0 = client
    playerId:   resd 1          ; 1 = host, 2..MAX_PLAYERS = clients, 0 = couldn't join

section .text

; Hosts the server, or joins it as a client if it's already running (1st player = host)
start_multiplayer:
    push rbp
    mov rbp, rsp

    ; Try to host the server
    call host_server
    test eax, eax                   ; Check if failed
    js .hostingFailed

    mov byte [rel isServer], 1      ; We're the server
    mov dword [rel playerId], 1     ; The host is player 1

    pop rbp
    ret

.hostingFailed:
    cmp eax, -EADDRINUSE            ; Check if the server is already running
    jne .hostingFailedOther

    mov byte [rel isServer], 0      ; We're a client

    ; Print a message
    ; sys_write(uint fd, const char *buf, size_t count)
    mov rax, sys_write      ; sys_write syscall number
    mov rdi, stdout         ; Fle descriptor 1 (stdout)
    lea rsi, [rel joiningServerMessage]  ; Pointer to message
    mov rdx, joiningServerMessageLength  ; Number of bytes to write
    syscall                 ; Invoke kernel

    ; Join the server
    call connect_to_server

    pop rbp
    ret

.hostingFailedOther:
    ; Print a message
    ; sys_write(uint fd, const char *buf, size_t count)
    mov rax, sys_write      ; sys_write syscall number
    mov rdi, stdout         ; Fle descriptor 1 (stdout)
    lea rsi, [rel hostingFailedMessage]  ; Pointer to message
    mov rdx, hostingFailedMessageLength  ; Number of bytes to write
    syscall                 ; Invoke kernel

    pop rbp
    ret
