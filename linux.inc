%define stdout 1

; https://github.com/las-nish/NASM-Assembly-Collection/blob/main/Linux%20System%20Call.MD

; sys_write(uint fd, const char *buf, size_t count)
%define sys_write 1

; sys_close(uint fd)
%define sys_close 3

; sys_poll(struct pollfd *ufds, uint nfds, int timeout_msecs)
%define sys_poll 7
%define POLLIN 1            ; There's data to read

; sys_exit(int error_code)
%define sys_exit 60

; sys_socket(int family, int type, int protocol)
%define sys_socket 41
%define AF_INET 2           ; IPv4 protocol
%define SOCK_STREAM 1       ; TCP socket
%define SOCK_NONBLOCK 0x800 ; Non blocking socket
%define INADDR_ANY 0        ; Any address (0.0.0.0)

; sys_connect(int fd, struct sockaddr *addr, int addrlen)
%define sys_connect 42

; sys_accept(int fd, struct sockaddr *addr, int *addrlen)
%define sys_accept 43

; sys_sendto(int fd, void *buf, size_t len, unsigned flags, struct sockaddr *addr, int addrlen)
%define sys_sendto 44

; sys_recvfrom(int fd, void *buf, size_t len, unsigned flags, struct sockaddr *addr, int *addrlen)
%define sys_recvfrom 45

; sys_bind(int fd, struct sockaddr *addr, int addrlen)
%define sys_bind 49
%define EADDRINUSE 98       ; Address already in use

; sys_listen(int fd, int backlog)
%define sys_listen 50

; sys_setsockopt(int fd, int level, int optname, char *optval, int optlen)
%define sys_setsockopt 54
%define SOL_SOCKET 1
%define SO_REUSEADDR 2      ; Reuse the port right after the server closes

; sys_fcntl(uint fd, uint cmd, ulong arg)
%define sys_fcntl 72
%define F_SETFL 4
%define O_NONBLOCK 0x800

; Arguments seems to be in this format:
; rax -> syscall number
; rdi -> first  argument
; rsi -> second argument
; rdx -> third  argument
; r10.. r8.. r9..
; Unsure why it's R8 THEN r9 but ok

; https://github.com/las-nish/NASM-Assembly-Collection/blob/main/Linux%20System%20Call.MD
