.data
    archi: .asciz "archivo.txt"
    palabras: .space 00    // Espacio del buffer donde guarda las palabras leidas de archivo.txt
archivo_ranking: .asciz "ranking.txt"


    palabra_elegida:.space 6
    palabra_usuario:.space 6

    nombre_usuario: .space 31

    puntos:        .word 0


    input_nombre:       .ascii "		                                                            \n"       											       
			.ascii "		                                                            \n"										              
			.ascii "		                                                            \n" 											              
			.ascii "		                                                            \n"                                                          											               
			.ascii "	                                                                    \n"	                                                            											              
			.ascii "		��+    ��+  ������+  ������+   ������+    ��+     �������+  \n"
            		.ascii "		���    ���  ��+---��+ ��+--��+  ��+--��+ ���     ��+----+   \n"
            		.ascii " 		��� �+ ���  �     ��� ������++ ���  ��� ���     �����+      \n"
            		.ascii "		������+�  � ��   ��� ��+--��+ ���  ��� ���     ��+--+       \n"
           		.ascii "		+���+���++ +������++ ���  ��� ������+ +�������+�������+     \n"
            		.ascii " 		+--++--+  +-----+ +-+  +-++-----+ +------++------+          \n"
			.asciz "                  	    	Ingresa tu nombre: "

msg_bienvenida:     .asciz "\nBienvenido "

    msg_input1:     .asciz "\nIntentos: "
    msg_input2:     .asciz " - Ingresa una palabra de 5 letras: "

    msg_verde:      .asciz "\033[32m"
    msg_amarillo:   .asciz "\033[33m"
    msg_rojo:       .asciz "\033[31m"
    msg_reset:      .asciz "\033[0m"

    msg_perdiste1:  .asciz "\nPerdiste! La palabra era: "
    msg_ganaste1:   .asciz "\nFelicitaciones! Adivinaste la palabra: "
    msg_ranking1:   .asciz "\n=== RANKING ===\n"
    msg_ranking2:   .asciz "Jugador: "
    msg_ranking3:   .asciz "\nPuntaje: "
    msg_ranking4:   .asciz " puntos\n"
    nueva_linea:    .asciz "\n"
    
    msg_jugar:      .asciz "\n Quieres jugar otra partida? (S/N): "
    msg_partida:    .asciz "\n=== Partida #"
    msg_separador:  .asciz " ===\n"

    buffer_temp:    .space 4         // buffer aumentado a 4 bytes para alineacion
    char_buffer:    .space 4         // buffer para escribir_char
    leer_buffer:    .space 4         // buffer para leer caracteres

    buffer_ranking: .space 1024    // Buffer para leer el ranking
    msg_ultimos: .asciz "\n=== ultimos 3 jugadores ===\n"

// variables para el generador de numeros aleatorios
    seed:   .word 1
    const1: .word 1103515245
    const2: .word 12345
    numero: .word 0
    
    num_partida: .word 1

.text
.global main

/*------------------------------- 
Subrutina: guardar_ranking
---------------------------------
Guarda el nombre y puntaje actual
en el archivo ranking.txt 
posicionandose al final
---------------------------------
*/
guardar_ranking:
    .fnstart
        push {r4-r11, lr}
        
        // Abrir archivo en modo lectura/escritura
        mov r7, #5              // abre el archivo
        ldr r0, =archivo_ranking
        mov r1, #2              // modo lectura escritura
        mov r2, #0644          // Permisos del archivo 
        swi 0
        
        // Verificar si hubo error al abrir
        cmp r0, #0              //para saber si abrio o no
        blt crear_archivo      // Si es negativo, el archivo no existe
        mov r4, r0             // Guardar descriptor de archivo
        
        
        mov r7, #19            // muevo el puntero del archivo
        mov r0, r4             // Descriptor del archivo
        mov r1, #0             // desplazamiento de 0 bytes -> se movera lo segun defina r2
        mov r2, #2             // me muevo al final del archivo #2
        swi 0
        b escribir_ranking

    crear_archivo:
        // Crear el archivo si no existe
        mov r7, #5              // Syscall para abrir archivo
        ldr r0, =archivo_ranking
        mov r1, #0x42           // crear archivo
        mov r2, #0644          // Permisos del archivo
        swi 0
        mov r4, r0             // Guardar descriptor de archivo

    escribir_ranking:    
        // Escribir nombre (sin espacios al final)
        mov r7, #4              // escribir archivo
        mov r0, r4              // Descriptor del archivo
        ldr r1, =nombre_usuario
        mov r2, #0              // inicia contador para longitud en 0
        
        // Calcular longitud real del nombre (hasta encontrar 0 o espacio)
    contar_nombre:
        ldrb r3, [r1, r2]       //carga byte por byte el nombre
        cmp r3, #0
        beq fin_contar          //si encuentra 0 sale
        cmp r3, #32            // 32 es espacio en ASCII
        beq fin_contar          //si encuentra espacio, sale
        add r2, r2, #1
        b contar_nombre
        // r2 tiene la longitud real del nombre
        swi 0
        
    fin_contar:    
        
        // Escribir puntos inmediatamente despues del nombre
        ldr r5, =puntos
        ldr r5, [r5]            // Cargar puntos
        mov r0, r5              //los pasa por parametro a la funcion convertir_string
        bl convertir_string           // Convertir numero a string
        
        mov r7, #4              //escribir archivo
        mov r0, r4              //descriptor
        ldr r1, =buffer_temp   // Buffer donde esta el numero convertido
        mov r2, r0             // Longitud del numero retornada por convertir_string
        swi 0
        
        // Escribir salto de linea
        mov r7, #4              //escribir
        mov r0, r4              //descriptor
        ldr r1, =nueva_linea    //donde se guarda lo escrito =nueva_linea
        mov r2, #1              //longitud = 1byte
        swi 0
        
        // Cerrar archivo
        mov r7, #6              //cerrar archivo
        mov r0, r4              //descriptor
        swi 0
        
    fin_guardar:    
        pop {r4-r11, lr}
        bx lr
    .fnend

/*------------------------------- 
Subrutina: leer_ultimos
---------------------------------
Lee y muestra los ultimos 3
registros del ranking
---------------------------------
*/
leer_ultimos:
    .fnstart
        push {r4-r11, lr}
        
        // Abrir archivo para lectura
        mov r7, #5              // Syscall para abrir archivo
        ldr r0, =archivo_ranking
        mov r1, #0             // Modo lectura
        swi 0
        
        mov r4, r0             // Guardar descriptor
        
        // Leer todo el contenido
        mov r7, #3              // Syscall para leer
        mov r0, r4
        ldr r1, =buffer_ranking
        mov r2, #1024          // Tamano maximo a leer
        swi 0
        
        // Cerrar archivo
        mov r7, #6
        mov r0, r4
        swi 0
        
        // Mostrar mensaje de ultimos jugadores
        ldr r0, =msg_ultimos
        bl print_palabra
        
        // Procesar y mostrar ultimas 3 lineas
        ldr r4, =buffer_ranking
        mov r5, #0              // Contador de lineas
        mov r6, #0              // Posicion actual en buffer
        
    contar_lineas:
        ldrb r0, [r4, r6]
        cmp r0, #0              // Fin del archivo
        beq mostrar_ultimos
        cmp r0, #10             // Nueva linea
        addeq r5, r5, #1
        add r6, r6, #1
        b contar_lineas
        
    mostrar_ultimos:
        sub r6, r6, #1          // Retroceder al ultimo caracter
        mov r7, #0              // Contador de lineas mostradas
        
    buscar_lineas:
        cmp r7, #3              // Ya mostramos 3 lineas?
        beq fin_mostrar
        cmp r6, #0              // Llegamos al inicio?
        ble fin_mostrar
        
        ldrb r0, [r4, r6]
        cmp r0, #10             // Nueva linea?
        addeq r7, r7, #1
        sub r6, r6, #1
        b buscar_lineas
        
    fin_mostrar:
        add r6, r6, #2          // Ajustar posicion
        ldr r0, =buffer_ranking
        add r0, r0, r6          // Posicion desde donde mostrar
        bl print_palabra
        
        pop {r4-r11, lr}
        bx lr
    .fnend

/*------------------------------- 
Subrutina: convertir_string
---------------------------------
Convierte un numero entero a string
Input: r0 = numero
Output: r0 = longitud del string
---------------------------------
*/
convertir_string:
    .fnstart
        push {r4-r11, lr}
        
        mov r4, r0              // r4= numero a convertir; Guardar numero original
        ldr r5, =buffer_temp    //r5 = direccion buffer temporal
        mov r6, #0              // r6 = Contador de digitos
        mov r7, #10             //r7 =  Divisor (10 para obtener digitos decimales 1-9)
        
        // Manejar caso especial del 0
        cmp r4, #0
        bne convertir_numero
        mov r0, #'0'            //si es 0, se carga el caracter #0 en ASCII
        strb r0, [r5]           //se guarda '0' en el buffer
        mov r0, #1              //longitud a guardar = 1
        pop {r4-r11, lr}
        bx lr
        
    convertir_numero:
        cmp r4, #0              //para ver si es 0
        beq fin_conversion
        
        // Dividir por 10
        udiv r8, r4, r7         // r8 = numero / 10 -> cociente
        mul r9, r8, r7          // r9 = cociente * 10
        sub r9, r4, r9          // r9 = numero - (cociente * 10) -> resto
        
        // Convertir digito a ASCII
        add r9, r9, #'0'        //lo convierto a ASCII sumandole un '0'
        strb r9, [r5, r6]       //guardo el caracter en buffer
        add r6, r6, #1          //incremento el contador
        
        mov r4, r8              // cambio al siguiente numero de la iteracion
        b convertir_numero
        
    fin_conversion:
        // Invertir string
        mov r8, #0              // indice Inicio
        sub r9, r6, #1          // indice Final (longitud - 1)
        
    invertir_loop:
        cmp r8, r9              //comparo y si es r8 > r9 voy al final
        bge fin_convertir_string
        
        ldrb r10, [r5, r8]      //cargo el primer caracter
        ldrb r11, [r5, r9]      // cargo el ultimo caracter
        strb r11, [r5, r8]      //guardo el primero
        strb r10, [r5, r9]      //guardo el ultimo
        
        add r8, r8, #1          //incremento el indice inicio
        sub r9, r9, #1          //decremento el indice final
        b invertir_loop
        
    fin_convertir_string:
        mov r0, r6              // Retornar longitud del string
        pop {r4-r11, lr}
        bx lr
    .fnend




/*------------------------------- 
Subrutina: leer_palabras
---------------------------------
Esta subrutina abre el archivo.txt
lee su contenido y lo guarda
en un espacio de memoria
---------------------------------
*/

leer_palabras:
    .fnstart
        // Guardar registros que usaremos
        push {r4-r6, lr}

        // Abrir archivo para lectura
        mov r7, #5              // Syscall para abrir archivo
        ldr r0, =archi         // Nombre del archivo
        mov r1, #0             // Modo lectura (0)
        mov r2, #0
        swi 0

        // Guardar descriptor de archivo
        mov r6, r0

        // Leer contenido del archivo
        mov r7, #3              // Syscall para leer
        mov r0, r6              // Descriptor del archivo
        ldr r1, =palabras         // Buffer donde guardar contenido
        mov r2, #100            // Cantidad máxima a leer
        swi 0

        // Guardar cantidad de bytes leídos
        mov r5, r0

        // Cerrar archivo
        mov r7, #6              // Syscall para cerrar
        mov r0, r6              // Descriptor del archivo
        swi 0

        // Restaurar registros y retornar
        pop {r4-r6, lr}
        bx lr
    .fnend



/*------------------------------- 
Subrutina: calcular_puntos
---------------------------------
Esta subrutina se utiliza para
calcular el puntaje, multiplicando
intentos restantes x letras 
de la palabra
---------------------------------
*/

calcular_puntos:
    .fnstart
        push {r4-r11, lr}
        mov r4, r0          // guardar numero de intentos en r4
        mov r1, #5          // r1 = 5 (letras de la palabra)
        mul r0, r1, r4      // r0 = r1 * r4 (letras x intentos)
        pop {r4-r11, lr}
        bx lr
    .fnend

/*------------------------------- 
Subrutina: pedir_nombre
---------------------------------
Esta subrutina se utiliza para
obtener el nombre del jugador
e imprimirlo dentro de los mensajes
del juego
---------------------------------
*/

pedir_nombre:
    .fnstart
        push {r4-r11, lr}
        ldr r0, =input_nombre
        bl print_palabra
        ldr r0, =nombre_usuario
        bl leer_palabra
        ldr r0, =msg_bienvenida
        bl print_palabra
        ldr r0, =nombre_usuario
        bl print_palabra
        ldr r0, =nueva_linea
        bl print_palabra
        pop {r4-r11, lr}
        bx lr
    .fnend

/*------------------------------- 
Subrutina: leer_palabra
---------------------------------
Esta subrutina se utiliza para
leer texto caracter por caracter
y detenerse cuando encuentra
enter (13) o nueva linea (10)
---------------------------------
*/

leer_palabra:
    .fnstart
        push {r4-r11, lr}
        mov r4, r0
        mov r5, #0
        
    leer_caracter:
        bl obtener_char
        cmp r0, #13
        beq fin_lectura
        cmp r0, #10
        beq fin_lectura
        strb r0, [r4, r5]
        add r5, r5, #1
        b leer_caracter
        
    fin_lectura:
        mov r0, #0
        strb r0, [r4, r5]
        mov r0, r5
        pop {r4-r11, lr}
        bx lr
    .fnend

/*------------------------------- 
Subrutina: obtener_char
---------------------------------
Esta subrutina se utiliza para
leer de teclado caracter x caracter 
lo ingresado por el usuario
---------------------------------
*/

obtener_char:
    .fnstart
        push {r4-r11, lr}
        mov r0, #0  //ingreso de cadena
        ldr r1, =buffer_temp    //donde guardo lo ingresado por usuario
        mov r2, #1  //cantidad de caracteres (1 char)
        mov r7, #3  //lectura de teclado
        swi 0
        cmp r0, #0
        beq fin_obtenerChar
        ldr r1, =buffer_temp
        ldrb r0, [r1]
    fin_obtenerChar:
        pop {r4-r11, lr}
        bx lr
    .fnend

/*------------------------------- 
Subrutina: mostrar_ranking
---------------------------------
Esta subrutina se utiliza para
mostrar la informacion del 
jugador de la partida y la 
puntuacion obtenida
---------------------------------
*/

mostrar_ranking:
    .fnstart
        push {r4-r11, lr}
        ldr r0, =msg_ranking1
        bl print_palabra
        ldr r0, =msg_ranking2
        bl print_palabra
        ldr r0, =nombre_usuario
        bl print_palabra
        ldr r0, =msg_ranking3
        bl print_palabra
        ldr r0, =puntos
        ldr r0, [r0]
        bl print_numero
        ldr r0, =msg_ranking4
        bl print_palabra
        pop {r4-r11, lr}
        bx lr
    .fnend

/*------------------------------- 
Subrutina: print_palabra
---------------------------------
Esta subrutina se utiliza para
imprimir la cadena de texto
caracter por caracter hasta encontrar
0
---------------------------------
*/

print_palabra:
    .fnstart
        push {r4-r11, lr}
        mov r4, r0
    print_loop:
        ldrb r0, [r4], #1
        cmp r0, #0
        beq print_fin
        bl escribir_char
        b print_loop

    print_fin:
        pop {r4-r11, lr}
        bx lr
    .fnend

/*------------------------------- 
Subrutina: print_numero
---------------------------------
Esta subrutina se utiliza para
convertir un numero en su 
representacion de caracteres ASCII
y lo imprime
---------------------------------
*/

print_numero:
    .fnstart
        push {r4-r11, lr}
        mov r4, r0
        mov r5, #0
        mov r6, #10

        cmp r4, #0
        bne convertir_loop
        mov r0, #'0'
        bl escribir_char
        b fin_print_numero

    convertir_loop:
        cmp r4, #0                          // compara si el numero (en r4) es 0
        beq print_digitos                   // si es 0, termina la conversion y va a imprimir
        mov r0, r4                          // mueve el numero a r0
        mov r1, r6                          // r6 contiene 10 (el divisor)
        bl division                         // divide el numero por 10
        mov r4, r0                          // r4 = cociente (para la siguiente iteracion)
        mov r0, r2                          // r2 contiene el resto de la division
        add r0, r0, #'0'                    // convierte el digito a ASCII sumando '0'
        ldr r1, =leer_buffer                // carga la direccion del buffer
        str r0, [r1, r5, lsl #2]            
        add r5, r5, #1                      // incrementa el contador de digitos
        b convertir_loop                    // continua con el siguiente digito

    print_digitos:
        cmp r5, #0
        beq fin_print_numero
        sub r5, r5, #1
        ldr r1, =leer_buffer
        ldr r0, [r1, r5, lsl #2]  
        bl escribir_char
        b print_digitos

    fin_print_numero:
        pop {r4-r11, lr}
        bx lr
    .fnend

/*------------------------------- 
Subrutina: division
---------------------------------
Esta subrutina se utiliza para
obtener la division entera y el 
resto
---------------------------------
*/

division:
    .fnstart
        push {r4-r11, lr}
        mov r2, r0
        udiv r0, r0, r1 //cociente de division entera
        mov r3, r0
        mul r1, r3, r1
        sub r2, r2, r1  //resto de la division
        pop {r4-r11, lr}
        bx lr
    .fnend

/*------------------------------- 
Subrutina: escribir_char
---------------------------------
Esta subrutina se utiliza para
escribir los caracteres 
---------------------------------
*/

escribir_char:
    .fnstart
        push {r1-r7, lr}
        mov r2, #1  //tamaño de la cadena (1 char)
        ldr r1, =char_buffer 
        strb r0, [r1]   //almacena de forma temporal el caracter en el buffer
        mov r0, #1  //salida de la cadena
        mov r7, #4  //salida por pantalla
        swi 0
        pop {r1-r7, lr}
        bx lr
    .fnend

/*------------------------------- 
Subrutina: myrand y mysrand
---------------------------------
Esta subrutina se utiliza para
implementar el uso de numeros
aleatorios
---------------------------------
*/

myrand:
    .fnstart
        push {r4-r11, lr}
        ldr r1, =seed                 // leo puntero a semilla   
        ldr r0, [r1]                   // leo valor de semilla   
        ldr r2, =const1
        ldr r2, [r2]                   // leo const1 en r2   
        mov r4, r0                 // guardo seed en r4   
        mul r0, r4, r2                 // r0 = seed * 1103515245   
        ldr r3, =const2
        ldr r3, [r3]                   // leo const2 en r3   
        add r0, r0, r3                 // r0 = r0 + 12345   
        str r0, [r1]                   // guardo en variable seed   
        LSL r0, #1
        LSR r0, #17
        pop {r4-r11, lr}
        bx lr
    .fnend

mysrand:
    .fnstart
        push {r4-r11, lr}
        ldr r1, =seed
        str r0, [r1]
        pop {r4-r11, lr}
        bx lr
    .fnend


/*------------------------------- 
Subrutina: num_random
---------------------------------
Genera un numero aleatorio entre
0 y 9
---------------------------------
*/

random_number:
    .fnstart
        push {r4-r11, lr}
        bl myrand              // obtener numero aleatorio
        mov r4, r0             // guardar resultado en r4
        mov r1, #10           // cargo 10 para usarlo de Divisor y obtener numero entre 0 y 9
        mov r0, r4            // recuperar numero aleatorio -> lo paso como parametro en la funcion modulo
        bl modulo              // llamar a modulo para obtener el resto de la division por 10
        pop {r4-r11, lr}
        bx lr
    .fnend


/*------------------------------- 
Subrutina: modulo
---------------------------------
calcula el resto de la division
y asegurar que el numero aleatorio
este entre 0 y 9

basado en 
resto = dividendo - (divisor * (dividendo / divisor))
---------------------------------
*/

modulo:
    .fnstart
        push {r4-r11, lr}
        mov r4, r0            // guardo en r4 el dividendo (osea el numero original)
        udiv r2, r0, r1       // hago r2 = r0 / r1 (division entera sin decimales)
        mul r2, r1, r2        // r2 = r1 * r2 -> multiplico el resultado por el divisor
        sub r0, r4, r2        // r0 = r4 - r2 -> resto = diferencia entre original y la multiplicacion
        pop {r4-r11, lr}
        bx lr
    .fnend

main:
    push {r4-r11, lr}
    bl leer_palabras        // Llamar a la subrutina
    // Mostrar numero de partida
    bl pedir_nombre

loop_juego:
    // Mostrar n�mero de partida
    ldr r0, =msg_partida
    bl print_palabra            //imprime mensaje de partida 
    ldr r0, =num_partida           
    ldr r0, [r0]               //traigo el nro de partida actual
    bl print_numero            //imprimo el nro de partida
    ldr r0, =msg_separador     //imprimo el final del mensaje partida    
    bl print_palabra

    @ Incrementar seed basado en numero de partida
    ldr r0, =num_partida
    ldr r0, [r0]        //traigo el nro de partida actual
    mov r1, #42         //base seed
    mul r0, r1, r0      //seed = base_seed * num_partida
    bl mysrand
    
    bl random_number    //llamo a random para generar el numero entre 0 y 9
    mov r4, r0          // r4 = numero aleatorio entre
    mov r5, #5          // r5 = 5 (cantidad de letras)  
    mul r0, r5, r4      // r0 = r5 * r4 -> multiplico el nro aleatorio * 5 para moverme de 5 en 5 (de palabra en palabra)  
    mov r4, r0          // guardar resultado en r4   
    
    // Copiar palabra elegida
    ldr r0, =palabras       //r0 = direccion de las palabras del juego
    add r0, r0, r4          //en la direccion me muevo la cantidad de lugares de r4 (para moverme a una palabra random)
    ldr r1, =palabra_elegida//r1 = direccion donde guardare la palabra elegida
    mov r2, #5

copiar_palabra:
    //r0 = dir de memoria, palabras del juego
    //r1 = dir de memoria, donde guarda palabra elegida
    //r2 = 5 - 1 ... hasta llegar a 0 para saber cuando llego al final de la palabra
    //r3 = registro donde cargo / guardo lo apuntado en r0/r1 respectivamente
    ldrb r3, [r0], #1
    strb r3, [r1], #1
    subs r2, r2, #1     //para restar y comparar con 0 (prende flag Z) en la misma instruccion
    bne copiar_palabra
    mov r3, #0
    strb r3, [r1]       //cargo 0 al final de la palabra elegida

    mov r10, #6         // Contador de intentos

input_loop:
    cmp r10, #0         //comparo si el contador llego a 0 para ir al final del juego
    beq perdedor
    ldr r0, =msg_input1
    bl print_palabra
    mov r0, r10         //paso el numero de intentos como parametro para imprimirlo en el mensaje
    bl print_numero
    ldr r0, =msg_input2
    bl print_palabra
    ldr r0, =palabra_usuario
    bl leer_palabra     //leo lo ingresado por el usuario en el juego
    
    mov r4, #0

informar_resultado:
    //r4 -> posicion
    //r5 -> palabra elegida
    //r6 -> palabra usuario
    cmp r4, #5        //POSICION: comparo r4 con 5 para saber si estoy en el final
    beq fin_informar_resultado
    ldr r0, =palabra_elegida
    ldrb r5, [r0, r4]//carga la letra en r5 de la palabra elegida, en la posicion r4
    ldr r0, =palabra_usuario
    ldrb r6, [r0, r4]//carga la letra en r6 de la palabra del usuario, en la posicion r4
    cmp r5, r6       //comparo las letras si son iguales, voy a letra VERDE.
    beq letra_verde //si son todas iguales, son todas verdes.
    mov r7, #0

buscar_letra:
    //r7 -> posicion
    //r8 -> cargo las letras para comparar los amarillos
    cmp r7, #5      //POSICION: comparo r7 con 5 para saber si estoy en el final
    beq letra_roja  //Si llegue al final, todas son rojas.
    ldr r0, =palabra_elegida
    ldrb r8, [r0, r7]//carga en r8 la letra de palabra elegida, en posicion de r7
    cmp r6, r8      //comparo con las letras de la palabra del usuario para ver si esta
    beq letra_amarilla
    add r7, r7, #1  //me muevo a la siguiente hasta llegar a 5
    b buscar_letra

letra_verde:
    ldr r0, =msg_verde
    bl print_palabra     //paso por parametro r0 la dir del color ANSI en verde para imprimir con color
    ldr r0, =palabra_usuario
    ldrb r0, [r0, r4]//r0: cargo la letra en la posicion de r4
    bl escribir_char   //imprimo la letra
    b siguiente_letra

letra_amarilla:
    ldr r0, =msg_amarillo
    bl print_palabra     //paso por parametro el color ANSI amarillo y lo imprimo
    ldr r0, =palabra_usuario
    ldrb r0, [r0, r4]
    bl escribir_char
    b siguiente_letra

letra_roja:
    ldr r0, =msg_rojo
    bl print_palabra
    ldr r0, =palabra_usuario
    ldrb r0, [r0, r4]
    bl escribir_char

siguiente_letra:
    ldr r0, =msg_reset
    bl print_palabra //reseteo el color al neutro
    add r4, r4, #1  //me muevo 1 posicion y vuelvo al bucle
    b informar_resultado

fin_informar_resultado:
    ldr r0, =nueva_linea
    bl print_palabra //agrego una linea en blanco
    mov r4, #0      //regreso a la posicion inicial
    mov r9, #1      //flag para saber si es ganador (por ahora asumo que si)

palabra_correcta:
    //r4 = posicion
    //r5 = letra palabra elegida
    //r6 = letra palabra usuario
    cmp r4, #5      //para ver si llegue al final de la palabra e ir al fin del juego
    beq juego_terminado
    ldr r0, =palabra_elegida
    ldrb r5, [r0, r4]
    ldr r0, =palabra_usuario
    ldrb r6, [r0, r4]
    cmp r5, r6  //comparo las letras
    addeq r4, r4, #1    //si son iguales me muevo de posicion
    movne r9, #0    //si no son iguales, r9 = 0 (no gano)
    bne juego_terminado    //r5 y r6 no iguales, se va al final del juego
    b palabra_correcta

juego_terminado:
    cmp r9, #1          //flag r9, si es 1 gano
    beq ganador
    sub r10, r10, #1    //si no gano, quito 1 intento y vuelvo al bucle para agregar palabra usuario
    b input_loop

perdedor:
    ldr r0, =msg_perdiste1
    bl print_palabra//imprimo mensaje perdiste
    ldr r0, =palabra_elegida
    bl print_palabra//imprimo la palabra elegida
    ldr r0, =nueva_linea
    bl print_palabra//imprimo linea en blanco
    mov r0, #0//para dejar r0 limpio
    ldr r1, =puntos
    str r0, [r1]//traigo los puntos de memoria
    bl mostrar_ranking//imprime ranking
    b continuar_juegando //pregunto para reiniciar el juego


ganador:
    ldr r0, =msg_ganaste1
    bl print_palabra//mensaje gano
    ldr r0, =palabra_elegida
    bl print_palabra//palabra elegida
    ldr r0, =nueva_linea
    bl print_palabra//linea en blanco
    mov r0, r10//paso por parametro r0 la cantidad de vidas que tenia en r10
    bl calcular_puntos
    ldr r1, =puntos
    str r0, [r1]//guardo puntos en memoria
    bl mostrar_ranking
    bl guardar_ranking    // Agregar esta l�nea
    bl leer_ultimos      // Agregar esta l�nea

continuar_juegando:
    // Preguntar si quiere jugar otra partida
    ldr r0, =msg_jugar
    bl print_palabra//jugar de nuevo?
    bl obtener_char//reviso que coloco el usuario (S / N) y lo devuelvo en r0
    
    // Comparar con 'S' o 's'
    cmp r0, #'S'
    beq continuar_juego
    cmp r0, #'s'
    beq continuar_juego
    b fin_juego

continuar_juego:
    // Incrementar numero de partida
    ldr r0, =num_partida
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]
    
    //Limpiar buffer
    bl obtener_char  // Limpiar el newline
    b loop_juego

fin_juego:
    mov r0, #0 //limpio r0
    pop {r4-r11, lr}
    mov r7, #1
    swi 0
