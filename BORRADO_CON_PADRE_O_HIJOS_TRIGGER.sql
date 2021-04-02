CREATE OR REPLACE TRIGGER borrado_con_padre_o_hijos
FOR DELETE ON INDIVIDUO
COMPOUND TRIGGER

    --Declaramos la variable dónde vamos a guardar el código del padre
    codigo_padre NUMBER(8);

    TYPE fila_individuos IS TABLE OF individuo%ROWTYPE;
    individuos_originales fila_individuos;

    --Declaramos la variable dónde vamos a guardar el número de hijos del individuo
    numero_de_hijos NUMBER(8);
    codigo_individuo NUMBER(8);


    BEFORE STATEMENT IS BEGIN

        SELECT *
        BULK COLLECT
        INTO individuos_originales
        FROM INDIVIDUO;

        UPDATE individuo
        SET padre = NULL
        WHERE CODIGO IN (SELECT CODIGO FROM INDIVIDUO);

    END BEFORE STATEMENT;

    --Antes de borrar, guardamos el código del padre
    BEFORE EACH ROW IS BEGIN
        codigo_individuo := :OLD.CODIGO;
        codigo_padre := NULL;
        numero_de_hijos := :OLD.NRO_HIJOS;

        FOR i_individuo in individuos_originales.FIRST .. individuos_originales.LAST LOOP
            IF individuos_originales(i_individuo).CODIGO = codigo_individuo THEN
                codigo_padre := individuos_originales(i_individuo).PADRE;
                EXIT;
            end if;
        end loop;

    END BEFORE EACH ROW;

    --Después de borrar, ejecutamos la disminución del valor del número de hijos
    AFTER STATEMENT IS BEGIN

        --Solo se ejecuta si el padre era diferente de NULL
        IF codigo_padre IS NOT NULL THEN
            UPDATE individuo
            SET nro_hijos = nro_hijos -1
            WHERE CODIGO = codigo_padre;
        end if;

        FOR individuo_i in individuos_originales.FIRST .. individuos_originales.LAST LOOP
            IF individuos_originales(individuo_i).CODIGO <> codigo_individuo AND
               individuos_originales(individuo_i).PADRE <> codigo_individuo THEN
                UPDATE individuo
                SET padre = individuos_originales(individuo_i).PADRE
                WHERE INDIVIDUO.CODIGO = individuos_originales(individuo_i).CODIGO;
            end if;
        END LOOP;

    END AFTER STATEMENT;

end;