-- Creación de Vistas
SELECT *  FROM 	ventas;}
DROP VIEW vista_top_productos;

-- Ventas por día y monto total
CREATE VIEW vista_ventas_diarias AS
SELECT fecha_venta, SUM(monto_final) AS total_diario, COUNT(*) AS cantidad_ventas
FROM ventas
GROUP BY fecha_venta;

SELECT * FROM vista_ventas_diarias;

-- Productos más vendidos
CREATE VIEW vista_top_productos AS
SELECT p.id_producto, p.descripcion, SUM(dv.cantidad) AS cantidad_vendida, SUM(dv.precio_total) AS ingresos
FROM detalle_venta dv
INNER JOIN productos p ON dv.id_producto=p.id_producto
GROUP BY p.id_producto, p.descripcion
ORDER BY cantidad_vendida DESC;

SELECT * FROM vista_top_productos;

-- Creación de una función
DELIMITER //

CREATE FUNCTION margen_producto(p_id_producto INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
	DECLARE v_margen DECIMAL(10,2);
    
    SELECT (precio_venta - precio_costo) INTO v_margen
    FROM productos
    WHERE id_producto = p_id_producto;
    
    RETURN v_margen;
END//

DELIMITER ;

SELECT id_producto, descripcion, 
       precio_costo, precio_venta, 
       margen_producto(id_producto) AS margen
FROM productos;

-- Creación de Stored Procedure

-- Ingreso de venta nueva y actualización de todos sus componentes
DELIMITER //

CREATE PROCEDURE registrar_venta(
    IN p_fecha DATE,
    IN p_monto DECIMAL(10,2),
    IN p_metodo INT,
    IN p_estado INT,
    IN p_cliente INT,
    IN p_id_producto INT,
    IN p_cantidad INT
)
BEGIN
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_new_id INT;

    SELECT IFNULL(MAX(id_venta), 0) + 1 INTO v_new_id FROM ventas; -- Esto es porque id_venta no es autoincrement y se deberá calcular

    INSERT INTO ventas (id_venta, fecha_venta, monto_final, id_metodo_pago, id_estado, id_cliente)
    VALUES (v_new_id, p_fecha, p_monto, p_metodo, p_estado, p_cliente);

    SELECT precio_venta INTO v_precio 
    FROM productos 
    WHERE id_producto = p_id_producto;

    INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_total)
    VALUES (v_new_id, p_id_producto, p_cantidad, (v_precio * p_cantidad));
END//

DELIMITER ;

-- Comprobamos si funciona

CALL registrar_venta('2025-08-18', 5600.00, 1, 1, 1, 1, 2);

SELECT * FROM detalle_venta;


-- Cración de Trigger

-- Este trigger actualizará el conteo de stock disponible de un producto
-- al ingresar una nueva venta
DELIMITER //

CREATE TRIGGER tr_descuento_stock
AFTER INSERT ON detalle_venta
FOR EACH ROW
BEGIN
    DECLARE v_fecha DATE; -- Variable para guardar la última fecha de control

    SELECT MAX(fecha_control)
    INTO v_fecha
    FROM stock
    WHERE id_producto = NEW.id_producto;

    -- Actualizamos
    UPDATE stock
    SET unidades_en_stock = unidades_en_stock - NEW.cantidad
    WHERE id_producto = NEW.id_producto
      AND fecha_control = v_fecha;
END//

DELIMITER ;

-- Dato ficticio para la tabla stock, id_producto 1 se verá modificado con el trigger
INSERT INTO stock (id_producto, fecha_control, unidades_en_stock)
VALUES (1, '2025-08-18', 100);

-- Para insertar un nuevo dato en detalle_venta es necesario actualizar ventas por existir FK
INSERT INTO ventas (id_venta, fecha_venta, monto_final, id_metodo_pago, id_estado, id_cliente)
VALUES (87, '2025-08-18', 5600, 1, 1, 1);

-- En este punto se dispara el trigger
INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_total)
VALUES (87, 1, 2, 5600);

SELECT * FROM stock;


