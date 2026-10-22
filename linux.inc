%define stdout 1

; https://github.com/las-nish/NASM-Assembly-Collection/blob/main/Linux%20System%20Call.MD

; sys_write(uint fd, const char *buf, size_t count)
%define sys_write 1

; sys_exit(int error_code)
%define sys_exit 60

; Arguments seems to be in this format:
; rax -> syscall number
; rdi -> first  argument
; rsi -> second argument
; rdx -> third  argument
; r10.. r8.. r9..
; Unsure why it's R8 THEN r9 but ok

; https://github.com/las-nish/NASM-Assembly-Collection/blob/main/Linux%20System%20Call.MD
