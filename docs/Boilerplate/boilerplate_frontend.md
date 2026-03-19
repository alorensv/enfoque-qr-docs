# Boilerplate Frontend - Estándar UMine (Planificación Nueva App)

Este documento es el **template técnico oficial** para crear nuevas aplicaciones dentro del ecosistema **Enfoque QR**, alineado a la arquitectura **Next.js 14+ (App Router)** y **PWA**.

---

## 1. Estructura de Proyecto (pnpm workspaces)

```text
/
├── app/                  # App Router (Next.js 14+)
│   ├── layout.tsx        # Layout común (HTML, Body, Metadata)
│   ├── page.tsx          # Página principal (Server Component)
│   └── (dashboard)/      # Agrupación de rutas (auth, admin, etc.)
├── components/           # UI Atoms, Molecules, Organisms (Atomic Design)
├── contexts/             # Shell Cognitivo (AppProviders)
├── services/             # API Client, Analytics, S3 logic
├── hooks/                # Custom hooks (Client side only)
├── domain/               # Modelos de datos (TypeScript Interfaces)
└── public/               # Assets estáticos y PWA manifest
```

## 2. Shell Cognitivo (`AppProviders.tsx`)

```tsx
// contexts/AppProviders.tsx
'use client';

import { AuthProvider } from './AuthContext';
import { ThemeProvider } from './ThemeContext';
import { AnalyticsProvider } from './AnalyticsContext';

export function AppProviders({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider>
      <AnalyticsProvider>
        <AuthProvider>
          {children}
        </AuthProvider>
      </AnalyticsProvider>
    </ThemeProvider>
  );
}
```

## 3. Cliente HTTP (`api/http.ts`)

```typescript
// services/api/http.ts
import axios from 'axios';

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
  timeout: 10000,
});

api.interceptors.response.use(
  (res) => ({ ...res, data: res.data.data, meta: res.data.meta }), 
  (err) => Promise.reject(err.response?.data?.error || { message: 'Api Error' })
);

export default api;
```

## 4. Ejemplo de Página (Server Component + Client Component)

```tsx
// app/dashboard/page.tsx (Server Component)
import { getSummary } from '@/services/api/dashboard';
import DashboardChart from '@/components/organisms/DashboardChart';

export default async function DashboardPage() {
  // Fetch de datos en el Servidor (seguro y rápido)
  const stats = await getSummary();

  return (
    <main>
      <h1>Dashboard Operacional</h1>
      {/* Componente que necesita interactividad */}
      <DashboardChart data={stats} />
    </main>
  );
}
```

## 5. Configuración PWA (`next.config.js`)

```javascript
/** @type {import('next').NextConfig} */
const withPWA = require('next-pwa')({
  dest: 'public',
  disable: process.env.NODE_ENV === 'development',
});

module.exports = withPWA({
  reactStrictMode: true,
  // Otras configuraciones de Next.js
});
```

## 6. Manifest PWA (`public/manifest.json`)

```json
{
  "name": "Enfoque QR App",
  "short_name": "EnfoqueQR",
  "description": "Gestión inteligente de activos",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#0052cc",
  "icons": [
    { "src": "/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

---

## Reglas de Oro para nuevas apps:
1.  **TypeScript siempre**: No se permiten archivos `.js`.
2.  **pnpm install**: Único gestor de paquetes permitido.
3.  **Server Components por defecto**: Mantén el cliente liviano usando `'use client'` solo cuando sea estrictamente necesario.
4.  **Desacoplamiento total**: El frontend consume servicios, no conoce la base de datos ni lógica de infraestructura.
