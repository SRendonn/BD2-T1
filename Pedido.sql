DECLARE

    pedido POSITIVE;
    peso_enviado NUMBER(10) := 0;
    peso_restante NUMBER(10);
    peso_maximo NUMBER(10);

    TYPE cam_row IS TABLE OF camion%ROWTYPE;
    camiones               cam_row;

    --Array para los cerdos que pueden satisfacer el pedido
    TYPE fila_cerdo IS TABLE OF cerdo%ROWTYPE;
    cerdos_elegibles fila_cerdo;
    cerdos_en_camion fila_cerdo := fila_cerdo();

    --Matriz para guardar la tabla de Falsos y Verdaderos
    TYPE booleano IS TABLE OF BOOLEAN INDEX BY BINARY_INTEGER;
    TYPE matriz_booleana IS TABLE OF  booleano INDEX BY BINARY_INTEGER;
    matriz matriz_booleana;

    kilos_actuales cerdo.pesokilos%TYPE;
    fila_actual NUMBER(3);
    conteo_fila NUMBER(3);
    columna_actual NUMBER(3);
    cerdos_en_camion_indice NUMBER(3) := 0;

BEGIN
    pedido := 16;
    BEGIN
        EXECUTE IMMEDIATE 'CREATE TABLE cerdo_pedido(
                            cerdo NUMBER(8) REFERENCES CERDO,
                            camion NUMBER(8) REFERENCES CAMION,
                            PRIMARY KEY (cerdo,camion))';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -955 THEN
                DELETE CERDOXCAMION WHERE CERDO IN (SELECT CERDO FROM CERDOXCAMION);
                COMMIT;
            ELSE
                DBMS_OUTPUT.PUT_LINE('Error creando tabla ' || SQLERRM || '. Código: ' || sqlcode);
            end if;
    end;

    -- Traigo los camiones disponibles ordenados de mayor a menor capacidad
    SELECT * BULK COLLECT
    INTO camiones
    FROM camion
    ORDER BY maximacapacidadkilos DESC, IDCAMION ASC;

    --Comprobamos que si hayan camiones
    IF camiones.COUNT <> 0 THEN
        --Recorremos los camiones
        FOR camion_i IN camiones.FIRST .. camiones.LAST LOOP
            --Calculamos el peso que falta
            peso_restante := pedido - peso_enviado;
            peso_maximo := LEAST(peso_restante, camiones(camion_i).MAXIMACAPACIDADKILOS);

            -- Bulk Collect para encontrar los cerdos que están entre el límite
            SELECT * BULK COLLECT
            INTO cerdos_elegibles
            FROM CERDO
            WHERE (
                (PESOKILOS>0 AND PESOKILOS<=peso_maximo) AND
                COD NOT IN (SELECT CC.CERDO FROM CERDOXCAMION CC)
                )
            ORDER BY PESOKILOS, COD
            ;

            IF cerdos_elegibles.COUNT <> 0 THEN
                BEGIN
                    --Generamos la matriz de falsos y verdaderos
                    --Siempre iniciamos desde la fila 0 hasta el último cerdito
                    FOR fila IN 0 .. cerdos_elegibles.LAST LOOP

                        --Las columnas también empiezan en 0 hasta el máximo peso que se pueda aceptar
                        FOR columna IN 0 .. peso_maximo LOOP

                            --kilos_actuales representa los kilos del cerdito que estamos analizando en el momento para crear la matriz
                            --Si nos encontramos en la fila 0, significa que no estamos tomando ningún cerdito, por lo que se le asigna 0
                            kilos_actuales := 0;
                            IF fila <> 0 THEN
                                kilos_actuales := cerdos_elegibles(fila).PESOKILOS;
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

                    /*
                    Por defecto, el peso límite es el máximo del camión seleccionado o del límite del pedido que se ingrese, pero esto
                    no quiere decir que se pueda usar toda esta capacidad, por lo que para saber este peso límite, hace falta revisar
                    la matriz y determinar cuál es la última columna que tiene al menos un True. Para esto solo basta con recorrer la
                    última fíla y todas las columnas de atrás hacia adelante, hasta que se encuentre un True
                    */
                    WHILE peso_maximo > 0 AND NOT matriz(cerdos_elegibles.LAST)(peso_maximo) LOOP
                        peso_maximo := peso_maximo -1;
                    end loop;

                    /*
                    Para encontrar que cerdos nos permiten usar al máximo la capacidad que tenemos disponible recorremos la matriz de
                    nuevo de atrás hacia adelante, empezando desde la última fila y la columna correspondiente al peso máximo encontrado
                    anteriormente
                    */
                    columna_actual := peso_maximo;
                    fila_actual := cerdos_elegibles.LAST;

                    WHILE columna_actual > 0 LOOP
                        conteo_fila := fila_actual;
                        FOR fila IN REVERSE 1 .. conteo_fila LOOP
                            IF NOT matriz(fila_actual-1)(columna_actual) THEN
                                cerdos_en_camion_indice := cerdos_en_camion_indice + 1;
                                cerdos_en_camion.extend;
                                cerdos_en_camion(cerdos_en_camion_indice):= cerdos_elegibles(fila_actual);
                                columna_actual := columna_actual - cerdos_elegibles(fila_actual).PESOKILOS;
                                fila_actual := fila_actual-1;
                                EXIT;
                            ELSE
                                fila_actual := fila_actual-1;
                            end if;
                        end loop;
                    end loop;


                    --DBMS_OUTPUT.PUT_LINE(peso_limite);

                    FOR cerdo_i IN 1 .. cerdos_en_camion_indice LOOP
                        DBMS_OUTPUT.PUT_LINE(cerdos_en_camion(cerdo_i).COD || ' ' || cerdos_en_camion(cerdo_i).NOMBRE || ' ' || cerdos_en_camion(cerdo_i).PESOKILOS);
                        INSERT INTO CERDOXCAMION VALUES (cerdos_en_camion(cerdo_i).COD, camiones(camion_i).IDCAMION);
                        COMMIT;
                    end loop;

                end;

                peso_enviado := peso_enviado + peso_maximo;
                cerdos_en_camion := fila_cerdo();
                cerdos_en_camion_indice := 0;

            ELSE
                EXIT;
            end if;

        end loop;
    ELSE
        DBMS_OUTPUT.PUT_LINE('El pedido no se puede satisfacer');
    end if;

end;