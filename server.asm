%include "linux.inc"
%include "multiplayer.inc"

extern serverAddress
extern serverAddressLength
extern printf

global host_server
global update_server
global fill_server_poll_fds
global serverSocket

section .data
    reuseAddress: dd 1              ; int reuseAddress = 1 (for SO_REUSEADDR)

    serverListeningMessage: db "Server is listening on port 8080", 0x0A
    serverListeningMessageLength: equ $ - serverListeningMessage

    clientMessageFormat: db "Message from client: %s", 0x0A, 0

    playerJoinedFormat: db "Player %d joined (%d/%d players)", 0x0A, 0
    playerLeftFormat:   db "Player %d left (%d/%d players)", 0x0A, 0
    serverFullFormat:   db "Server is full (%d/%d players), player rejected", 0x0A, 0

section .bss
    serverSocket:  resd 1           ; int serverSocket
    clientSockets: resd MAX_CLIENTS ; int clientSockets[MAX_CLIENTS] (-1 = empty slot)
    playerCount:   resd 1           ; int playerCount (including the host)
    newPlayerId:   resb 1           ; Id sent to the player that just joined

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

    ; Mark every player slot as empty
    lea rdi, [rel clientSockets]
    xor ecx, ecx                    ; i = 0

.clearSlot:
    mov dword [rdi + rcx*4], -1     ; clientSockets[i] = -1
    inc ecx                         ; i++
    cmp ecx, MAX_CLIENTS
    jl .clearSlot

    mov dword [rel playerCount], 1  ; The host is the 1st player

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

; Accepts new players and receives messages from the connected ones
; Doesn't block, returns right away if there's nothing to do
update_server:
    push rbp
    mov rbp, rsp

    call accept_client
    call receive_from_clients

    pop rbp
    ret

; Accepts a new player if there's a free slot, otherwise rejects them
accept_client:
    push rbp
    mov rbp, rsp

    ; Accept the connection request (the player's socket is non blocking too)
    ; int clientSocket = accept4(serverSocket, nullptr, nullptr, SOCK_NONBLOCK);
    ; sys_accept4(int fd, struct sockaddr *addr, int *addrlen, int flags)
    mov eax, sys_accept4            ; sys_accept4 syscall number
    mov edi, [rel serverSocket]     ; arg 1: fd      = serverSocket
    xor esi, esi                    ; arg 2: addr    = nullptr
    xor edx, edx                    ; arg 3: addrlen = nullptr
    mov r10d, SOCK_NONBLOCK         ; arg 4: flags   = SOCK_NONBLOCK (non blocking)
    syscall                         ; Invoke kernel

    test eax, eax                   ; Check if failed (-EAGAIN = no player waiting)
    js .done

    cmp dword [rel playerCount], MAX_PLAYERS    ; Check if the server is full
    jge .serverFull

    ; Find an empty slot
    lea rdi, [rel clientSockets]
    xor ecx, ecx                    ; i = 0

.findSlot:
    cmp dword [rdi + rcx*4], -1     ; Check if clientSockets[i] is empty
    je .foundSlot
    inc ecx                         ; i++
    cmp ecx, MAX_CLIENTS
    jl .findSlot                    ; if i < MAX_CLIENTS
    jmp .serverFull                 ; No empty slot

.foundSlot:
    mov [rdi + rcx*4], eax          ; clientSockets[i] = clientSocket
    inc dword [rel playerCount]     ; playerCount++

    add ecx, 2                      ; id = i + 2 (the host is 1)
    mov [rel newPlayerId], cl       ; Save the player's id

    ; Tell the player their id
    ; send(clientSocket, &newPlayerId, 1, 0);
    ; sys_sendto(int fd, void *buf, size_t len, unsigned flags, struct sockaddr *addr, int addrlen)
    mov eax, sys_sendto             ; sys_sendto syscall number
    mov edi, eax                    ; arg 1: fd      = clientSocket
    lea rsi, [rel newPlayerId]      ; arg 2: buf     = &newPlayerId
    mov edx, 1                      ; arg 3: len     = 1 byte
    xor r10d, r10d                  ; arg 4: flags   = 0
    xor r8d, r8d                    ; arg 5: addr    = nullptr
    xor r9d, r9d                    ; arg 6: addrlen = 0
    syscall                         ; Invoke kernel

    ; printf("Player %d joined (%d/%d players)\n", newPlayerId, playerCount, MAX_PLAYERS)
    lea rdi, [rel playerJoinedFormat]
    movzx esi, byte [rel newPlayerId]
    mov edx, [rel playerCount]
    mov ecx, MAX_PLAYERS
    xor eax, eax
    call printf

    jmp .done

.serverFull:
    ; Close the player's socket
    ; close(clientSocket);
    ; sys_close(uint fd)
    mov edi, eax                    ; arg 1: fd = clientSocket
    mov eax, sys_close              ; sys_close syscall number
    syscall                         ; Invoke kernel

    ; printf("Server is full (%d/%d players), player rejected\n", playerCount, MAX_PLAYERS)
    lea rdi, [rel serverFullFormat]
    mov esi, [rel playerCount]
    mov edx, MAX_PLAYERS
    xor eax, eax
    call printf

.done:
    pop rbp
    ret

; Receives messages from every connected player, and removes the ones that left
receive_from_clients:
    push rbp
    mov rbp, rsp
    push rbx                        ; Save rbx (callee saved), used for the slot index
    push r12                        ; Save r12 (callee saved), used for the player's socket

    xor ebx, ebx                    ; i = 0

.nextSlot:
    lea rax, [rel clientSockets]
    mov r12d, [rax + rbx*4]         ; r12d = clientSockets[i]
    cmp r12d, -1                    ; Check if the slot is empty
    je .skipSlot

    ; Receive data
    ; recv(clientSockets[i], buffer, sizeof(buffer) - 1, 0);
    ; sys_recvfrom(int fd, void *buf, size_t len, unsigned flags, struct sockaddr *addr, int *addrlen)
    mov eax, sys_recvfrom           ; sys_recvfrom syscall number
    mov edi, r12d                   ; arg 1: fd      = clientSockets[i]
    lea rsi, [rel buffer]           ; arg 2: buf     = buffer
    mov edx, bufferLength - 1       ; arg 3: len     = sizeof(buffer) - 1 (room for the null terminator)
    xor r10d, r10d                  ; arg 4: flags   = 0
    xor r8d, r8d                    ; arg 5: addr    = nullptr
    xor r9d, r9d                    ; arg 6: addrlen = nullptr
    syscall                         ; Invoke kernel

    cmp eax, -EAGAIN                ; Check if there's nothing to read yet
    je .skipSlot
    test eax, eax                   ; Check if the player left (0 = disconnected, negative = error)
    jle .playerLeft

    lea rdi, [rel buffer]
    mov byte [rdi + rax], 0         ; Null terminate the message

    ; cout << "Message from client: " << buffer << endl;
    ; printf("Message from client: %s\n", buffer)
    lea rdi, [rel clientMessageFormat]
    lea rsi, [rel buffer]
    xor eax, eax
    call printf

    jmp .skipSlot

.playerLeft:
    ; Close the player's socket
    ; close(clientSockets[i]);
    ; sys_close(uint fd)
    mov eax, sys_close              ; sys_close syscall number
    mov edi, r12d                   ; arg 1: fd = clientSockets[i]
    syscall                         ; Invoke kernel

    lea rax, [rel clientSockets]
    mov dword [rax + rbx*4], -1     ; clientSockets[i] = -1 (empty slot)
    dec dword [rel playerCount]     ; playerCount--

    ; printf("Player %d left (%d/%d players)\n", i + 2, playerCount, MAX_PLAYERS)
    lea rdi, [rel playerLeftFormat]
    lea esi, [ebx + 2]              ; id = i + 2 (the host is 1)
    mov edx, [rel playerCount]
    mov ecx, MAX_PLAYERS
    xor eax, eax
    call printf

.skipSlot:
    inc ebx                         ; i++
    cmp ebx, MAX_CLIENTS
    jl .nextSlot

    pop r12                         ; Restore r12
    pop rbx                         ; Restore rbx
    pop rbp
    ret

; Fills pollFds with the server socket and every player's socket (to wait on them with poll)
; Takes the pollfd array in rdi, returns the number of pollfds filled in eax
fill_server_poll_fds:
    push rbp
    mov rbp, rsp

    ; pollFds[0] = { serverSocket, POLLIN, 0 } (a player is waiting to join)
    mov eax, [rel serverSocket]
    mov [rdi], eax                  ; .fd      = serverSocket
    mov word [rdi + 4], POLLIN      ; .events  = POLLIN
    mov word [rdi + 6], 0           ; .revents = 0

    ; pollFds[1 + i] = { clientSockets[i], POLLIN, 0 } (poll ignores -1 = empty slot)
    lea rsi, [rel clientSockets]
    xor ecx, ecx                    ; i = 0

.fillSlot:
    mov eax, [rsi + rcx*4]
    mov [rdi + 8 + rcx*8], eax              ; .fd      = clientSockets[i]
    mov word [rdi + 8 + rcx*8 + 4], POLLIN  ; .events  = POLLIN
    mov word [rdi + 8 + rcx*8 + 6], 0       ; .revents = 0
    inc ecx                         ; i++
    cmp ecx, MAX_CLIENTS
    jl .fillSlot

    mov eax, 1 + MAX_CLIENTS        ; Number of pollfds filled

    pop rbp
    ret

