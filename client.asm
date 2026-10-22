%include "linux.inc"

extern serverAddress
extern serverAddressLength
extern playerId
extern printf

global connect_to_server

section .data
    message: db "Hello, server!"    ; const char* message = "Hello, server!";
    messageLength: equ $ - message

    connectingFailedMessage: db "Failed to connect to the server", 0x0A
    connectingFailedMessageLength: equ $ - connectingFailedMessage

    serverFullMessage: db "Server is full, couldn't join", 0x0A
    serverFullMessageLength: equ $ - serverFullMessage

    joinedFormat: db "Joined as player %d", 0x0A, 0

section .bss
    clientSocket: resd 1            ; int clientSocket
    receivedId:   resb 1            ; Id received from the server

section .text

; Connects to the server, sends it a message and receives our player id
connect_to_server:
    push rbp
    mov rbp, rsp

    ; Create a socket
    ; int clientSocket = socket(AF_INET, SOCK_STREAM, 0);
    ; sys_socket(int family, int type, int protocol)
    mov eax, sys_socket             ; sys_socket syscall number
    mov edi, AF_INET                ; arg 1: family   = AF_INET (IPv4)
    mov esi, SOCK_STREAM            ; arg 2: type     = SOCK_STREAM (TCP)
    xor edx, edx                    ; arg 3: protocol = 0 (default for TCP)
    syscall                         ; Invoke kernel

    test eax, eax                   ; Check if failed (negative = error)
    js .connectingFailed

    mov [rel clientSocket], eax     ; Save the socket fd

    ; Send the connection request
    ; connect(clientSocket, (struct sockaddr*)&serverAddress, sizeof(serverAddress));
    ; sys_connect(int fd, struct sockaddr *addr, int addrlen)
    mov eax, sys_connect            ; sys_connect syscall number
    mov edi, [rel clientSocket]     ; arg 1: fd      = clientSocket
    lea rsi, [rel serverAddress]    ; arg 2: addr    = &serverAddress
    mov edx, serverAddressLength    ; arg 3: addrlen = sizeof(serverAddress)
    syscall                         ; Invoke kernel

    test eax, eax                   ; Check if failed
    js .closeSocket

    ; Send data
    ; send(clientSocket, message, strlen(message), 0);
    ; sys_sendto(int fd, void *buf, size_t len, unsigned flags, struct sockaddr *addr, int addrlen)
    mov eax, sys_sendto             ; sys_sendto syscall number
    mov edi, [rel clientSocket]     ; arg 1: fd      = clientSocket
    lea rsi, [rel message]          ; arg 2: buf     = message
    mov edx, messageLength          ; arg 3: len     = strlen(message)
    xor r10d, r10d                  ; arg 4: flags   = 0
    xor r8d, r8d                    ; arg 5: addr    = nullptr
    xor r9d, r9d                    ; arg 6: addrlen = 0
    syscall                         ; Invoke kernel

    ; Receive our player id (waits until the server sends it)
    ; recv(clientSocket, &receivedId, 1, 0);
    ; sys_recvfrom(int fd, void *buf, size_t len, unsigned flags, struct sockaddr *addr, int *addrlen)
    mov eax, sys_recvfrom           ; sys_recvfrom syscall number
    mov edi, [rel clientSocket]     ; arg 1: fd      = clientSocket
    lea rsi, [rel receivedId]       ; arg 2: buf     = &receivedId
    mov edx, 1                      ; arg 3: len     = 1 byte
    xor r10d, r10d                  ; arg 4: flags   = 0
    xor r8d, r8d                    ; arg 5: addr    = nullptr
    xor r9d, r9d                    ; arg 6: addrlen = nullptr
    syscall                         ; Invoke kernel

    cmp eax, 1                      ; Check if we got the id (0 = the server closed the connection, it's full)
    jne .serverFull

    movzx eax, byte [rel receivedId]
    mov [rel playerId], eax         ; playerId = receivedId

    ; printf("Joined as player %d\n", playerId)
    lea rdi, [rel joinedFormat]
    mov esi, [rel playerId]
    xor eax, eax
    call printf

    pop rbp
    ret

.serverFull:
    ; Close the socket
    ; close(clientSocket);
    ; sys_close(uint fd)
    mov eax, sys_close              ; sys_close syscall number
    mov edi, [rel clientSocket]     ; arg 1: fd = clientSocket
    syscall                         ; Invoke kernel

    ; Print a message
    ; sys_write(uint fd, const char *buf, size_t count)
    mov rax, sys_write      ; sys_write syscall number
    mov rdi, stdout         ; Fle descriptor 1 (stdout)
    lea rsi, [rel serverFullMessage]  ; Pointer to message
    mov rdx, serverFullMessageLength  ; Number of bytes to write
    syscall                 ; Invoke kernel

    pop rbp
    ret

.closeSocket:
    ; Close the socket
    ; close(clientSocket);
    ; sys_close(uint fd)
    mov eax, sys_close              ; sys_close syscall number
    mov edi, [rel clientSocket]     ; arg 1: fd = clientSocket
    syscall                         ; Invoke kernel

.connectingFailed:
    ; Print a message
    ; sys_write(uint fd, const char *buf, size_t count)
    mov rax, sys_write      ; sys_write syscall number
    mov rdi, stdout         ; Fle descriptor 1 (stdout)
    lea rsi, [rel connectingFailedMessage]  ; Pointer to message
    mov rdx, connectingFailedMessageLength  ; Number of bytes to write
    syscall                 ; Invoke kernel

    pop rbp
    ret
