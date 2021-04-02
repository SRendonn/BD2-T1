CREATE OR REPLACE TRIGGER ingreso_con_padre
BEFORE INSERT ON INDIVIDUO
FOR EACH ROW
FOLLOWS INGRESO_CERO_HIJOS
WHEN (NEW.PADRE IS NOT NULL)
BEGIN
    UPDATE individuo
    SET nro_hijos = nro_hijos + 1
    WHERE codigo = :NEW.padre;
end;