\## Pregunta 1 — Catálogo comercial activo



\*\*Enunciado:\*\* Obtén los productos que no están descatalogados y cuyo precio unitario esté entre 10 y 50 euros, ambos incluidos. Muestra el nombre del producto y su precio redondeado a dos decimales, ordenado de mayor a menor precio.



\*\*Consulta:\*\*



```sql

\-- Obtiene los productos activos con precio entre 10 y 50 euros, ordenados de mayor a menor precio

SELECT product\_name AS producto, 

&#x20;      ROUND(unit\_price::numeric, 2) AS precio

FROM products

WHERE discontinued = 0 

&#x20; AND unit\_price BETWEEN 10 AND 50

ORDER BY precio DESC;

```



\## Pregunta 2 — Concentración geográfica de la cartera



\*\*Enunciado:\*\* Dirección quiere saber en qué mercados está realmente concentrada la base de clientes antes de decidir dónde abrir delegación. Cuenta cuántos clientes hay en cada país y muestra únicamente aquellos países con 5 o más clientes, ordenados de mayor a menor. Indica también cuántas ciudades distintas hay en cada uno de esos países.



\*\*Consulta:\*\*



```sql

\-- Cuenta clientes y ciudades distintas por país, filtrando aquellos con 5 o más clientes

SELECT country AS pais,

&#x20;      COUNT(customer\_id) AS num\_clientes,

&#x20;      COUNT(DISTINCT city) AS num\_ciudades

FROM customers

GROUP BY country

HAVING COUNT(customer\_id) >= 5

ORDER BY num\_clientes DESC;





