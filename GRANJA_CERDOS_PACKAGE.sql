CREATE OR REPLACE PACKAGE granja_cerdos IS

    --Definimos todos los tipos de arrays que vamos a usar en el package
    TYPE fila_camion IS TABLE OF camion%ROWTYPE;

    TYPE fila_cerdo IS TABLE OF cerdo%ROWTYPE;

    TYPE booleano IS TABLE OF BOOLEAN INDEX BY BINARY_INTEGER;
    TYPE matriz_booleana IS TABLE OF  booleano INDEX BY BINARY_INTEGER;

    FUNCTION matriz_falso_verdadero(
        cerdos IN fila_cerdo,
        peso_limite IN NUMBER
    )
    RETURN matriz_booleana;

    FUNCTION peso_cerdos(
        matriz IN matriz_booleana,
        cerdos IN fila_cerdo,
        peso_limite IN NUMBER
    )
    RETURN NUMBER;

    FUNCTION  elegir_cerdos(
        matriz IN matriz_booleana,
        cerdos IN fila_cerdo,
        peso_limite IN NUMBER
    )
    RETURN fila_cerdo;

END;

CREATE OR REPLACE PACKAGE BODY granja_cerdos IS

    FUNCTION matriz_falso_verdadero(
        cerdos IN fila_cerdo,
        peso_limite IN NUMBER
    )
    RETURN
        matriz_booleana
    IS
        matriz matriz_booleana;
        kilos_actuales cerdo.pesokilos%TYPE;
    BEGIN
        --Generamos la matriz de falsos y verdaderos
        --Siempre iniciamos desde la fila 0 hasta el último cerdito
        FOR fila IN 0 .. cerdos.LAST LOOP

            --Las columnas también empiezan en 0 hasta el máximo peso que se pueda aceptar
            FOR columna IN 0 .. peso_limite LOOP

                --kilos_actuales representa los kilos del cerdito que estamos analizando en el momento para crear la matriz
                --Si nos encontramos en la fila 0, significa que no estamos tomando ningún cerdito, por lo que se le asigna 0
                kilos_actuales := 0;
                IF fila <> 0 THEN
                    kilos_actuales := cerdos(fila).PESOKILOS;
                end if;

                IF columna = 0 THEN
                    --Toda la columna 0 debe ser True
                    matriz(fila)(columna) := TRUE;

                ELSIF fila = 0 THEN
                    --Toda la fila 0 debe ser False, excepto la posición (0)(0)
                    matriz(fila)(columna) := FALSE;

                ELSIF kilos_actuales > columna THEN
                    /*Si los kilos del cerdito actual es menor al número de columna, solo tomamos el valor que se
                      encuentra en la misma columna pero una fila antes*/
                    matriz(fila)(columna) := matriz(fila-1)(columna);

                ELSE
                    /*En cualquier otro caso hacemos un OR entre el valor de la misma columna y fila anterior,
                      o entre la columna actual menos el peso del cerdito, y la fila anterior*/
                    matriz(fila)(columna) := matriz(fila-1)(columna) OR matriz(fila-1)(columna-kilos_actuales);
                end if;

            end loop;
        end loop;

        --Imprime las columnas de la matriz generada, solo descomentar para verificar la generación de la matriz
        /*FOR i IN matriz.FIRST .. matriz.LAST LOOP
            DBMS_OUTPUT.PUT_LINE('Columna ' || i);
            FOR j IN matriz(i).FIRST .. matriz(i).LAST LOOP
                DBMS_OUTPUT.PUT_LINE(case
                    when matriz(i)(j) then 'TRUE'
                    when not matriz(i)(j) then 'FALSE'
                    end
                    );
            end loop;
        end loop;*/
        RETURN matriz;
    END;

    FUNCTION  peso_cerdos(
        matriz IN matriz_booleana,
        cerdos IN fila_cerdo,
        peso_limite IN NUMBER
    )
    RETURN
        NUMBER
    IS
        peso_final NUMBER;
    BEGIN
        /*
        Por defecto, el peso límite es el máximo del camión seleccionado o del límite del pedido que se ingrese, pero esto
        no quiere decir que se pueda usar toda esta capacidad, por lo que para saber este peso límite, hace falta revisar
        la matriz y determinar cuál es la última columna que tiene al menos un True. Para esto solo basta con recorrer la
        última fíla y todas las columnas de atrás hacia adelante, hasta que se encuentre un True
        */
        peso_final := peso_limite;

        WHILE peso_final > 0 AND NOT matriz(cerdos.LAST)(peso_final) LOOP
            peso_final := peso_final -1;
        end loop;

        RETURN peso_final;

    END;

    FUNCTION  elegir_cerdos(
        matriz IN matriz_booleana,
        cerdos IN fila_cerdo,
        peso_limite IN NUMBER
    )
    RETURN
        fila_cerdo
    IS
        fila_actual NUMBER;
        columna_actual NUMBER;
        conteo_fila NUMBER;
        indice_cerdos NUMBER:=0;
        cerdos_elegidos fila_cerdo;
    BEGIN

        /*
        Para encontrar que cerdos nos permiten usar al máximo la capacidad que tenemos disponible recorremos la matriz de
        nuevo de atrás hacia adelante, empezando desde la última fila y la columna correspondiente al peso máximo encontrado
        anteriormente
        */
        columna_actual := peso_limite;
        fila_actual := cerdos.LAST;

        --Inicializamos la lista de cerdos
        cerdos_elegidos := fila_cerdo();


        WHILE columna_actual > 0 LOOP
            --Definimos estas variables para evitar un choque de valores en el FOR
            conteo_fila := fila_actual;

            FOR fila IN REVERSE 1 .. conteo_fila LOOP

                /*
                Si la fila anterior en la actual columna es un FALSE significa que el cerdo que representa esa fila  se
                puede se
                */
                IF NOT matriz(fila_actual-1)(columna_actual) THEN
                    indice_cerdos := indice_cerdos + 1;
                    cerdos_elegidos.extend;
                    cerdos_elegidos(indice_cerdos):= cerdos(fila_actual);
                    columna_actual := columna_actual - cerdos(fila_actual).PESOKILOS;
                    fila_actual := fila_actual-1;
                    EXIT;
                ELSE
                    fila_actual := fila_actual-1;
                end if;
            end loop;
        end loop;

        RETURN cerdos_elegidos;

    END;

END;