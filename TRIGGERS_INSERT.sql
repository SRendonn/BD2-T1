CREATE OR REPLACE TRIGGER insertar_individuo
BEFORE INSERT ON INDIVIDUO
FOR EACH ROW
DECLARE
    cero_hijos EXCEPTION;
BEGIN
    IF :NEW.nro_hijos <> 0 THEN
        RAISE_APPLICATION_ERROR(-20500,'Solo se permite creación con 0 hijos');
    ELSE
        IF :NEW.PADRE IS NOT NULL THEN
            UPDATE individuo
            SET nro_hijos = nro_hijos + 1
            WHERE codigo = :NEW.padre;
        end if;
    END IF;
end;