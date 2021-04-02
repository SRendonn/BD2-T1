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
end;