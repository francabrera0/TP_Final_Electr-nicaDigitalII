;*******************************************************************************
;                                                                              *
;    Filename: TRABAJOFINAL                                                    *
;    Date: 07/05/2022                                                          *
;    File Version: 2.0.0                                                       *
;    Author: Francisco Cabrera                                                 *
;    Company: FCEFyN                                                           *
;    Description: Decodificación de teclado y muestra de valores por display y *                                                   *
;                 comunicacion serie                                           *
;*******************************************************************************
	
	LIST	    P=16F887
	#include    <p16f887.inc>
	
    __CONFIG    _CONFIG1, _INTOSCIO & _WDT_OFF & _PWRTE_ON & _MCLRE_ON & _BOR_OFF & _LVP_OFF
	
AUXC	EQU	0X20     ;Registro auxiliar para multiplexar los displays
AUXD	EQU	0X21	 ;Registro para decodificación de teclado
REG3	EQU	0X22	 ;Registro para guardar el valor que se muestra por el display 3
REG2	EQU	0X23	 ;Registro para guardar el valor que se muestra por el display 2
REG1	EQU	0X24	 ;Registro para guardar el valor que se muestra por el display 1
REG0	EQU	0X25	 ;Registro para guardar el valor que se muestra por el display 0
DATO	EQU	0X26	 ;Registro para almacenar el dato ingresado por el teclado
WTEMP	EQU	0X27	 ;Registro para guardar W cuando entra a la ISR
STEMP	EQU	0X28	 ;Registro para guardar STATUS cuando entra a la ISR
RTEMP	EQU	0X29	 ;Registro para almacenar temporalmente el valor a mostrar en el display
DEB0	EQU	0X2A     ;Registro auxiliar para realizar el DEBOUNCE	
DEB1	EQU	0X2B	 ;Registro auxiliar para realizar el DEBOUNCE
REG3A	EQU	0X2C	 ;Registro para enviar datos por TX
REG2A	EQU	0X2D	 ;Registro para enviar datos por TX
REG1A	EQU	0X2E	 ;Registro para enviar datos por TX
REG0A	EQU	0X2F	 ;Registro para enviar datos por TX
DATOA	EQU	0X30	 ;Registro auxiliar para actualizar registros REGxA

	ORG	    0X00
	GOTO	    MAIN	; Va a la rutina principal 
	
	ORG	    0X04

	MOVWF	    WTEMP	; -----------------------------------------------------------------
	SWAPF	    STATUS,W	; Guarda el contexto del procesador
	MOVWF	    STEMP	; -----------------------------------------------------------------
	
	BANKSEL	    INTCON	; -----------------------------------------------------------------
	BTFSC	    INTCON,INTF	; Va a la subrutina de interrupción INTO en caso de tratarse de INT 
	GOTO	    INTO	; Esta se encarga de pasar los datos por TX y reiniciar los registros
				; -----------------------------------------------------------------
	
	BANKSEL	    STATUS	; -----------------------------------------------------------------
	BCF	    STATUS,C	; Si no es por INT, es por TMR0, por lo cual ilumina el siguiente display
	BTFSC	    AUXC,7	;
	BSF	    STATUS,C	; 
	RLF	    AUXC,1	; Primero rota el puntero del Display
	MOVF	    AUXC,W	; 
	MOVWF	    PORTC	; 
				;
	BTFSC	    AUXC,0	; Chequea cuál de todos los registros debe enseñar dependiendo del segmento
	GOTO	    SAVE3	; que se deba mostrar.
	BTFSC	    AUXC,1	;
	GOTO	    SAVE2	;
	BTFSC	    AUXC,2	;
	GOTO	    SAVE1	;
	GOTO	    SAVE0	;
SAVE3	MOVF	    REG3,W	;
	GOTO	    NEXT2	;
SAVE2	MOVF	    REG2,W	;
	GOTO	    NEXT2	;
SAVE1	MOVF	    REG1,W	;
	GOTO	    NEXT2	;
SAVE0	MOVF	    REG0,W	;
NEXT2	MOVWF	    RTEMP	;  Finalmente, cuando tiene el registro primero
	MOVLW	    0X00	;  apaga el puerto C para no señalar a ninguno
	MOVWF	    PORTC	;  
	MOVF	    RTEMP,W	;  
	MOVWF	    PORTA	;  Modifica el puerto A para mostrar el nuevo dato
	MOVF	    AUXC,W	;
	MOVWF	    PORTC	;  Vuelve a encender el display ya modificado
	
	BANKSEL	    INTCON	; -----------------------------------------------------------------
	BCF	    INTCON,2	;
	BANKSEL	    TMR0	; Reinicia el timer0 y baja el flag
	MOVLW	    .100	;
	MOVWF	    TMR0	; -----------------------------------------------------------------
	SWAPF	    STEMP,W	;
	MOVWF	    STATUS	; Recupera el contexto y acaba la interrupción
	SWAPF	    WTEMP,1	;  
	SWAPF	    WTEMP,W	;
	RETFIE			; -----------------------------------------------------------------
	
INTO				; -----------------------------------------------------------------
	BCF	    PIR1,TXIF	;
	BANKSEL	    TXREG	; Transmite los datos por TX
	MOVF	    REG3A,W	;
	MOVWF	    TXREG	;
	BANKSEL	    TXSTA	;
	BTFSS	    TXSTA,TRMT	;
	GOTO	    $-1		;
	BANKSEL	    TXREG	;
	MOVF	    REG2A,W	;
	MOVWF	    TXREG	;
	BANKSEL	    TXSTA	;
	BTFSS	    TXSTA,TRMT	;
	GOTO	    $-1		;
	BANKSEL	    TXREG	;
	MOVF	    REG1A,W	;
	MOVWF	    TXREG	;
	BANKSEL	    TXSTA	;
	BTFSS	    TXSTA,TRMT	;
	GOTO	    $-1		;
	BANKSEL	    TXREG	;
	MOVF	    REG0A,W	;
	MOVWF	    TXREG	;
	BANKSEL	    TXSTA	;
	BTFSS	    TXSTA,TRMT	;
	GOTO	    $-1		;

	BANKSEL	    REG0	; -----------------------------------------------------------------
	MOVLW	    0X3F	;
	MOVWF	    REG0	; Limpia todos los registros poniendolos en 0 y también reinicia
	MOVWF	    REG1	; los registros temporales a enviar
	MOVWF	    REG2	;
	MOVWF	    REG3	;
	CLRF	    REG0A	;
	CLRF	    REG1A	;
	CLRF	    REG2A	;
	CLRF	    REG3A	; -----------------------------------------------------------------
	
	BANKSEL	    INTCON	; -----------------------------------------------------------------
	BCF	    INTCON,INTF ;
	BANKSEL	    STATUS	;
	SWAPF	    STEMP,W	; Recupera contexto y baja el flag de INT
	MOVWF	    STATUS	;
	SWAPF	    WTEMP,1	;
	SWAPF	    WTEMP,W	;
	RETFIE			; -----------------------------------------------------------------

	
MAIN
	BANKSEL	    ANSEL	; -----------------------------------------------------------------
	CLRF	    ANSEL	; Primero limpio el ANSEL ya que no se utilizarán puertos analógicos
	CLRF	    ANSELH	; -----------------------------------------------------------------
	
	BANKSEL	    TRISA	; -----------------------------------------------------------------
	MOVLW	    0X01	; Seteo los puertos:
	MOVWF	    TRISB	; B para el interrupt en RB0
	CLRF	    TRISA	; A para los 8 bits del output
	CLRF	    TRISC	; C para seleccionar el display de 7 seg a iluminar
	MOVLW	    0XF0	; D para tener el teclado (como es por polling no hace falta el B)   
	MOVWF	    TRISD	; -----------------------------------------------------------------
	
	BANKSEL	    TXSTA	; -----------------------------------------------------------------    
	MOVLW	    0X24	; 
	MOVWF	    TXSTA	; Seteo TXSTA con 0010 0100 -> modo asíncrono, sin 9no bit, con high speed (BRHS)
	BANKSEL	    RCSTA	; 
	MOVLW	    0X80	; 
	MOVWF	    RCSTA	; Seteo RCSTA con 1000 0000 -> Solo enciendo el puerto serial (no hay recepción)
	BANKSEL	    BAUDCTL	; 
	BCF	    BAUDCTL,BRG16;Seteo BRG16 con 0
	BANKSEL	    SPBRG	; A partir de la tabla 12-5 de la página 162, si quiero transmitir a 9600 baudios, con la configuración 
	MOVLW	    .25		; de Sync = 0, BRGH = 1 y BRG16 = 0, tendré un error rate de 0.16% y deberé configurar el SPBRG con 25
	MOVWF	    SPBRG	; -----------------------------------------------------------------    
				
	BANKSEL	    OPTION_REG  ; -----------------------------------------------------------------    
	MOVLW	    0X84	; 
	MOVWF	    OPTION_REG  ; Seteo sin WPUB, y preescaler en 1:32 para TMR0 
	BANKSEL	    PIE1	; 
	BSF	    PIE1,TXIE	; Seteo interrupción por TX
	BANKSEL	    INTCON	;
	MOVLW	    0XB0	; Seteo interrupción por TMR0 y INT (RB0)
	MOVWF	    INTCON	; -----------------------------------------------------------------    
	
	BANKSEL	    TMR0	; Inicio TMR0 en 100. Porque (256 - 100) * 32 * 1us = 5ms (serían los 20ms dividido 4 displays)
	MOVLW	    .100	
	MOVWF	    TMR0  
	MOVLW	    0X11	
	MOVWF	    AUXC	; Enciendo el primer bit del display
	MOVWF	    PORTC	;
	MOVLW	    0X3F	; -----------------------------------------------------------------    
	MOVWF	    REG0	;
	MOVWF	    REG1	; Comienzo todos los registros y el puerto A en 0 (con lógica positiva)
	MOVWF	    REG2	;
	MOVWF	    REG3	;
	MOVWF	    PORTA	; -----------------------------------------------------------------    
	CLRF	    REG3A	;
	CLRF	    REG2A	; Limpio los registros para el envío de datos
	CLRF	    REG1A	;
	CLRF	    REG0A	; -----------------------------------------------------------------    
	

NEXT	MOVLW	    0XEE	; -----------------------------------------------------------------       
	MOVWF	    AUXD	; Comienzo Polling en el puerto D. Coloco todos 1s menos uno y voy avanzando 
	CLRF	    DATO	; aumentando el dato a pasar. En caso de que haya una tecla apretada, llama a SAVE
KEYB	MOVF	    AUXD,W	;
	MOVWF	    PORTD	; 
	BTFSS	    PORTD,4	; Testeo puerto 4 (primera fila)
	GOTO	    SAVE	;
	INCF	    DATO,1	; 
	BTFSS	    PORTD,5	; Testeo puerto 5 
	GOTO	    SAVE	;
	INCF	    DATO,1	;
	BTFSS	    PORTD,6	; Testeo puerto 6
	GOTO	    SAVE	;
	INCF	    DATO,1	;
	BTFSS	    PORTD,7	; Testeo puerto 7 (última fila)
	GOTO	    SAVE	;
	INCF	    DATO,1	;
	
	BSF	    STATUS,C    ; Roto el registro a la izquierda, o sea la columna 
	BTFSS	    AUXD,7	; hacia la derecha (es izquierda en el código, 
	BCF	    STATUS,C	; pero depende de cómo se conecte el teclado) 
	RLF	    AUXD,1	;
	GOTO	    KEYB	; -----------------------------------------------------------------        
	
SAVE				; -----------------------------------------------------------------       
	CALL	    DEBOUNCE	; Primero hace el debounce para evitar doble toques
	MOVLW	    0X0F	; 
	ANDWF	    DATO,1	; Toma el nibble inferior como dato
	MOVF	    DATO,W	; 
	MOVWF	    DATOA	; Pone el dato en DATOA
	CALL	    DECOD	; Lo decodifica para saber qué corresponde en el display de 7seg
	MOVWF	    DATO	; Lo vuelve a poner
	CALL	    ORDER	; Avanza cada dato a la izquierda, poniendose DATO en el primer puesto
	CALL	    RKEY	; Espera a que se suelte la tecla y vuelve a empezar
	GOTO	    NEXT	; -----------------------------------------------------------------       

DEBOUNCE
	BANKSEL	    INTCON
	BCF	    INTCON,GIE
	BANKSEL	    DEB0
	MOVLW	    .255
	MOVWF	    DEB0
	MOVLW	    .12
	MOVWF	    DEB1
	
LOOP1	DECFSZ	    DEB1,1
	GOTO	    LOOP
	GOTO	    RET
LOOP	DECFSZ	    DEB0,1
	GOTO	    LOOP
	GOTO	    LOOP1
	
RET	
	BANKSEL	    INTCON
	BSF	    INTCON,GIE
	BANKSEL	    PORTD
	RETURN
	
DECOD
	MOVF	    DATO,W
	ADDWF	    PCL,1
	RETLW	    0X3F	; '00111111' -> 0 con lógica positiva
	RETLW	    0X06
	RETLW	    0X5B
	RETLW	    0X4F
	RETLW	    0X66
	RETLW	    0X6D
	RETLW	    0X7D
	RETLW	    0X07
	RETLW	    0X7F
	RETLW	    0X67
	RETLW	    0X5F
	RETLW	    0X7C
	RETLW	    0X39
	RETLW	    0X5E
	RETLW	    0X7B
	RETLW	    0X71
	
ORDER 
	MOVF	    REG2,W
	MOVWF	    REG3
	MOVF	    REG1,W
	MOVWF	    REG2
	MOVF	    REG0,W
	MOVWF	    REG1
	MOVF	    DATO,W
	MOVWF	    REG0
	MOVF	    REG2A,W
	MOVWF	    REG3A
	MOVF	    REG1A,W
	MOVWF	    REG2A
	MOVF	    REG0A,W
	MOVWF	    REG1A
	MOVF	    DATOA,W
	MOVWF	    REG0A
	
	RETURN	
	
RKEY 
	BANKSEL	    INTCON
	BCF	    INTCON,GIE
	BANKSEL	    PORTD
	MOVLW	    0X00
	MOVWF	    PORTC
CHECK	MOVLW	    0XF0
	ANDWF	    PORTD,W
	SUBLW	    0XF0
	BTFSS	    STATUS,Z
	GOTO	    CHECK
	MOVF	    AUXC,W
	MOVWF	    PORTC
	BANKSEL	    INTCON
	BSF	    INTCON,GIE
	BANKSEL	    PORTD
	RETURN	

	END