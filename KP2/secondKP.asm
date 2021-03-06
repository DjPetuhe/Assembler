STSEG SEGMENT PARA STACK "STACK" 
    DB 64 DUP("STACK") 
STSEG ENDS 

DSEG SEGMENT PARA PUBLIC "DATA" 
    MSGSTRAT DB 'Enter 2-byte number: ','$' 
    MSGERROR DB 'Error!','$' 
    
    STRNUMBER LABEL BYTE 
    MAXLEN DB 7 
    NUMLEN DB 0 
    NUMFLD DB 7 DUP(0DH) 
    
    NUMBER DW 0 
    ERRORBOOL DB 0 
    NEGATIVE DB 0 
    LIMITCONST EQU 32768 
DSEG ENDS 

CSEG SEGMENT PARA PUBLIC "CODE" 
    
    ASSUME CS:CSEG, DS:DSEG, SS:STSEG 
    
    MAIN PROC FAR 
        PUSH DS 
        MOV AX, 0 
        PUSH AX 
        MOV AX, DSEG 
        MOV DS, AX 
        
        CALL PRINTINPUT 
        
        CALL TRANSLATENUMBER 
        CMP ERRORBOOL, 0 
        JG ERRORCLOSE 
        
        CALL DOTASK 
        CMP ERRORBOOL, 0 
        JG ERRORCLOSE 

        CALL PRINTRESULT 
        JMP CLOSE 
        ERRORCLOSE: 
            CALL PRINTERROR 
        CLOSE: 
            RET 
    MAIN ENDP 

    PRINTINPUT PROC NEAR 
        MOV AL, 0AH 
        INT 29H 

        MOV AH, 09H 
        LEA DX, MSGSTRAT 
        INT 21H 
        
        MOV AH, 0AH 
        LEA DX, STRNUMBER 
        INT 21H 
        
        RET 
    PRINTINPUT ENDP 
    
    TRANSLATENUMBER PROC NEAR 
        XOR AX, AX 
        MOV BX, 10 
        
        LEA SI, NUMFLD 
        CMP BYTE PTR [SI], "-" 
        JNE STARTLOOP 
        
        MOV NEGATIVE, 1 
        INC SI 
        STARTLOOP: 
            MOV CL, [SI] 
            CMP CL, 0DH 
            JE ENDLOOP 
            
            IMUL BX 
            JO TRANSLATEERROR 
            
            CMP CL, 30H 
            JB TRANSLATEERROR 
            CMP CL, 39H 
            JA TRANSLATEERROR 
            
            SUB CL, 30H 
            ADD AX, CX 
            JO CHECKEXCEPTION 
            
            INC SI 
            JMP STARTLOOP 
        
        CHECKEXCEPTION: 
          CMP AX, LIMITCONST 
          JNE TRANSLATEERROR 
          
          CMP NEGATIVE, 0 
          JE TRANSLATEERROR 
        
        ENDLOOP: 
          CMP NEGATIVE, 0 
          JE TRANSLATERETURN 
          
          NEG AX 
          JMP TRANSLATERETURN 
        
        TRANSLATEERROR: 
          MOV ERRORBOOL, 1 
        
        TRANSLATERETURN: 
          RET 
    TRANSLATENUMBER ENDP 
    
    DOTASK PROC NEAR 
        MOV NUMBER, AX 
        ADD NUMBER, 55 
        JO OVERFLOWERR 
        JMP ENDTASK 
        
        OVERFLOWERR: 
            MOV ERRORBOOL, 1 
        
        ENDTASK: 
            RET 
   DOTASK ENDP 
    
   PRINTRESULT PROC NEAR 
        MOV AL, 0AH 
        INT 29H 
        
        MOV BX, NUMBER 
        OR BX, BX 
        JNS M1 
        
        MOV AL, '-' 
        INT 29H 
        NEG BX 
        
        M1: 
          MOV AX, BX 
          XOR CX, CX 
          MOV BX, 10 
        
        M2: 
          XOR DX, DX 
          DIV BX 
          ADD DL, '0' 
          PUSH DX 
          INC CX 
          TEST AX, AX 
          JNZ M2 
        
        M3: 
          POP AX 
          INT 29H 
          LOOP M3 
        
        RET 
    PRINTRESULT ENDP 
    
    PRINTERROR PROC NEAR 
        MOV AL, 0AH 
        INT 29H 
        
        MOV AH, 09H 
        LEA DX, MSGERROR 
        INT 021H 
        
        RET 
    PRINTERROR ENDP 
    
CSEG ENDS 
END MAIN