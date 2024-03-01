org 0x7c00
bits 16


;
;       FAT12 BIOS Parameter Block (BPB)
;
jmp short main                              ; Start execution from main
nop                                         ; Convention

bpb_oem_identifier:         db "MSWIN4.1"   ; Version of DOS
bpb_bytes_per_sector:       dw 512          ; Bytes per sector
bpb_sectors_per_cluster:    db 1            ; Sector per cluster
bpb_reserved_sectors:       dw 1            ; Only this sector is reserved
bpb_fat_count:              db 2            ; Number of File Allocation Tables (usually 2)
bpb_dir_entries_count:      dw 0xe0         ; Number of root directories (e0 = 224 is standard)
bpb_total_sectors:          dw 2880         ; 2880 sectors for a 1.44MB floppy
bpb_media_descriptor_type:  db 0xf0         ; Standard for a 1.44MB floppy
bpb_sectors_per_fat:        dw 9            ;  "
bpb_sectors_per_track:      dw 18           ;  "
bpb_heads:                  dw 2            ;  "
bpb_hidden_sectors:         dd 0            ;  " (Offset of LBA)
bpb_large_sector_count:     dd 0            ;  "


;
;       Extended Boot Record (EBR)
;
ebr_drive_number:           db 0                ; Drive number (0 for floppy disk)
                            db 0                ; Reserved byte (for windows NT flag)
ebr_signature:              db 0x29             ; Signature for floppy
ebr_volume_id:              dd 0x12345678       ; Volume ID (DOES NOT MATTER)
ebr_label:                  db "SUS OS     "    ; Must be eleven bytes
ebr_system_id:              db "FAT12   "       ; Must be eight bytes


main:
    ; Set data, extra, and stack segments to 0
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax

    mov sp, 0x7c00 ; Move stack pointer to here and grow down

    mov [ebr_drive_number], dl  ; Drive number stored in dl on boot
    
    ; Read Disk
    mov ah, 2       ; Disk read
    mov al, 1       ; Sectors to read
    
    mov cl, 1       ; Sector number
    mov bx, 0x7e00
    

    mov si, boot_msg
    call print


jmp $ ; Suspend program execution past here

disk_read:
    push ax
    push bx
    push cx

    call lba_to_chs

print:
    push ax
    push bx
    push si

    mov ah, 0x0e    ; Set to Teletype mode
    mov bh, 0       ; Page number 0 (main screen)

print_loop:
    lodsb           ; Put next byte from si into al
    or al, al       ; Only zero when al is 0 (NULL CHAR)
    jz print_done

    int 0x10        ; Print to screen
    jmp print_loop
    

print_done:
    pop si
    pop bx
    pop ax

    ret


boot_msg: db "BOOT!", 0x0d, 0x0a, 0 ; "Boot!\n"

; Make bootloader 512 bytes with end signature
times 510 - ($ - $$) db 0
dw 0xaa55
