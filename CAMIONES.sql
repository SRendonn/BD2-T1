ACCEPT pedido NUMBER PROMPT 'Ingrese su pedido (kg): ';

DECLARE
    pedido                 NUMBER;
    pedido_aux             NUMBER;

    TYPE cam_row IS TABLE OF camion%ROWTYPE;
    camiones               cam_row;
    camiones_seleccionados cam_row;
BEGIN
    pedido := &pedido;
    pedido_aux := pedido;
    camiones_seleccionados := cam_row();
    SELECT * BULK COLLECT INTO camiones FROM camion ORDER BY maximacapacidadkilos DESC;
    IF camiones.FIRST IS NOT NULL THEN
        IF pedido <= camiones(1).MAXIMACAPACIDADKILOS THEN
            camiones_seleccionados.extend;
            camiones_seleccionados(1) := camiones(1);
            DBMS_OUTPUT.PUT_LINE('Camión ' || camiones_seleccionados(1).IDCAMION || ' Cap. ' ||
                                camiones_seleccionados(1).MAXIMACAPACIDADKILOS);
        ELSE
            FOR i IN camiones.FIRST .. camiones.LAST
                LOOP
                    camiones_seleccionados.extend;
                    camiones_seleccionados(i) := camiones(i);
                    pedido_aux := pedido_aux - camiones_seleccionados(i).MAXIMACAPACIDADKILOS;
                    DBMS_OUTPUT.PUT_LINE(
                                'Camión ' || camiones_seleccionados(i).IDCAMION || ' Cap. ' ||
                                camiones_seleccionados(i).MAXIMACAPACIDADKILOS);
                    EXIT WHEN pedido_aux <= 0;
                END LOOP;
        END IF;
    END IF;
END ;
/