# Enfoque QR --- Arquitectura de Formularios de Mantención

## Objetivo

Extender la plataforma **Enfoque QR** para permitir **formularios
dinámicos de mantención, inspección y auditoría** asociados a equipos.\
Esto permite registrar checklists técnicos al escanear el QR del equipo
y mantener trazabilidad completa.

------------------------------------------------------------------------

# Principios de Diseño

-   Formularios **100% dinámicos**
-   Reutilizables entre múltiples equipos
-   Versionables
-   Independientes del tipo de mantención
-   Compatibles con múltiples industrias
-   Soporte para evidencias (fotos / firmas)

------------------------------------------------------------------------

# Stack Tecnológico

Frontend: Next.js (Vercel)\
Backend: NestJS (AWS)\
Base de datos: MySQL 8 (AWS RDS)

------------------------------------------------------------------------

# Arquitectura Conceptual

QR Scan ↓ Ficha pública del equipo ↓ Panel técnico ↓ Selección de acción

-   Realizar inspección
-   Realizar mantención
-   Ver historial
-   Ver documentos

↓

Formulario dinámico asociado al equipo

↓

Registro de ejecución

↓

Historial técnico

------------------------------------------------------------------------

# Modelo de Datos

## 1. maintenance_form_templates

Define plantillas reutilizables de formularios.

  campo         tipo
  ------------- ----------
  id            PK
  name          varchar
  description   text
  category      varchar
  version       int
  enabled       tinyint
  created_at    datetime

Ejemplos:

-   Mantención Motor Industrial
-   Inspección Eléctrica
-   Mantención Refrigerador
-   Auditoría Seguridad

------------------------------------------------------------------------

## 2. maintenance_form_fields

Define los campos del formulario.

  campo         tipo
  ------------- ---------
  id            PK
  form_id       FK
  label         varchar
  field_type    enum
  required      tinyint
  order_index   int
  options       json
  unit          varchar

Tipos de campo recomendados:

-   boolean
-   checkbox
-   text
-   number
-   select
-   date
-   photo
-   signature
-   rating

Ejemplo:

  label                   type      unit
  ----------------------- --------- ------
  Temperatura motor       number    °C
  Vibración               number    mm/s
  Lubricación realizada   boolean   
  Estado correa           select    
  Observaciones           text      

------------------------------------------------------------------------

## 3. device_types

Permite clasificar equipos.

  campo   tipo
  ------- ---------
  id      PK
  name    varchar

Ejemplo:

-   Motor
-   Compresor
-   Refrigerador
-   Generador
-   Bomba

------------------------------------------------------------------------

## 4. device_type_forms

Asocia formularios a tipos de equipos.

  campo            tipo
  ---------------- ------
  id               PK
  device_type_id   FK
  form_id          FK

Esto permite que **todos los equipos de un tipo hereden el mismo
checklist**.

------------------------------------------------------------------------

## 5. maintenance_executions

Representa una ejecución real del formulario.

  campo              tipo
  ------------------ ----------
  id                 PK
  device_id          FK
  form_id            FK
  performed_by       FK user
  status             enum
  created_at         datetime
  completed_at       datetime
  duration_minutes   int
  observations       text

------------------------------------------------------------------------

## 6. maintenance_execution_answers

Guarda las respuestas del formulario.

  campo          tipo
  -------------- ----------
  id             PK
  execution_id   FK
  field_id       FK
  value          text
  created_at     datetime

------------------------------------------------------------------------

# Flujo Operacional

## 1. Administrador

Crea formulario:

Mantención Motor Industrial

Campos:

-   Nivel de aceite
-   Vibración
-   Temperatura
-   Ajuste de tornillos
-   Foto estado motor
-   Observaciones

------------------------------------------------------------------------

## 2. Asociación

Formulario asociado a:

Tipo de equipo: Motor

------------------------------------------------------------------------

## 3. Escaneo QR

Técnico escanea QR del equipo.

Se abre ficha del equipo.

Opciones:

-   Ver información
-   Ver documentos
-   Realizar mantención
-   Ver historial

------------------------------------------------------------------------

## 4. Completar checklist

Ejemplo:

Nivel aceite: OK\
Vibración: 4.3 mm/s\
Temperatura: 62°C\
Foto: Adjunta\
Observación: revisar rodamiento

------------------------------------------------------------------------

## 5. Registro en historial

El sistema guarda:

-   equipo
-   formulario
-   técnico
-   respuestas
-   evidencia
-   fecha

Historial:

  fecha   técnico   tipo
  ------- --------- ------------
  16-03   Juan      Mantención
  02-02   Pedro     Inspección

------------------------------------------------------------------------

# Tipos de Formularios

Agregar campo:

form_type

Valores:

-   inspection
-   maintenance
-   audit

Esto permite distintos flujos.

------------------------------------------------------------------------

# Funcionalidades Avanzadas Recomendadas

## Frecuencia de mantención

Tabla:

device_maintenance_schedule

  campo            tipo
  ---------------- ------
  device_id        FK
  form_id          FK
  frequency_days   int

Ejemplo:

Refrigerador → cada 30 días

El sistema puede mostrar:

"Mantención vencida hace 5 días"

------------------------------------------------------------------------

## Evidencia técnica

Campos soportados:

-   fotos
-   firma técnico
-   firma cliente
-   ubicación GPS

------------------------------------------------------------------------

## Beneficios del sistema

Transforma Enfoque QR en:

-   Sistema de mantención industrial
-   Sistema de inspecciones
-   Plataforma de trazabilidad técnica
-   CMMS ligero basado en QR

------------------------------------------------------------------------

# Escalabilidad

El modelo permite:

-   miles de equipos
-   múltiples tipos de mantención
-   formularios versionables
-   integraciones futuras

Compatible con arquitectura:

NestJS modular MySQL relacional Next.js frontend dinámico

------------------------------------------------------------------------

# Roadmap sugerido

## MVP

-   Formularios dinámicos
-   Asociación a equipos
-   Registro de mantenciones
-   Historial

## v2

-   Fotos y firmas
-   Alertas de mantención
-   Reportes PDF

## v3

-   Analítica de mantenciones
-   Integraciones ERP
-   IoT / sensores

------------------------------------------------------------------------

Autor: Arquitectura propuesta para proyecto Enfoque QR
