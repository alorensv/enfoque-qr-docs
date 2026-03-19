
# Plan de implementación: Etiqueta QR para equipos

## Requerimiento
Se requiere crear una etiqueta para imprimir y pegar a los equipos, con un diseño similar al modelo ubicado en `docs/image.png`.

En la sección de equipos, se debe crear una nueva acción **Descargar etiqueta** y generar la funcionalidad para crear la etiqueta con:
- Código QR del equipo
- Nombre del equipo
- Número de serie
- Logo de la institución (por ahora, logo por defecto: `Logo-Lortech.png`)

La idea es poder imprimir hasta 2 etiquetas de manera horizontal en una hoja carta.

---

## Plan de trabajo
1. **Agregar botón "Descargar etiqueta"**
	- Ubicar el botón en la página de detalle de equipo en el frontend (Next.js).

2. **Crear componente de etiqueta**
	- Componente React que reciba los datos del equipo y renderice la etiqueta según el diseño de `image.png`.
	- Incluir el QR, nombre, número de serie y logo (usar el logo por defecto, moverlo a `/front/public` si es necesario).

3. **Generar imagen PNG de la etiqueta**
	- Usar una librería como `html2canvas` para convertir el componente a PNG.
	- Permitir descargar la imagen generada.

4. **Diseño para impresión múltiple**
	- Permitir seleccionar cuántas etiquetas imprimir (hasta 2 por hoja carta, en horizontal).
	- Ajustar el layout para que al imprimir desde el navegador, se acomoden dos etiquetas por hoja.

5. **Pruebas y ajustes**
	- Verificar que el diseño sea fiel al modelo y que la descarga/impresión funcione correctamente.

---

## Notas
- El logo por defecto debe estar disponible en la carpeta `public` del frontend para ser referenciado fácilmente.
- La descarga será en formato PNG.
- Si se requiere, se puede agregar la opción de descarga en PDF en el futuro.