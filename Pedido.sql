ACCEPT pedido NUMBER PROMPT 'Ingrese su pedido (kg): ';

DECLARE

    pedido POSITIVE;
    peso_enviado NUMBER(10) := 0;
    peso_restante NUMBER(10);
    peso_maximo NUMBER(10);

    cadena_informe varchar2(1000);

    --Array para los camiones existentes
    camiones GRANJA_CERDOS.fila_camion;

    --Array para los cerdos que pueden satisfacer el pedido
    cerdos_elegibles GRANJA_CERDOS.fila_cerdo;
    cerdos_en_camion GRANJA_CERDOS.fila_cerdo := GRANJA_CERDOS.fila_cerdo();

    --Matriz para guardar la tabla de Falsos y Verdaderos
    matriz GRANJA_CERDOS.matriz_booleana;

    --Excepción propia para cuándo no se puede hacer el pedido
    no_se_puede EXCEPTION;

BEGIN
    --Entrada del pedido
    pedido := &pedido;
    DELETE CERDOXCAMION WHERE CERDO IN (SELECT CERDO FROM CERDOXCAMION);

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
            --Calculamos el máximo peso que podemos llevar en este camión según lo que aún resta del pedido
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

            --Si hay al menos un cerdo elegible, calculamos cómo pueden entrar en el camión
            IF cerdos_elegibles.COUNT <> 0 THEN

                BEGIN

                    /*
                    Usamos el package 'GRANJA_CERDOS' para implementar el algoritmo que resuelve el 'Problema de la suma
                    del subconjunto' (Subset Sum Problem)
                    */
                    matriz := GRANJA_CERDOS.MATRIZ_FALSO_VERDADERO(cerdos_elegibles, peso_maximo);

                    peso_maximo := GRANJA_CERDOS.PESO_CERDOS(matriz, cerdos_elegibles, peso_maximo);

                    cerdos_en_camion := GRANJA_CERDOS.ELEGIR_CERDOS(matriz, cerdos_elegibles, peso_maximo);

                    -- Si estamos en el primer camión, imprimimos la cabecera del informe
                    IF camion_i = camiones.FIRST THEN
                        DBMS_OUTPUT.PUT_LINE('Informe para Mi Cerdito.');
                        DBMS_OUTPUT.PUT_LINE('-----');
                    end if;

                    --Imprimimos el id del camión
                    DBMS_OUTPUT.PUT_LINE('Camión: ' || camiones(camion_i).IDCAMION);

                    --Generamos el informe de los cerdos
                    FOR cerdo_i IN 1 .. cerdos_en_camion.LAST LOOP
                        IF cerdo_i <> 1 THEN
                            cadena_informe :=  ','||cadena_informe;
                        end if;
                        cadena_informe := ' '||cerdos_en_camion(cerdo_i).COD||' ('||cerdos_en_camion(cerdo_i).NOMBRE||') '||cerdos_en_camion(cerdo_i).PESOKILOS||'kg'||cadena_informe;
                        INSERT INTO CERDOXCAMION VALUES (cerdos_en_camion(cerdo_i).COD, camiones(camion_i).IDCAMION);
                    end loop;
                    COMMIT;
                    DBMS_OUTPUT.PUT_LINE('Lista cerdos:'||cadena_informe);

                    --Imprimimos el informe del envío en el camión
                    DBMS_OUTPUT.PUT_LINE('Total peso cerdos: '||peso_maximo||'kg. Capacidad no usada del camión: '||(camiones(camion_i).MAXIMACAPACIDADKILOS-peso_maximo)||'kg');

                end;

                --Actualizamos las variables para la próxima iteración del FOR
                peso_enviado := peso_enviado + peso_maximo;
                cerdos_en_camion := GRANJA_CERDOS.fila_cerdo();
                cadena_informe := NULL;

            ELSE
                /*
                Si es el primer camión, esto quiere decir que no hay camión que pueda llevar los cerdos disponibles o
                que no hay cerdos, por lo que no se puede satisfacer el pedido. Se lanza la excepción
                */
                IF camion_i = camiones.FIRST THEN
                    RAISE no_se_puede;
                end if;

                /*
                Si no se ejecuta la excepción, significa que hay al menos un camión que se pudo utilizar, por lo que se
                debe imprimir el final del informe
                */
                DBMS_OUTPUT.PUT_LINE('-----');
                DBMS_OUTPUT.PUT_LINE('Total Peso solicitado: '||pedido||'kg. Peso real enviado: '||peso_enviado||'kg. Peso no satisfecho: '||(pedido-peso_enviado)||'kg.');

                --Salimos del for, pues ya no hay camiones que puedan enviar cerdos para cumplir con el pedido
                EXIT;
            end if;

        end loop;

    --Si no hay camiones, lanzamos la excepción de que no se puede satisfacer el pedido
    ELSE
        RAISE no_se_puede;
    end if;

EXCEPTION
    WHEN no_se_puede THEN
        DBMS_OUTPUT.PUT_LINE('El pedido no se puede satisfacer');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error ejecutando script ' || SQLERRM || '. Código: ' || sqlcode);
end;