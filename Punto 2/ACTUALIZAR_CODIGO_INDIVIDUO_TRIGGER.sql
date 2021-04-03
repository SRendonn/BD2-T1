CREATE OR REPLACE TRIGGER actualizar_codigo_individuo
FOR UPDATE OF CODIGO ON INDIVIDUO
COMPOUND TRIGGER

    TYPE fila_individuos IS TABLE OF individuo%ROWTYPE;
    individuos_originales fila_individuos;


    codigo_nuevo_individuo NUMBER(8);
    codigo_viejo_individuo NUMBER(8);


    BEFORE STATEMENT IS BEGIN

        SELECT *
        BULK COLLECT
        INTO individuos_originales
        FROM INDIVIDUO;

        UPDATE individuo
        SET padre = NULL
        WHERE CODIGO IN (SELECT CODIGO FROM INDIVIDUO);

    END BEFORE STATEMENT;

    --Guardamos los códigos viejos y nuevos para comparar en el After
    BEFORE EACH ROW IS BEGIN
        codigo_viejo_individuo := :OLD.CODIGO;
        codigo_nuevo_individuo := :NEW.CODIGO;

    END BEFORE EACH ROW;

    --Después de actualizar, recuperamos los datos originales y actualizamos el padre de los hijos del individuo
    AFTER STATEMENT IS BEGIN

        FOR individuo_i in individuos_originales.FIRST .. individuos_originales.LAST LOOP
            -- Retornamos a los valores originales para
            IF individuos_originales(individuo_i).PADRE <> codigo_viejo_individuo
                OR individuos_originales(individuo_i).PADRE IS NULL
                THEN
                UPDATE individuo
                SET padre = individuos_originales(individuo_i).PADRE
                WHERE INDIVIDUO.CODIGO = individuos_originales(individuo_i).CODIGO;
            ELSE
                UPDATE individuo
                SET padre = codigo_nuevo_individuo
                WHERE INDIVIDUO.CODIGO = individuos_originales(individuo_i).CODIGO;
            end if;
        END LOOP;

    END AFTER STATEMENT;

end;