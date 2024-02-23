global start
extern long_mode_start

section .data
    ; VGA text mode buffer
    vga_buffer: equ 0xB8000
    ; VGA graphics mode buffer
    vga_graphics_buffer: equ 0xA0000
    ; Current position in the text buffer
    text_pos: dq 0

section .text
bits 64
start:
    mov rsp, stack_top

    call check_multiboot
    call check_cpuid
    call check_long_mode

    call setup_page_tables
    call enable_paging

    lgdt [gdt64.pointer]
    jmp gdt64.code_segment:long_mode_start

    hlt

check_multiboot:
    cmp rax, 0x36d76289
    jne .no_multiboot
    ret
.no_multiboot:
    mov al, "M"
    jmp error

check_cpuid:
    pushfq
    pop rax
    mov rcx, rax
    xor rax, 1 << 21
    push rax
    popfq
    pushfq
    pop rax
    push rcx
    popfq
    cmp rax, rcx
    je .no_cpuid
    ret
.no_cpuid:
    mov al, "C"
    jmp error

check_long_mode:
    mov rax, 0x80000000
    cpuid
    cmp rax, 0x80000001
    jb .no_long_mode

    mov rax, 0x80000001
    cpuid
    test rdx, 1 << 29
    jz .no_long_mode
    ret
.no_long_mode:
    mov al, "L"
    jmp error

setup_page_tables:
    mov rax, page_table_l3
    or rax, 0b11 ; present, writable
    mov [page_table_l4], rax

    mov rax, page_table_l2
    or rax, 0b11 ; present, writable
    mov [page_table_l3], rax

    mov rcx, 0 ; counter
.loop:

    mov rax, 0x200000 ; 2MiB
    mul rcx
    or rax, 0b10000011 ; present, writable, huge page
    mov [page_table_l2 + rcx * 8], rax

    inc  rcx ; increment counter
    cmp rcx, 512 ; checks if the whole table is mapped
    jne .loop ; if not, continue

    ret

enable_paging:
    ; pass page table location to cpu
    mov rax, page_table_l4
    mov cr3, rax

    ; enable PAE
    mov rax, cr4
    or rax, 1 << 5
    mov cr4, rax

    ; enable long mode
    mov rcx, 0xC0000080
    rdmsr
    or rax, 1 << 8
    wrmsr

    ; enable paging
    mov rax, cr0
    or rax, 1 << 31
    mov cr0, rax

    ret

error:
    ; print "ERR: X" where X is the error code
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8004], 0x4f3a4f52
    mov dword [0xb8008], 0x4f204f20
    mov byte [0xb800a], al
    hlt

    ; Function to write a character to the VGA text buffer
    ; Input: al = character, ah = color
    write_char:
        mov [vga_buffer + text_pos], ax
        add text_pos, 2
        ret

    ; Function to set a pixel in VGA mode 13h
    ; Input: ax = x, bx = y, cl = color
    set_pixel:
        ; Calculate the offset in the buffer
        ; (y * 320 + x)
        imul rdx, rbx, 320
        add rdx, rax
        ; Set the pixel
        mov [vga_graphics_buffer + rdx], cl
        ret

    ; Function to switch to VGA mode 13h
    set_mode_13h:
        mov ax, 0x0013
        int 0x10
        ret

section .bss
align 4096
page_table_l4:
    resb 4096
page_table_l3:
    resb 4096
page_table_l2:
    resb 4096
stack_bottom:
    resb 4096 * 4
stack_top:

section .rodata
gdt64:
    dq 0 ; zero entry
.code_segment: equ $ - gdt64
    dq (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53) ; code segment
.pointer:
    dw $ - gdt64 - 1
    dq gdt64%