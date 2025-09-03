-- VISTAS

-- 1) Ventas por día y monto total
CREATE VIEW vista_ventas_diarias AS
SELECT fecha_venta, SUM(monto_final) AS total_diario, COUNT(*) AS cantidad_ventas
FROM ventas
GROUP BY fecha_venta;

SELECT * FROM vista_ventas_diarias;

-- 2) Productos más vendidos
CREATE VIEW vista_top_productos AS
SELECT p.id_producto, p.descripcion, SUM(dv.cantidad) AS cantidad_vendida, SUM(dv.precio_total) AS ingresos
FROM detalle_venta dv
INNER JOIN productos p ON dv.id_producto=p.id_producto
GROUP BY p.id_producto, p.descripcion
ORDER BY cantidad_vendida DESC;

SELECT * FROM vista_top_productos;

-- 3) Ventas agrupadas por año y mes
CREATE VIEW ventas_por_mes AS
SELECT 
    YEAR(fecha_venta) AS año,
    MONTH(fecha_venta) AS mes,
    COUNT(id_venta) AS cantidad_ventas,
    SUM(monto_final) AS total_ventas
FROM ventas
GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY año, mes;

SELECT * FROM ventas_por_mes;

-- 4) Productos más devueltos
CREATE VIEW vista_productos_mas_devueltos AS
SELECT 
    p.id_producto,
    p.descripcion AS producto,
    SUM(d.cantidad_devuelta) AS total_devueltos,
    COUNT(DISTINCT d.id_venta) AS cantidad_ventas_con_devolucion
FROM devoluciones d
INNER JOIN productos p 
    ON d.id_producto = p.id_producto
GROUP BY p.id_producto, p.descripcion
ORDER BY total_devueltos DESC;

SELECT * FROM vista_productos_mas_devueltos

-- 5) Clientes que más compran
CREATE VIEW vista_clientes_mas_compran AS
SELECT 
    c.id_cliente,
    c.nombre_apellido,
    c.alias,
    COUNT(v.id_venta) AS cantidad_compras,
    SUM(v.monto_final) AS monto_total_gastado
FROM ventas v
INNER JOIN clientes c 
    ON v.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nombre_apellido, c.alias
ORDER BY cantidad_compras DESC;

SELECT * FROM vista_clientes_mas_compran;

-- FUNCIONES

-- 1) Cálculo de rendimiento de cada producto
DELIMITER //

CREATE FUNCTION margen_producto(p_id_producto INT)
RETURNS DECIMAL(12,4)
DETERMINISTIC
BEGIN
	DECLARE v_margen DECIMAL(12,4);
    
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

-- 2) Cálculo de ventas por período
DELIMITER //
CREATE FUNCTION calcular_ventas_por_periodo(fecha_inicio DATE, fecha_fin DATE)
RETURNS DECIMAL(12, 4)
DETERMINISTIC
BEGIN
    -- Declara una variable para almacenar el monto total
    DECLARE total_ventas DECIMAL(12, 4);

    -- Calcula la suma del 'monto_final' para todas las ventas entre las fechas de inicio y fin.
    SELECT SUM(monto_final)
    INTO total_ventas
    FROM ventas
    WHERE fecha_venta BETWEEN fecha_inicio AND fecha_fin;

    IF total_ventas IS NULL THEN
        RETURN 0.00;
    ELSE
        RETURN total_ventas;
    END IF;
END//
DELIMITER ;

SELECT calcular_ventas_por_periodo('2025-04-01', '2025-04-30') AS Total_Ventas_Abril;


-- PROCEDIMIENTOS ALMACENADOS

-- 1) Ingreso de venta nueva y actualización de todos sus componentes
DELIMITER //

CREATE PROCEDURE registrar_venta(
    IN p_fecha DATE,
    IN p_monto DECIMAL(12,2),
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

-- 2) Gestionar una devolución y restituir el stock
DROP PROCEDURE registrar_devolucion;
DELIMITER //

CREATE PROCEDURE registrar_devolucion (
    IN p_id_producto INT,
    IN p_id_venta INT,
    IN p_cantidad_devuelta INT,
    IN p_fecha DATE,
    IN p_motivo VARCHAR(255),
    IN p_resolucion VARCHAR(255)
)
BEGIN
    -- Insertar la devolución
    INSERT INTO devoluciones (
        id_producto, id_venta, cantidad_devuelta, fecha_devolucion, motivo_devolucion, resolucion
    )
    VALUES (
        p_id_producto, p_id_venta, p_cantidad_devuelta, p_fecha, p_motivo, p_resolucion
    );

    -- Verificar si ya existe un registro de stock para ese producto en esa fecha
    -- Pues la tabla stock tiene como PK id_venta e id_producto (control único de producto por fecha)
    IF EXISTS (
        SELECT 1 FROM stock 
        WHERE id_producto = p_id_producto 
          AND fecha_control = p_fecha
    ) THEN
        -- Si existe, actualizar sumando la devolución
        UPDATE stock
        SET unidades_en_stock = unidades_en_stock + p_cantidad_devuelta
        WHERE id_producto = p_id_producto 
          AND fecha_control = p_fecha;
    ELSE
        -- Si no existe, crear un nuevo registro en stock
        INSERT INTO stock (id_producto, fecha_control, unidades_en_stock)
        VALUES (p_id_producto, p_fecha, p_cantidad_devuelta);
    END IF;
END //

DELIMITER ;

SELECT * FROM stock;
CALL registrar_devolucion(2, 23, 1, '2025-09-01', 'Producto vencido', 'Reintegrado al stock'); 


-- TRIGGERS

-- 1) Actualización del conteo de stock disponible de un producto al ingresar una nueva venta
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

-- 2) Ingreso de una nueva venta en 'detalle_venta' y actualización en tabla 'ventas'
DELIMITER //
CREATE TRIGGER trg_actualizar_monto_venta
AFTER INSERT ON detalle_venta
FOR EACH ROW
BEGIN
    -- Declara una variable para almacenar el precio de venta del producto.
    DECLARE precio_prod DECIMAL(12, 2);

    -- Obtiene el precio de venta del producto de la tabla 'productos'
    SELECT precio_venta INTO precio_prod
    FROM productos
    WHERE id_producto = NEW.id_producto;

    -- Actualiza el monto_final  en la tabla 'ventas'
    -- El monto se incrementa con el precio del nuevo producto multiplicado por la cantidad
    UPDATE ventas
    SET monto_final = monto_final + (precio_prod * NEW.cantidad)
    WHERE id_venta = NEW.id_venta;
END//
DELIMITER ;

-- Ahora, primero ingreso una venta sin calcular el monto_final, el trigger se activará luego
-- y modificará la tabla detalle_venta
INSERT INTO ventas (id_venta, fecha_venta, monto_final, id_metodo_pago, id_estado, id_cliente) VALUES (101, CURDATE(), 0, 1, 1, 1);
INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_total) VALUES (101, 1, 1, 50.00);

SELECT * FROM ventas;

