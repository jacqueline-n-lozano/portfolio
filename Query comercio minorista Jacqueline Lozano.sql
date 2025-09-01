DROP DATABASE comercio_minorista;
CREATE DATABASE IF NOT EXISTS comercio_minorista;
USE comercio_minorista;

CREATE TABLE genero (
    id_genero INT PRIMARY KEY,
    genero VARCHAR(20)
);

CREATE TABLE metodo_pago (
    id_metodo_pago INT PRIMARY KEY,
    metodo_pago VARCHAR(50)
);

CREATE TABLE estado (
    id_estado INT PRIMARY KEY,
    estado_venta VARCHAR(20)
);

CREATE TABLE proveedores (
    id_mayorista INT PRIMARY KEY,
    nombre VARCHAR(255),
    rubro VARCHAR(255),
    direccion VARCHAR(255)
);

CREATE TABLE clientes (
    id_cliente INT PRIMARY KEY,
    nombre_apellido VARCHAR(255) NULL,
    alias VARCHAR(255) NULL,
    id_genero INT NULL,
    edad_aproximada VARCHAR(20) NULL,
    contacto VARCHAR(255) NULL,
    FOREIGN KEY (id_genero) REFERENCES genero(id_genero)
);

CREATE TABLE productos (
    id_producto INT PRIMARY KEY,
    descripcion VARCHAR(255),
    categoria VARCHAR(255),
    subcategoria VARCHAR(255),
    precio_costo DECIMAL(12,2),
    precio_venta DECIMAL(12,2),
    rendimiento DECIMAL(12,4)
);

CREATE TABLE productos_proveedores (
    id_producto INT,
    id_mayorista INT,
    PRIMARY KEY (id_producto, id_mayorista),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    FOREIGN KEY (id_mayorista) REFERENCES proveedores(id_mayorista)
);

CREATE TABLE ventas (
    id_venta INT PRIMARY KEY,
    fecha_venta DATE,
    monto_final DECIMAL(12,4),
    id_metodo_pago INT,
	id_estado INT,
    id_cliente INT NULL,
    FOREIGN KEY (id_estado) REFERENCES estado(id_estado),
    FOREIGN KEY (id_metodo_pago) REFERENCES metodo_pago(id_metodo_pago),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE detalle_venta (
    id_venta INT,
    id_producto INT,
    cantidad INT,
    precio_total DECIMAL(12,4),
    PRIMARY KEY (id_venta, id_producto),
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE TABLE stock (
    id_producto INT,
    fecha_control DATE,
    unidades_en_stock INT,
    PRIMARY KEY (id_producto, fecha_control),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE TABLE devoluciones (
    id_producto INT,
    id_venta INT,
    cantidad_devuelta INT,
    fecha_devolucion DATE,
    motivo_devolucion VARCHAR(255),
    resolucion VARCHAR(255),
    PRIMARY KEY (id_producto, id_venta),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta)
);

