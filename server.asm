%include "linux.inc"

extern serverAddress
extern serverAddressLength
extern printf

global host_server
global accept_client
global serverSocket

section .data
    reuseAddress: dd 1              ; int reuseAddress = 1 (for SO_REUSEADDR)

    serverListeningMessage: db "Server is listening on port 8080", 0x0A
    serverListeningMessageLength: equ $ - serverListeningMessage

    clientMessageFormat: db "Message from client: %s", 0x0A, 0

section .bss
    serverSocket: resd 1            ; int serverSocket
    clientSocket: resd 1            ; int clientSocket

    buffer:       resb 1024         ; char buffer[1024]
    bufferLength: equ $ - buffer

section .text

; Creates the server socket, binds it to port 8080 and listens on it
; Returns 0 in eax on success, the negative error code on failure (-EADDRINUSE if the server is already running)
host_server:
    push rbp
    mov rbp, rsp

    ; Create a socket
    ; int serverSocket = socket(AF_INET, SOCK_STREAM | SOCK_NONBLOCK, 0);
    ; sys_socket(int family, int type, int protocol)
    mov eax, sys_socket             ; sys_socket syscall number
    mov edi, AF_INET                ; arg 1: family   = AF_INET (IPv4)
    mov esi, SOCK_STREAM | SOCK_NONBLOCK   ; arg 2: type     = SOCK_STREAM (TCP) | SOCK_NONBLOCK (non blocking)
    xor edx, edx                    ; arg 3: protocol = 0 (default for TCP)
    syscall                         ; Invoke kernel

    test eax, eax                   ; Check if failed (negative = error)
    js .failed

    mov [rel serverSocket], eax     ; Save the socket fd

    ; Let the port be reused right after the server closes
    ; setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &reuseAddress, sizeof(reuseAddress));
    ; sys_setsockopt(int fd, int level, int optname, char *optval, int optlen)
    mov eax, sys_setsockopt         ; sys_setsockopt syscall number
    mov edi, [rel serverSocket]     ; arg 1: fd      = serverSocket
    mov esi, SOL_SOCKET             ; arg 2: level   = SOL_SOCKET
    mov edx, SO_REUSEADDR           ; arg 3: optname = SO_REUSEADDR
    lea r10, [rel reuseAddress]     ; arg 4: optval  = &reuseAddress
    mov r8d, 4                      ; arg 5: optlen  = sizeof(int)
    syscall                         ; Invoke kernel

    ; Bind the socket to the address
    ; bind(serverSocket, (struct sockaddr*)&serverAddress, sizeof(serverAddress));
    ; sys_bind(int fd, struct sockaddr *addr, int addrlen)
    mov eax, sys_bind               ; sys_bind syscall number
    mov edi, [rel serverSocket]     ; arg 1: fd      = serverSocket
    lea rsi, [rel serverAddress]    ; arg 2: addr    = &serverAddress
    mov edx, serverAddressLength    ; arg 3: addrlen = sizeof(serverAddress)
    syscall                         ; Invoke kernel

    test eax, eax                   ; Check if failed (-EADDRINUSE = server is already running)
    js .closeSocket

    ; Listen to the socket
    ; listen(serverSocket, 5);
    ; sys_listen(int fd, int backlog)
    mov eax, sys_listen             ; sys_listen syscall number
    mov edi, [rel serverSocket]     ; arg 1: fd      = serverSocket
    mov esi, 5                      ; arg 2: backlog = 5 (max players waiting to be accepted)
    syscall                         ; Invoke kernel

    test eax, eax                   ; Check if failed
    js .closeSocket

    ; Print a message
    ; sys_write(uint fd, const char *buf, size_t count)
    mov rax, sys_write      ; sys_write syscall number
    mov rdi, stdout         ; Fle descriptor 1 (stdout)
    lea rsi, [rel serverListeningMessage]  ; Pointer to message
    mov rdx, serverListeningMessageLength  ; Number of bytes to write
    syscall                 ; Invoke kernel

    xor eax, eax                    ; Success
    pop rbp
    ret

.closeSocket:
    push rax                        ; Save the error code

    ; Close the socket
    ; close(serverSocket);
    ; sys_close(uint fd)
    mov eax, sys_close              ; sys_close syscall number
    mov edi, [rel serverSocket]     ; arg 1: fd = serverSocket
    syscall                         ; Invoke kernel

    pop rax                         ; Restore the error code

.failed:
    pop rbp
    ret

; Accepts a new player and prints their message
; Doesn't block, returns right away if there's no player waiting
accept_client:
    push rbp
    mov rbp, rsp

    ; Accept the connection request
    ; int clientSocket = accept(serverSocket, nullptr, nullptr);
    ; sys_accept(int fd, struct sockaddr *addr, int *addrlen)
    mov eax, sys_accept             ; sys_accept syscall number
    mov edi, [rel serverSocket]     ; arg 1: fd      = serverSocket
    xor esi, esi                    ; arg 2: addr    = nullptr
    xor edx, edx                    ; arg 3: addrlen = nullptr
    syscall                         ; Invoke kernel

    test eax, eax                   ; Check if failed (-EAGAIN = no player waiting)
    js .done

    mov [rel clientSocket], eax     ; Save the client's socket fd

    ; Receive data
    ; recv(clientSocket, buffer, sizeof(buffer), 0);
    ; sys_recvfrom(int fd, void *buf, size_t len, unsigned flags, struct sockaddr *addr, int *addrlen)
    mov eax, sys_recvfrom           ; sys_recvfrom syscall number
    mov edi, [rel clientSocket]     ; arg 1: fd      = clientSocket
    lea rsi, [rel buffer]           ; arg 2: buf     = buffer
    mov edx, bufferLength - 1       ; arg 3: len     = sizeof(buffer) - 1 (room for the null terminator)
    xor r10d, r10d                  ; arg 4: flags   = 0
    xor r8d, r8d                    ; arg 5: addr    = nullptr
    xor r9d, r9d                    ; arg 6: addrlen = nullptr
    syscall                         ; Invoke kernel

    test eax, eax                   ; Check if failed
    js .done

    lea rdi, [rel buffer]
    mov byte [rdi + rax], 0         ; Null terminate the message

    ; cout << "Message from client: " << buffer << endl;
    ; printf("Message from client: %s\n", buffer)
    lea rdi, [rel clientMessageFormat]
    lea rsi, [rel buffer]
    xor eax, eax
    call printf

.done:
    pop rbp
    ret
