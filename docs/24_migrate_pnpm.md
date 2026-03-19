# Guía de Migración de npm a pnpm

Esta guía detalla cómo identificar el gestor de paquetes actual, los pasos para migrar a `pnpm` y las consideraciones para el despliegue en plataformas como Vercel.

---

## 1. ¿Cómo saber si usas npm o pnpm?

Para determinar qué gestor se está utilizando en un módulo (`backend` o `front`), revisa la existencia de los siguientes archivos de bloqueo en la raíz de la carpeta:

| Gestor | Archivo de Bloqueo |
| :--- | :--- |
| **npm** | `package-lock.json` |
| **pnpm** | `pnpm-lock.yaml` |
| **yarn** | `yarn.lock` |

> [!NOTE]
> En este proyecto, tanto el `backend` como el `front` utilizan actualmente **npm** debido a la presencia de `package-lock.json`.

---

## 2. Pasos para Migrar de npm a pnpm

Sigue estos pasos dentro de cada carpeta (`backend/` y `front/`):

### Paso 1: Instalar pnpm (si no lo tienes)
Si aún no tienes `pnpm` instalado globalmente en tu máquina:
```powershell
npm install -g pnpm
```

### Paso 2: Generar el lockfile de pnpm
`pnpm` incluye una herramienta para importar las versiones exactas desde npm automáticamente:
```powershell
cd backend  # Repetir luego para front
pnpm import
```
*Esto creará el archivo `pnpm-lock.yaml` basado en tu `package-lock.json` actual.*

### Paso 3: Limpiar archivos antiguos
Elimina la carpeta de dependencias y el archivo de bloqueo de npm para evitar conflictos:
```powershell
# En Windows (PowerShell):
Remove-Item -Recurse -Force node_modules
Remove-Item package-lock.json
```

### Paso 4: Instalar dependencias con pnpm
```powershell
pnpm install
```

---

## 3. Funcionamiento en Vercel

Vercel tiene soporte nativo para `pnpm`. Al detectar un archivo `pnpm-lock.yaml` en la raíz de tu proyecto o subdirectorio, Vercel utilizará automáticamente `pnpm` para instalar las dependencias en lugar de `npm`.

### Consideraciones clave para Vercel:

1.  **Detección Automática**: No necesitas cambiar los comandos de "Build Command" o "Install Command" en la configuración de Vercel; la plataforma detecta el lockfile y ajusta el proceso de instalación.
2.  **Versión de pnpm**: Para asegurar que Vercel use la misma versión de `pnpm` que tú, es recomendable definirla en el `package.json` utilizando el campo `packageManager`:
    ```json
    "packageManager": "pnpm@8.15.4"
    ```
3.  **Corepack**: Si prefieres usar la versión de Node.js que viene con Corepack, puedes habilitarlo en Vercel mediante una variable de entorno `COREPACK_ENABLE_STRICT=0`, aunque normalmente no es necesario si el lockfile está presente.
4.  **Monorepos**: Si tu estructura es un monorepo real, asegúrate de configurar el "Root Directory" correctamente en Vercel para que encuentre el `pnpm-lock.yaml`.

---

## 4. Nuevos Comandos de Uso Diario

A partir de la migración, los comandos cambian ligeramente:

| Acción | Comando npm | Comando pnpm |
| :--- | :--- | :--- |
| Instalar todo | `npm install` | `pnpm i` |
| Añadir paquete | `npm install <pkg>` | `pnpm add <pkg>` |
| Script custom | `npm run dev` | `pnpm dev` (o `pnpm run dev`) |
| Ejecutar binario | `npx <cmd>` | `pnpm dlx <cmd>` |
