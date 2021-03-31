ACCEPT pedido NUMBER PROMPT 'Ingrese su pedido (kg): ';

DECLARE
    pedido                 NUMBER;
    pedido_aux             NUMBER;

    TYPE cam_row IS TABLE OF camion%ROWTYPE;
    camiones               cam_row;
    camiones_seleccionados cam_row;

    TYPE cer_row IS TABLE OF cerdo%ROWTYPE;
    cerdos                 cer_row;
    TYPE bool_list IS TABLE OF NUMBER;
    TYPE bool_matrix IS TABLE OF bool_list;
    cerdos_seleccionados   bool_matrix;
BEGIN
    pedido := &pedido;
    pedido_aux := pedido;
    camiones_seleccionados := cam_row();
    cerdos_seleccionados := bool_matrix();
    SELECT * BULK COLLECT INTO camiones FROM camion ORDER BY MAXIMACAPACIDADKILOS DESC;
    IF camiones.FIRST IS NOT NULL THEN
        IF pedido <= camiones(1).MAXIMACAPACIDADKILOS THEN
            camiones_seleccionados.extend;
            camiones_seleccionados(1) := camiones(1);
        ELSE
            FOR i IN camiones.FIRST .. camiones.LAST
                LOOP
                    camiones_seleccionados.extend;
                    camiones_seleccionados(i) := camiones(i);
                    pedido_aux := pedido_aux - camiones_seleccionados(i).MAXIMACAPACIDADKILOS;
                    EXIT WHEN pedido_aux <= 0;
                END LOOP;
        END IF;
    ELSE
        -- No hay camiones disponibles
        DBMS_OUTPUT.PUT_LINE('El pedido no se puede satisfacer');
    END IF;
END;
/