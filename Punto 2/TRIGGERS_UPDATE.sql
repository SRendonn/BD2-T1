CREATE OR REPLACE TRIGGER actualizar_individuo
FOR UPDATE ON INDIVIDUO
WHEN ( NEW.CODIGO <> OLD.CODIGO )
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

    --Antes de borrar, guardamos el código del padre
    BEFORE EACH ROW IS BEGIN
        codigo_viejo_individuo := :OLD.CODIGO;
        codigo_nuevo_individuo := :NEW.CODIGO;

        /*FOR i_individuo in individuos_originales.FIRST .. individuos_originales.LAST LOOP
            IF individuos_originales(i_individuo).CODIGO = codigo_individuo THEN
                codigo_padre := individuos_originales(i_individuo).PADRE;
                EXIT;
            end if;
        end loop;*/

    END BEFORE EACH ROW;

    --Después de borrar, ejecutamos la disminución del valor del número de hijos
    AFTER STATEMENT IS BEGIN

    /*IF :NEW.codigo <> :OLD.codigo THEN
        UPDATE INDIVIDUO
        SET padre = :NEW.codigo
        WHERE padre = :OLD.codigo;
    end if;*/

    /*
        --Solo se ejecuta si el padre era diferente de NULL
        IF codigo_padre IS NOT NULL THEN
            UPDATE individuo
            SET nro_hijos = nro_hijos -1
            WHERE CODIGO = codigo_padre;
        end if;
        */
        FOR individuo_i in individuos_originales.FIRST .. individuos_originales.LAST LOOP
            IF individuos_originales(individuo_i).PADRE <> codigo_viejo_individuo THEN
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
/*
CREATE OR REPLACE TRIGGER actualizar_individuo
BEFORE UPDATE ON INDIVIDUO
FOR EACH ROW
DECLARE
    diferencia INDIVIDUO.valor%TYPE;
    TYPE fila_individuo IS TABLE OF INDIVIDUO%ROWTYPE;
    hijos fila_individuo;
    aumento_menor EXCEPTION;
BEGIN
    IF :NEW.codigo <> :OLD.codigo THEN
        UPDATE INDIVIDUO
        SET padre = :NEW.codigo
        WHERE padre = :OLD.codigo;
    end if;
    IF :NEW.valor > :OLD.valor THEN
        diferencia := :NEW.valor - :OLD.valor;
        IF diferencia >= 5 THEN
            :NEW.valor := :NEW.valor + 2;
            diferencia := diferencia - 2;
            IF :OLD.nro_hijos = 1 THEN
                UPDATE individuo
                SET valor = valor + diferencia
                WHERE padre = :NEW.codigo;
            ELSIF :NEW.nro_hijos <> 0 THEN
                SELECT * BULK COLLECT
                INTO hijos
                FROM INDIVIDUO
                WHERE padre = :NEW.codigo
                ORDER BY VALOR DESC
                ;
                UPDATE individuo
                SET valor = valor + diferencia
                WHERE padre = :NEW.codigo AND codigo = hijos(1).CODIGO
                ;
            end if;
        ELSE
            --RAISE aumento_menor;
            RAISE_APPLICATION_ERROR(-20501,'Solo se permiten aumentos de 5 unidades o más en el valor del individuo');
        end if;
    end if;
--EXCEPTION
    --WHEN aumento_menor THEN
        --DBMS_OUTPUT.PUT_LINE('Solo se permiten aumentos de 5 unidades o más en el valor del individuo');
end;*/