INSERT INTO individuo VALUES (19,'Hope Sandoval',10,NULL,0);
INSERT INTO individuo VALUES (32,'Kirsty Hawkshaw',8,NULL,0);
INSERT INTO individuo VALUES (64,'Annabella Lwin',10,19,0);
INSERT INTO individuo VALUES (122,'Amanda Marshall',20,19,0);
INSERT INTO individuo VALUES (11,'Mavvie Marcos',2,64,0);
DELETE INDIVIDUO WHERE CODIGO=19;
DELETE INDIVIDUO WHERE CODIGO=32;
DELETE INDIVIDUO WHERE CODIGO=64;
DELETE INDIVIDUO WHERE CODIGO=122;
DELETE INDIVIDUO WHERE CODIGO=11;
UPDATE INDIVIDUO SET VALOR = 5 WHERE CODIGO = 2030;
DROP TRIGGER ingreso_cero_hijos;
DROP TRIGGER ingreso_con_padre;
DROP TRIGGER borrado_con_padre_o_hijos;
DROP TRIGGER actualizar_valor_individuo;
DROP TRIGGER actualizar_codigo_individuo;
commit;