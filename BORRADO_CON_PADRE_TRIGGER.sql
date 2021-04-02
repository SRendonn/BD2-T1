CREATE OR REPLACE TRIGGER borrado_con_padre
FOR DELETE ON INDIVIDUO
COMPOUND TRIGGER

    --Declaramos la variable dónde vamos a guardar el código del padre
    codigo_padre NUMBER(8);

    --Antes de borrar, guardamos el código del padre
    BEFORE EACH ROW IS BEGIN
        codigo_padre := :OLD.PADRE;
    END BEFORE EACH ROW;

    --Después de borrar, ejecutamos la disminución del valor del número de hijos
    AFTER STATEMENT IS BEGIN

        IF codigo_padre IS NOT NULL THEN
            UPDATE individuo
            SET nro_hijos = nro_hijos -1
            WHERE CODIGO = codigo_padre;
        end if;

    END AFTER STATEMENT;

end;