CREATE OR REPLACE TRIGGER borrar_individuo
BEFORE DELETE ON INDIVIDUO
FOR EACH ROW
BEGIN
    IF :OLD.PADRE IS NOT NULL THEN
        UPDATE individuo
        SET nro_hijos = nro_hijos - 1
        WHERE codigo = :OLD.padre;
    end if;
    IF :OLD.nro_hijos IS NOT NULL THEN
        UPDATE individuo
        SET padre = NULL
        WHERE padre = :OLD.codigo;
    end if;
end;