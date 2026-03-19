# Dashboard de Indicadores Avanzados (Enfoque QR)

Este panel proporciona una visión estratégica y operativa de la institución, enfocándose en la trazabilidad de equipos y la eficiencia de los procesos.

## Indicadores Clave (KPIs)

El dashboard se organiza en cuatro pilares fundamentales:
1. **Equipos Totales**: El inventario completo de activos de la institución.
2. **Escaneos Totales**: Métrica de interacción real con los equipos a través de códigos QR.
3. **Cobertura de Documentación**: Cantidad de equipos que poseen manuales o certificados digitales (con porcentaje de avance).
4. **Cobertura de Mantenciones**: Equipos con registros de mantenimiento preventivo o correctivo (con porcentaje de avance).

## Secciones Especializadas

### 🏆 Ranking de Clientes (Top 5)
Visualización que lista a los 5 clientes con mayor volumen de equipos registrados. 
- Muestra el nombre del cliente y el conteo exacto de activos.
- Permite identificar rápidamente los clientes con mayor carga de gestión.

### 📊 Resumen General & Eficiencia
- **Usuarios y Clientes**: Conteos globales para control administrativo.
- **Eficiencia QR**: Se calcula como el total de escaneos dividido por el total de equipos (`Escaneos / Equipos`). Este indicador mide la adopción del sistema por parte de los usuarios.
- **Lógica de Cobertura**: Los porcentajes de Documentación y Mantención se calculan sobre la base de **equipos únicos**. Por ejemplo: si un equipo tiene 5 documentos cargados, contribuye como "1" al contador de equipos con documentación, evitando porcentajes superiores al 100%.

### 🚀 Próximos Pasos (Smart Suggestions)
Sugerencias automáticas basadas en el estado de la institución para incentivar la compleción de datos operativos.

## Implementación Técnica

### Backend (`AppService.getDashboardStats`)
- Utiliza **QueryBuilder** para realizar conteos distintos (`COUNT(DISTINCT ...)`) de equipos con documentos y mantenciones.
- Realiza agrupaciones (`GROUP BY`) y ordenamientos (`ORDER BY DESC`) para generar el ranking de clientes en una sola consulta.
- Garantiza la privacidad de datos mediante el filtrado constante por `institution_id`.

### Frontend (`AdminHome.js`)
- **Visualización de Progreso**: Las tarjetas de "Documentación" y "Mantención" incluyen barras de progreso integradas en la base.
- **Layout Adaptativo**: Las secciones se reorganizan dinámicamente según el tamaño de pantalla.
- **Estados de Carga**: Implementación de *skeletons* animados mientras se procesan las estadísticas.