BEGIN
    --Creamos un bloque para crear una tabla cerdo_pedido
    EXECUTE IMMEDIATE 'CREATE TABLE CERDOXCAMION(
        cerdo NUMBER(8) REFERENCES CERDO,
        camion NUMBER(8) REFERENCES CAMION,
        PRIMARY KEY (cerdo,camion))';
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE('La tabla CERDOXCAMION ya está creada');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Error creando tabla ' || SQLERRM || '. Código: ' || sqlcode);
        end if;
end;