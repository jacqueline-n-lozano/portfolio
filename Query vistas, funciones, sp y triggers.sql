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
