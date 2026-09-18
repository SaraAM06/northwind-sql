## Pregunta 1 — Catálogo comercial activo

**Enunciado:** Obtén los productos que no están descatalogados y cuyo precio unitario esté entre 10 y 50 euros, ambos incluidos. Muestra el nombre del producto y su precio redondeado a dos decimales, ordenado de mayor a menor precio.

**Consulta:**

```sql
-- Obtiene los productos activos con precio entre 10 y 50 euros, ordenados de mayor a menor precio
SELECT product_name AS producto, 
       ROUND(unit_price::numeric, 2) AS precio
FROM products
WHERE discontinued = 0 
  AND unit_price BETWEEN 10 AND 50
ORDER BY precio DESC;
```

## Pregunta 2 — Concentración geográfica de la cartera

**Enunciado:** Dirección quiere saber en qué mercados está realmente concentrada la base de clientes antes de decidir dónde abrir delegación. Cuenta cuántos clientes hay en cada país y muestra únicamente aquellos países con **5 o más clientes**, ordenados de mayor a menor. Indica también cuántas ciudades distintas hay en cada uno de esos países.

**Consulta:**

```sql
-- Cuenta clientes y ciudades distintas por país, filtrando aquellos con 5 o más clientes
SELECT country AS pais,
       COUNT(customer_id) AS num_clientes,
       COUNT(DISTINCT city) AS num_ciudades
FROM customers
GROUP BY country
HAVING COUNT(customer_id) >= 5
ORDER BY num_clientes DESC;
```
# Pregunta 3 — Alerta de reposición

**Enunciado:** Logística necesita detectar qué referencias están en riesgo de rotura de stock. Localiza los productos activos cuyas unidades en stock sean **inferiores o iguales** a su nivel de reposición. Muestra el nombre, las unidades en stock, el nivel de reposición, las unidades ya pedidas al proveedor y una columna de texto que indique `'CRÍTICO'` cuando el stock sea 0 y `'AVISO'` en el resto de casos.

**Consulta:**

```sql
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
```



