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

CREATE TABLE gestion (
    id_gestion INT PRIMARY KEY,
    tipo_gestion VARCHAR(50)
);

CREATE TABLE proveedores (
    id_mayorista INT PRIMARY KEY,
    nombre VARCHAR(255),
    rubro VARCHAR(255),
    direccion VARCHAR(255),
    precio_nafta DECIMAL
);

CREATE TABLE clientes (
    id_cliente INT PRIMARY KEY,
    nombre_apellido VARCHAR(255),
    alias VARCHAR(255),
    id_genero INT,
    edad_aproximada VARCHAR(20),
    contacto VARCHAR(255),
    FOREIGN KEY (id_genero) REFERENCES genero(id_genero)
);

CREATE TABLE productos (
    id_producto INT PRIMARY KEY,
    descripcion VARCHAR(255),
    categoria VARCHAR(255),
    subcategoria VARCHAR(255),
    precio_costo DECIMAL,
    precio_venta DECIMAL
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
    id_estado INT,
    monto_final DECIMAL,
    id_metodo_pago INT,
    id_cliente INT,
    FOREIGN KEY (id_estado) REFERENCES estado(id_estado),
    FOREIGN KEY (id_metodo_pago) REFERENCES metodo_pago(id_metodo_pago),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE detalle_venta (
    id_venta INT,
    id_producto INT,
    cantidad INT,
    precio_total DECIMAL,
    PRIMARY KEY (id_venta, id_producto),
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE TABLE stock (
    id_producto INT,
    fecha_control DATE,
    id_gestion INT,
    cantidad INT,
    PRIMARY KEY (id_producto, fecha_control),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    FOREIGN KEY (id_gestion) REFERENCES gestion(id_gestion)
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
