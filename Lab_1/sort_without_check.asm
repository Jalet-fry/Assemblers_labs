;
CR          EQU   0Dh
LF          EQU   0Ah
MaxKBufLen  EQU   80                ; With CR terminator
MaxWordNum  EQU   MaxKBufLen/2      ; char + space -> word
; LenPosStruct (emu8086 not supports structures ;o)
PosOffs     EQU   0
LenOffs     EQU   PosOffs + 1
LenPosLen   EQU   2
;
_CODE SEGMENT
      ORG   100h
START:
      JMP   EXEC
sdAppInfo   DB    "Arranges words in descending length", CR, LF
            DB    "Wickedly Crafted in emu8086  (C:) Kangaroo Limited", CR, LF, "$"
sdPrompt    DB    " enter string of words (empty string - exit)"
sdCrLf      DB    CR, LF, "$"
EXEC:
      LEA   DX, sdAppInfo
      CALL  showSd
STR_LOOP:
      LEA   DX, sdPrompt
      LEA   SI, kbBuf
      MOV   CX, MaxKBufLen
      CALL  inputSc
      JCXZ  EXIT
      LEA   DI, asWrdLenPos
      CALL  sc2WordLenPosArray
      JCXZ  EXIT
      CALL  crLf
      MOV   SI, DI
      CALL  sortDescWordArray
      MOV   BX, SI
      LEA   DI, chBufOut
      LEA   SI, chBufIn
      CALL  wordLenPosArray2Sd
      MOV   DX, DI
      CALL  showSd
      CALL  crLf
      JMP   STR_LOOP
EXIT:
      RET
;
wordLenPosArray2Sd PROC
; Input: BX = address of array of word parameters structs
;        CX = array length in structs
;        DI = address of destination string buffer
;        SI = address of source string buffer
; Used:  AX BX CX DX SI
      PUSH  DI
      XOR   DH, DH
sdloop:
      PUSH  CX
      PUSH  SI
      MOV   DL, [BX+PosOffs]
      ADD   SI, DX
      XOR   CH, CH
      MOV   CL, [BX+LenOffs]
      REP MOVSB
      MOV   AL, " "
      STOSB
      POP   SI
      POP   CX
      ADD   BX, LenPosLen
      LOOP  sdloop
      MOV   Byte Ptr [DI-1], "$"
      POP   DI
      RET
wordLenPosArray2Sd ENDP
;
sc2WordLenPosArray PROC
; Input:  DI = address of array of word parameters structs
;         SI = address of input stringCR
; Output: CX = number of words
; Used:   AX DX
      PUSH  DI
      PUSH  SI
      MOV   AX, SI
      XOR   DX, DX            ; Word counter
aloop:
      CALL  getWord
      JCXZ  aexit
      SUB   BX, AX
      MOV   [DI+PosOffs], BL
      MOV   [DI+LenOffs], CL
      INC   DX
      ADD   DI, LenPosLen
      JMP   aloop
aexit:
      MOV   CX, DX
      POP   SI
      POP   DI
      RET
sc2WordLenPosArray ENDP
;
getWord PROC
; Input:  SI = current address of stringCR
; Output: BX = word address
;         CX = word length
;         SI = current address of stringCR
      PUSH  AX
      XOR   CX, CX            ; Word length
skipspace:
      LODSB
      CMP   AL, CR
      JE    wexit
      CMP   AL, "0"
      JL    skipspace
      CMP   AL, "9"
      JLE   itsword
      CMP   AL, "A"
      JL    skipspace
itsword:
      DEC   SI
      MOV   BX, SI
searchwordterm:
      LODSB
      CMP   AL, CR
      JE    wordfound
      CMP   AL, "0"
      JL    wordfound
      CMP   AL, "9"
      JLE   nextchar
      CMP   AL, "A"
      JL    wordfound
nextchar:
      INC   CX
      JMP   searchwordterm
wordfound:
      DEC   SI
wexit:
      POP   AX
      RET
getWord ENDP
;
sortDescWordArray PROC
; Input: SI = array address
;        CX = array length in words
; Used:  AX
      PUSH  CX
      PUSH  DI
      PUSH  SI
      MOV   DI, SI
sortloop:
      MOV   SI, DI
      ADD   SI, CX
      ADD   SI, CX            ; CX * LenPosLen
      MOV   AX, [DI]
cmploop:
      SUB   SI, LenPosLen
      CMP   [SI], AX
      JBE   nextword
      XCHG  [SI], AX
nextword:
      CMP   SI, DI
      JNZ   cmploop
      STOSW
      LOOP  sortloop
      POP   SI
      POP   DI
      POP   CX
      RET
sortDescWordArray ENDP
;
crLf PROC
; Used: AH DX
      LEA   DX, sdCrLf
      CALL showSd
      RET
crLf ENDP
;
showSd PROC
; Input: DX = string address
; Used:  AH
      MOV   AH, 9
      INT   21h
      RET
showSd ENDP
;
inputSc PROC
; Input:  DX = message address
;         SI = keyboard buffer address
;         CX = buffer length
; Output: CX = number of chars
;         SI = string address
; Used:   AX DX
      MOV   [SI], CL
      CALL  showSd
      MOV   DX, SI
      MOV   AH, 0Ah
      INT   21h
      XOR   CH, CH
      INC   SI
      MOV   CL, [SI]    ; String length
      INC   SI
      RET
inputSc ENDP
;
asWrdLenPos LABEL Word
kbBuf       EQU   asWrdLenPos + 2*MaxWordNum
chBufIn     EQU   kbBuf + 2
chBufOut    EQU   chBufIn + MaxKBufLen
;
_CODE ENDS
;
      END   START
;