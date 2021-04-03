CREATE OR REPLACE TRIGGER actualizar_valor_individuo
FOR UPDATE OF VALOR ON INDIVIDUO
FOLLOWS ACTUALIZAR_CODIGO_INDIVIDUO
COMPOUND TRIGGER

    diferencia INDIVIDUO.valor%TYPE;
    adicion_hijo individuo.valor%TYPE;
    codigo_nuevo_individuo individuo.codigo%TYPE;
    numero_hijos individuo.nro_hijos%TYPE;
    hijo_elegido individuo%ROWTYPE;

    TYPE fila_individuos IS TABLE OF individuo%ROWTYPE;
    hijos fila_individuos;
    hijos_de_hijo fila_individuos;

    BEFORE EACH ROW IS BEGIN
        diferencia := :NEW.VALOR - :OLD.VALOR;
        --Si esta condición no se cumple, el UPDATE pasa derecho
        IF diferencia > 0 THEN
            --Se detiene la ejecución si el cambio es menor a 5
            IF diferencia < 5 THEN
                RAISE_APPLICATION_ERROR(-20501,'Solo se permiten aumentos de 5 unidades o más en el valor del individuo');
            ELSE
                --Almacenamos las variables que requerimos para ejecutar los cambios en el AFTER
                --Actualizamos el nuevo valor
                :NEW.VALOR := :OLD.VALOR + 2;
                adicion_hijo := diferencia - 2;
                codigo_nuevo_individuo := :NEW.CODIGO;
                numero_hijos := :OLD.NRO_HIJOS;
            END IF;
        end if;
    end BEFORE EACH ROW;

    AFTER STATEMENT IS BEGIN
        --Si no se cumplen ninguna de estas condiciones,
        IF diferencia >= 5  AND numero_hijos > 0 THEN

            SELECT *
            BULK COLLECT
            INTO hijos
            FROM individuo
            WHERE PADRE = codigo_nuevo_individuo
            ORDER BY valor ASC;

            hijo_elegido := hijos(1);

            IF hijo_elegido.NRO_HIJOS > 0 THEN
                SELECT *
                BULK COLLECT
                INTO hijos_de_hijo
                FROM individuo
                WHERE PADRE = hijo_elegido.CODIGO;
            end if;

            adicion_hijo := adicion_hijo + hijo_elegido.VALOR;

            DELETE FROM individuo WHERE CODIGO = hijo_elegido.CODIGO;
            INSERT INTO individuo VALUES (hijo_elegido.CODIGO,hijo_elegido.NOMBRE,adicion_hijo,hijo_elegido.PADRE,0);

            IF hijo_elegido.NRO_HIJOS > 0 THEN
                UPDATE individuo SET nro_hijos = hijo_elegido.NRO_HIJOS WHERE CODIGO = hijo_elegido.CODIGO;
                FORALL hijos_i IN hijos_de_hijo.FIRST .. hijos_de_hijo.LAST
                    UPDATE individuo SET padre = hijo_elegido.CODIGO WHERE CODIGO = hijos_de_hijo(hijos_i).CODIGO;
            end if;


        end if;
    END AFTER STATEMENT;
END;