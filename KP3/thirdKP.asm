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

    X DW 0 
    DEVIDEND DW 0 
    DEVISOR DW 0 
    RESULTINTEGERPART DW 0 
    RESULTFRACTIONALPART DW 0 
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
            JE FINISH 
            NEG AX 
            
        FINISH: 
            MOV X, AX 
            JMP TRANSLATERETURN 
            
        TRANSLATEERROR: 
            MOV ERRORBOOL, 1 
            
        TRANSLATERETURN: 
            RET 
    TRANSLATENUMBER ENDP 
    
    DOTASK PROC NEAR 
        CMP X, 15 
        JNE NOTEQUAL 

        CALL SECONDSITUATION 
        JMP ENDTASK 

        NOTEQUAL: 
            CMP X, 15 
            JG GREATER 
            
            CALL FIRSTSITUATION 
            JMP ENDTASK 
            
        GREATER: 
            CALL THIRDSITUATION 

        ENDTASK: 
            RET 
    DOTASK ENDP 
    
    FIRSTSITUATION PROC NEAR 
        SUB X, 3 
        JO OVERFLOWERFIRST 
        
        MOV AX, X 
        MOV RESULTINTEGERPART, AX 
        JMP ENDFIRST 
        
        OVERFLOWERFIRST: 
            MOV ERRORBOOL, 1 
            
        ENDFIRST: 
            RET 
    FIRSTSITUATION ENDP 
    
    SECONDSITUATION PROC NEAR 
        MOV AX, X 
        MOV DEVISOR, AX 
        SUB DEVISOR, 4 
        JO SECONDERROR 
        
        MOV CL, 2 
        SECONDPOWERLOOP: 
            CALL POWER 
            
            CMP ERRORBOOL, 0 
            JG SECONDEND 
            
            DEC CL 
            CMP CL, 0 
            JNE SECONDPOWERLOOP 
        
        MOV DX, 3 
        IMUL DX 
        JO SECONDERROR 
        
        ADD AX, 4 
        JO SECONDERROR 
        
        MOV DEVIDEND, AX 
        CALL DIVISION 
        JMP SECONDEND 
        
        SECONDERROR: 
            MOV ERRORBOOL, 1 
            
        SECONDEND: 
            RET 
   SECONDSITUATION ENDP 
    
    THIRDSITUATION PROC NEAR 
        MOV AX, 2 
        IMUL X 
        JO THIRDERROR 
        
        SUB AX, 5 
        JO THIRDERROR 
        
        MOV DEVISOR, AX 
        MOV AX, X 
        CALL POWER 
        CMP ERRORBOOL, 0 
        JG THIRDEND 
        
        MOV DX, 9 
        IMUL DX 
        JO THIRDERROR 
        
        SUB AX, 58 
        JO THIRDERROR 
        
        MOV DEVIDEND, AX 
        CALL DIVISION 
        JMP THIRDEND 
        
        THIRDERROR: 
            MOV ERRORBOOL, 1 

        THIRDEND: 
            RET 
    THIRDSITUATION ENDP 
    
    DIVISION PROC NEAR 
        MOV AX, DEVIDEND 
        IDIV DEVISOR 
        
        MOV RESULTINTEGERPART, AX 
        MOV BX, DX 
        
        MOV CL, 3 
        DIVISIONLOOP: 
            MOV AX, RESULTFRACTIONALPART 
            MOV DX, 10 
            MUL DX 
            JC CARRYDIVISION 
            
            MOV RESULTFRACTIONALPART, AX 
            MOV AX, BX 
            MUL DX 
            JC CARRYDIVISION 
            
            DIV DEVISOR 
            ADD RESULTFRACTIONALPART, AX 
            CMP DX, 0 
            JE DIVISIONEND 
            
            MOV BX, DX 
            DEC CL 
            CMP CL, 0 
            JG DIVISIONLOOP 

        MOV AX, BX 
        MOV DX, 10 
        MUL DX 
        JC CARRYDIVISION 
        
        DIV DEVISOR 
        CMP AX, 5 
        JL DIVISIONEND 
        
        ADD RESULTFRACTIONALPART, 1 
        JMP DIVISIONEND 
        
        CARRYDIVISION: 
            MOV ERRORBOOL, 1 
        DIVISIONEND: 
            RET 
    DIVISION ENDP 
    
    POWER PROC NEAR 
        IMUL X 
        JO OVERFLOWERPOWER 
        JMP ENDPOWER 

        OVERFLOWERPOWER: 
            MOV ERRORBOOL, 1 
        
        ENDPOWER: 
            RET 
    POWER ENDP 
    
    PRINTRESULT PROC NEAR 
        MOV AL, 0AH 
        INT 29H 
        
        MOV BX, RESULTINTEGERPART 
        OR BX, BX 
        JNS STARTPRINT 
        
        MOV AL, '-' 
        INT 29H 
        NEG BX 

        STARTPRINT: 
        CALL PRINTPART 
        
        MOV BX, RESULTFRACTIONALPART 
        MOV AL, '.' 
        INT 29H 
        
        CALL PRINTPART 
        RET 
    PRINTRESULT ENDP 
    
    PRINTPART PROC NEAR 
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
    PRINTPART ENDP 
    
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