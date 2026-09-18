-- Pregunta 1 — Catálogo comercial activo

-- Obtiene los productos activos con precio entre 10 y 50 euros, ordenados de mayor a menor precio
SELECT
       product_name AS producto, 
       ROUND(unit_price::numeric, 2) AS precio
FROM products
WHERE discontinued = 0 AND unit_price BETWEEN 10 AND 50
ORDER BY precio DESC;

-- Pregunta 2 — Concentración geográfica de la cartera

-- Cuenta clientes y ciudades distintas por país, filtrando aquellos con 5 o más clientes
SELECT
       country AS pais,
       COUNT(customer_id) AS num_clientes,
       COUNT(DISTINCT city) AS num_ciudades
FROM customers
GROUP BY country
HAVING COUNT(customer_id) >= 5
ORDER BY num_clientes DESC;

-- Pregunta 3 — Alerta de reposición

SELECT 
    product_name   AS producto, 
    units_in_stock AS stock, 
    reorder_level  AS nivel_reposicion, 
    units_on_order AS pedido_a_proveedor,
    CASE 
        WHEN units_in_stock = 0 THEN 'CRÍTICO' 
        ELSE 'AVISO' 
    END AS situacion
FROM 
    products
WHERE 
    discontinued = 0 
    AND units_in_stock <= reorder_level 
    AND units_in_stock IS NOT NULL 
    AND reorder_level IS NOT NULL;

-- Pregunta 4 — Ficha completa de producto

SELECT 
    p.product_name AS producto, 
    c.category_name AS categoria, 
    s.company_name AS proveedor, 
    s.country AS pais, 
    s.city AS ciudad
FROM products p
INNER JOIN categories c USING (category_id)
INNER JOIN suppliers s USING (supplier_id)
WHERE s.country IN ('Italy', 'France', 'Spain')
ORDER BY s.country ASC, p.product_name ASC;

-- Pregunta 5 — Detalle valorizado de un pedido

SELECT 
    c.company_name AS cliente, 
    o.order_date AS fecha_pedido, 
    p.product_name AS producto, 
    od.unit_price AS precio_unitario, 
    od.quantity AS cantidad, 
    od.discount AS descuento, 
    ROUND((od.unit_price::numeric) * od.quantity * (1 - od.discount::numeric), 2) AS importe_linea
FROM orders o
INNER JOIN customers c USING (customer_id)
INNER JOIN order_details od USING (order_id)
INNER JOIN products p USING (product_id)
WHERE o.order_id = 10248;

-- Pregunta 6 — Ranking de categorías por facturación

SELECT 
    c.category_name AS categoria, 
    COUNT(od.product_id) AS num_lineas, 
    COUNT(DISTINCT od.product_id) AS num_productos, 
    SUM(ROUND((od.unit_price::numeric) * od.quantity * (1 - od.discount::numeric), 2)) AS facturacion
FROM categories c
INNER JOIN products p USING (category_id)
INNER JOIN order_details od USING (product_id)
GROUP BY c.category_name
HAVING SUM(ROUND((od.unit_price::numeric) * od.quantity * (1 - od.discount::numeric), 2)) > 100000
ORDER BY facturacion DESC;

-- Pregunta 7 — Clientes sin actividad comercial

SELECT 
    c.company_name AS cliente, 
    c.country AS pais, 
    COUNT(o.order_id) AS num_pedidos, 
    COALESCE(MAX(o.order_date)::text, 'SIN PEDIDOS') AS ultimo_pedido
FROM customers c
LEFT JOIN orders o USING (customer_id)
GROUP BY c.company_name, c.country
ORDER BY num_pedidos ASC, c.company_name ASC;

-- Pregunta 8 — Organigrama de la fuerza de ventas

SELECT 
    e.first_name || ' ' || e.last_name AS empleado, 
    e.title AS cargo, 
    COALESCE(m.first_name || ' ' || m.last_name, 'DIRECCIÓN GENERAL') AS responsable, 
    m.title AS cargo_responsable
FROM employees e
LEFT JOIN employees m ON e.reports_to = m.employee_id;

-- Pregunta 9 — Rejilla de cobertura categoría × año

WITH anios AS (
    SELECT 1996 AS anio 
    UNION ALL 
    SELECT 1997 
    UNION ALL 
    SELECT 1998
),
ventas AS (
    SELECT 
        p.category_id, 
        EXTRACT(YEAR FROM o.order_date) AS anio, 
        SUM(ROUND((od.unit_price::numeric) * od.quantity * (1 - od.discount::numeric), 2)) AS total
    FROM orders o
    INNER JOIN order_details od USING (order_id)
    INNER JOIN products p USING (product_id)
    GROUP BY p.category_id, EXTRACT(YEAR FROM o.order_date)
)
SELECT 
    c.category_name AS categoria, 
    a.anio, 
    COALESCE(v.total, 0) AS facturacion
FROM 
    categories c
CROSS JOIN anios a
LEFT JOIN ventas v ON c.category_id = v.category_id AND a.anio = v.anio
ORDER BY categoria ASC, anio ASC;

-- Pregunta 10 — Mapa de países: clientes frente a proveedores

WITH clientes_pais AS (
    SELECT 
        country, 
        COUNT(customer_id) AS nc 
    FROM customers 
    GROUP BY country
),
proveedores_pais AS (
    SELECT 
        country, 
        COUNT(supplier_id) AS np 
    FROM suppliers 
    GROUP BY country
)
SELECT 
    COALESCE(c.country, p.country) AS pais,
    COALESCE(c.nc, 0) AS num_clientes, 
    COALESCE(p.np, 0) AS num_proveedores,
    CASE 
        WHEN c.nc IS NOT NULL AND p.np IS NOT NULL THEN 'AMBOS'
        WHEN c.nc IS NOT NULL THEN 'SOLO CLIENTES'
        ELSE 'SOLO PROVEEDORES' 
    END AS tipo_presencia
FROM clientes_pais c
FULL JOIN proveedores_pais p USING (country)
ORDER BY pais ASC;

-- Pregunta 11 — Directorio unificado de contactos

SELECT 'CLIENTE' AS origen, UPPER(contact_name) AS contacto, company_name AS organizacion, city AS ciudad, country AS pais FROM customers
UNION ALL
SELECT 'PROVEEDOR', UPPER(contact_name), company_name, city, country FROM suppliers
UNION ALL
SELECT 'EMPLEADO', UPPER(first_name || ' ' || last_name), 'NORTHWIND TRADERS', city, country FROM employees
ORDER BY origen ASC, pais ASC;

-- Pregunta 12 — Mercados con desequilibrio

-- a) Países donde hay clientes pero ningún proveedor
SELECT country AS pais 
FROM customers
EXCEPT
SELECT country 
FROM suppliers
ORDER BY pais ASC;

-- b) Países donde hay a la vez clientes y proveedores
SELECT country AS pais 
FROM customers
INTERSECT
SELECT country 
FROM suppliers
ORDER BY pais ASC;

-- Pregunta 13 — Clientes que nunca han comprado pescado

SELECT 
    c.company_name AS cliente, 
    c.country AS pais, 
    COUNT(o.order_id) AS pedidos_realizados
FROM customers c
LEFT JOIN orders o USING (customer_id)
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM orders o2 
        INNER JOIN order_details od USING (order_id) 
        INNER JOIN products p USING (product_id) 
        INNER JOIN categories cat USING (category_id)
        WHERE o2.customer_id = c.customer_id AND cat.category_name = 'Seafood'
    )
GROUP BY c.company_name, c.country
ORDER BY pedidos_realizados DESC;

-- Pregunta 14 — Productos por encima de la media

SELECT 
    product_name AS producto, 
    ROUND(unit_price::numeric, 2) AS precio,
    ROUND((SELECT AVG(unit_price)::numeric FROM products WHERE discontinued = 0), 2) AS precio_medio_catalogo,
    ROUND(unit_price::numeric - (SELECT AVG(unit_price)::numeric FROM products WHERE discontinued = 0), 2) AS diferencia
FROM products 
WHERE discontinued = 0 AND unit_price > (SELECT AVG(unit_price) FROM products WHERE discontinued = 0)
ORDER BY diferencia DESC;

-- Pregunta 15 — Ticket medio por cliente

SELECT 
    c.company_name AS cliente, 
    c.country AS pais, 
    COUNT(t.order_id) AS num_pedidos,
    SUM(t.total_pedido) AS importe_total, 
    ROUND(AVG(t.total_pedido), 2) AS ticket_medio
FROM customers c
INNER JOIN (
    SELECT 
        o.customer_id, 
        o.order_id, 
        SUM(ROUND((od.unit_price::numeric) * od.quantity * (1 - od.discount::numeric), 2)) AS total_pedido
    FROM orders o
    INNER JOIN order_details od USING (order_id)
    GROUP BY o.customer_id, o.order_id
) t USING (customer_id)
GROUP BY c.company_name, c.country
ORDER BY ticket_medio DESC
LIMIT 15;

-- Pregunta 16 — El producto más caro de cada categoría

SELECT 
    c.category_name AS categoria, 
    p.product_name AS producto, 
    ROUND(p.unit_price::numeric, 2) AS precio,
    ROUND((SELECT AVG(unit_price)::numeric FROM products p3 WHERE p3.category_id = p.category_id), 2) AS precio_medio_categoria
FROM products p
INNER JOIN categories c USING (category_id)
WHERE 
    p.unit_price = (
        SELECT MAX(unit_price) 
        FROM products p2 
        WHERE p2.category_id = p.category_id
    );

-- Pregunta 17 — Segmentación ABC de la cartera de clientes

WITH VentasClientes AS (
    SELECT o.customer_id, SUM(ROUND((od.unit_price::numeric) * od.quantity * (1 - od.discount::numeric), 2)) AS facturacion
    FROM orders o 
    INNER JOIN order_details od USING (order_id) 
    GROUP BY o.customer_id
),
Cuartiles AS (
    SELECT 
        customer_id, 
        facturacion, 
        NTILE(4) OVER (ORDER BY facturacion DESC) as cuartil 
    FROM VentasClientes
),
Segmentos AS (
    SELECT 
        customer_id,
        CASE cuartil 
            WHEN 1 THEN 'A - Estratégico' 
            WHEN 2 THEN 'B - Consolidado' 
            WHEN 3 THEN 'C - Ocasional' 
            WHEN 4 THEN 'D - Marginal' 
        END AS segmento, 
        facturacion 
    FROM Cuartiles
)
SELECT 
    segmento, 
    COUNT(customer_id) AS num_clientes, 
    SUM(facturacion) AS facturacion_segmento,
    ROUND(SUM(facturacion) / (SELECT SUM(facturacion) FROM Segmentos) * 100, 2) AS porcentaje_sobre_total
FROM Segmentos 
GROUP BY segmento 
ORDER BY segmento ASC;

-- Pregunta 18 — Los tres productos más vendidos de cada categoría

WITH VentasProd AS (
    SELECT 
        p.category_id, 
        p.product_id, 
        p.product_name AS producto, 
        SUM(od.quantity) AS unidades,
        SUM(ROUND((od.unit_price::numeric) * od.quantity * (1 - od.discount::numeric), 2)) AS facturacion
    FROM products p 
    INNER JOIN order_details od USING (product_id) 
    GROUP BY p.category_id, p.product_id, p.product_name
),
Rankings AS (
    SELECT 
        c.category_name AS categoria, 
        v.producto, 
        v.unidades, 
        v.facturacion,
        RANK() OVER (PARTITION BY v.category_id ORDER BY v.facturacion DESC) AS posicion_en_categoria,
        RANK() OVER (ORDER BY v.facturacion DESC) AS posicion_global
    FROM VentasProd v 
    INNER JOIN categories c USING (category_id)
)
SELECT 
    categoria, 
    posicion_en_categoria, 
    producto, 
    unidades, 
    facturacion, 
    posicion_global
FROM Rankings 
WHERE posicion_en_categoria <= 3 
ORDER BY categoria ASC, posicion_en_categoria ASC;

-- Pregunta 19 — Evolución mensual con acumulado y media móvil

WITH VentasMes AS (
    SELECT 
        DATE_TRUNC('month', o.order_date)::date AS mes,
        SUM(ROUND((od.unit_price::numeric) * od.quantity * (1 - od.discount::numeric), 2)) AS facturacion
    FROM orders o 
    INNER JOIN order_details od USING (order_id) 
    WHERE EXTRACT(YEAR FROM o.order_date) = 1997 
    GROUP BY DATE_TRUNC('month', o.order_date)::date
)
SELECT 
    mes, 
    facturacion,
    SUM(facturacion) OVER (ORDER BY mes) AS acumulado,
    ROUND(AVG(facturacion) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS media_movil_3m,
    LAG(facturacion) OVER (ORDER BY mes) AS mes_anterior,
    ROUND((facturacion - LAG(facturacion) OVER (ORDER BY mes)) / LAG(facturacion) OVER (ORDER BY mes) * 100, 2) AS variacion_pct
FROM VentasMes 
ORDER BY mes ASC;

-- Pregunta 20 — Cuadro de mando anual por categoría

WITH VentasCategoria AS (
    SELECT 
        c.category_name AS categoria,
        SUM(ROUND((od.unit_price::numeric) * od.quantity * (1 - od.discount::numeric), 2)) FILTER (WHERE EXTRACT(YEAR FROM o.order_date) = 1996) AS f_1996,
        SUM(ROUND((od.unit_price::numeric) * od.quantity * (1 - od.discount::numeric), 2)) FILTER (WHERE EXTRACT(YEAR FROM o.order_date) = 1997) AS f_1997,
        SUM(ROUND((od.unit_price::numeric) * od.quantity * (1 - od.discount::numeric), 2)) FILTER (WHERE EXTRACT(YEAR FROM o.order_date) = 1998) AS f_1998,
        SUM(ROUND((od.unit_price::numeric) * od.quantity * (1 - od.discount::numeric), 2)) AS total
    FROM categories c 
    INNER JOIN products p USING (category_id) 
    INNER JOIN order_details od USING (product_id) 
    INNER JOIN orders o USING (order_id)
    GROUP BY ROLLUP(c.category_name)
)
SELECT 
    COALESCE(categoria, 'TOTAL GENERAL') AS categoria,
    COALESCE(f_1996, 0) AS f_1996, 
    COALESCE(f_1997, 0) AS f_1997, 
    COALESCE(f_1998, 0) AS f_1998, 
    COALESCE(total, 0) AS total,
    ROUND(total / MAX(total) OVER () * 100, 2) AS peso_pct,
    CASE 
        WHEN categoria IS NULL THEN NULL
        WHEN f_1998 > f_1997 THEN 'CRECE'
        WHEN f_1998 < f_1997 THEN 'DECRECE'
        ELSE 'MANTIENE' 
    END AS tendencia
FROM VentasCategoria 
ORDER BY 
    CASE 
        WHEN categoria IS NULL THEN 1 
        ELSE 0 
    END, 
    total DESC;