## Autenticación JWT Enfoque QR

### Flujo general
1. El usuario ingresa su email y contraseña en el formulario de la landing (Next.js).
2. El front envía una petición POST a `/auth/login` del backend (NestJS) con las credenciales.
3. El backend valida las credenciales, y si son correctas, responde con un JWT (`access_token`).
4. El front almacena el JWT en `localStorage` y lo usa en el header `Authorization: Bearer <token>` para acceder a rutas protegidas.
5. El backend protege rutas usando `@UseGuards(AuthGuard('jwt'))` y solo permite acceso a usuarios autenticados.

### Ejemplo de login desde el front
```js
const res = await fetch('http://localhost:3001/auth/login', {
	method: 'POST',
	headers: { 'Content-Type': 'application/json' },
	body: JSON.stringify({ email, password })
});
const data = await res.json();
localStorage.setItem('token', data.access_token);
```

### Ejemplo de acceso a ruta protegida
```js
const token = localStorage.getItem('token');
const res = await fetch('http://localhost:3001/hello', {
	headers: { 'Authorization': `Bearer ${token}` }
});
```

### Seguridad
- Contraseñas hasheadas con bcryptjs.
- JWT firmado y con expiración.
- Principios SOLID y clean code en backend.

### Troubleshooting y tips
- Si el login falla, asegúrate de que el hash bcrypt en la base de datos fue generado correctamente para la clave deseada.
- El campo password debe ser VARCHAR(60) o mayor.
- El campo estado debe ser 1 y el email debe coincidir exactamente.
- Puedes generar un hash bcrypt en Docker así:

```sh
docker run --rm -v /ruta/absoluta/backend:/app -w /app node:20-alpine sh -c "npm install bcryptjs && node -e \"const bcrypt = require('bcryptjs'); bcrypt.hash('tu_clave', 10, (err, hash) => { if (err) throw err; console.log(hash); });\""
```
Reemplaza /ruta/absoluta/backend por la ruta real y tu_clave por la contraseña deseada.