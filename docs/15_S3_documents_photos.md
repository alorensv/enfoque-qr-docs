# Migración de Archivos a AWS S3 - Plan de Implementación

## 📋 Resumen Ejecutivo

**Objetivo:** Migrar todos los archivos estáticos (fotos, documentos, imágenes QR) desde almacenamiento local (`/public`) a AWS S3 para mejorar escalabilidad, disponibilidad y gestión de archivos.

**Alcance:** 
- ✅ Fotos de equipos
- ✅ Documentos de equipos
- ✅ Fotos de mantenciones
- ✅ Documentos de mantenciones
- ✅ Imágenes de códigos QR

**Impacto estimado:** Alto - Requiere cambios en 5 servicios principales y migración de archivos existentes.

---

## 1️⃣ ANÁLISIS DEL ESTADO ACTUAL

### 1.1 Estructura de Archivos Actual

```
public/
├── equipos/
│   ├── {equipmentId}/
│   │   ├── foto_equipo/          # Fotos del equipo
│   │   │   └── {timestamp}-{filename}.jpg
│   │   ├── documentos/           # Documentos del equipo
│   │   │   └── {timestamp}-{filename}.pdf
│   │   ├── qr/                   # Imágenes QR
│   │   │   └── qr_{token}.png
│   │   └── mantenciones/
│   │       └── {maintenanceId}/
│   │           ├── fotos/        # Fotos de la mantención
│   │           │   └── {timestamp}-{filename}.jpg
│   │           └── documentos/   # Documentos de la mantención
│   │               └── {timestamp}-{filename}.pdf
└── tmp/                          # Archivos temporales de uploads
```

### 1.2 Archivos Involucrados

| Archivo | Función | Líneas clave |
|---------|---------|--------------|
| `equipment.service.ts` | Maneja fotos y documentos de equipos | L74-91, L104-130 |
| `maintenances.service.ts` | Maneja fotos y documentos de mantenciones | L191-310 |
| `qr.service.ts` | Genera y almacena imágenes QR | L35-50, L150-167 |
| `maintenance.storage.ts` | Configuración de Multer para mantenciones | L5-18 |
| `equipment.controller.ts` | Endpoints de upload | L95-148, L195-243 |
| `maintenances.controller.ts` | Endpoints de upload | L106-163 |

### 1.3 Base de Datos - Campos Afectados

**Tabla `equipment`:**
- `equipmentPhoto` VARCHAR(300) - Ruta de la foto

**Tabla `equipment_document`:**
- `filePath` VARCHAR(300) - Ruta del documento

**Tabla `equipment_qr_code`:**
- `imagenPath` VARCHAR(300) - Ruta de la imagen QR

**Tabla `equipment_maintenance_photo`:**
- `filePath` VARCHAR(300) - Ruta de la foto

**Tabla `equipment_maintenance_document`:**
- `filePath` VARCHAR(300) - Ruta del documento

---

## 2️⃣ CONFIGURACIÓN DE AWS S3

### 2.1 Crear Bucket en AWS

1. **Acceder a AWS Console:**
   ```
   https://console.aws.amazon.com/s3/
   ```

2. **Crear nuevo bucket:** ✅ COMPLETADO
   - Click "Create bucket"
   - **Bucket name:** `enfoque-qr-files`
   - **Region:** `us-east-1` (EE.UU. Este - Norte de Virginia)
   - **Tipo de bucket:** Uso general
   - **ACL:** Deshabilitadas (recomendado)
   - **Block Public Access:** Configuración personalizada:
     - ❌ Bloquear acceso público vía nuevas ACL: OFF
     - ❌ Bloquear acceso público vía cualquier ACL: OFF
     - ✅ Bloquear acceso público vía nuevas políticas de bucket: ON
     - ✅ Bloquear acceso público vía cualquier política de bucket: ON
   - **Bucket Versioning:** Desactivado
   - **Encryption:** SSE-S3 (cifrado con claves administradas por Amazon)
   - **Clave de bucket:** Desactivada
   - Click "Create bucket"

   > **⚠️ DECISIÓN DE SEGURIDAD:** El bucket NO tiene acceso público.
   > Todos los archivos (incluidos QR) se sirven mediante **pre-signed URLs**
   > generadas por el backend. Esto previene abuso por bots y costos inesperados.
   > El backend actúa como "portero": solo usuarios autenticados obtienen URLs temporales.

3. **Configurar CORS:** ⏳ PENDIENTE
   - Ir a bucket → Permissions → CORS
   - Agregar configuración:
   ```json
   [
     {
       "AllowedHeaders": ["*"],
       "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
       "AllowedOrigins": ["*"],
       "ExposeHeaders": ["ETag"],
       "MaxAgeSeconds": 3000
     }
   ]
   ```

   > **Nota:** No se necesita Bucket Policy pública. Todos los archivos se
   > sirven con pre-signed URLs desde el backend.

### 2.2 Crear Usuario IAM ✅ COMPLETADO

**Usuario creado:**
- **Username:** `enfoque-qr-backend`
- **ARN:** `arn:aws:iam::600627341091:user/enfoque-qr-backend`
- **Access Key ID:** `AKIAYXWBN44R4G2OFPYL`

1. **Acceder a IAM:**
   ```
   https://console.aws.amazon.com/iam/
   ```

2. **Crear usuario:**
   - Users → Add users
   - **Username:** `enfoque-qr-backend`
   - **Access type:** Programmatic access
   - Click "Next"

3. **Asignar permisos:**
   - Attach policies → Create policy
   - JSON:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:PutObject",
           "s3:GetObject",
           "s3:DeleteObject",
           "s3:ListBucket"
         ],
         "Resource": [
           "arn:aws:s3:::enfoque-qr-files",
           "arn:aws:s3:::enfoque-qr-files/*"
         ]
       }
     ]
   }
   ```
   - Nombre de política: `EnfoqueQR-S3-Access`
   - Asignar política al usuario

4. **Guardar credenciales:**
   - ⚠️ **CRÍTICO:** Guardar Access Key ID y Secret Access Key
   - Estas credenciales solo se muestran una vez

### 2.3 Variables de Entorno

Agregar al archivo `.env`:

```bash
# AWS S3 Configuration
AWS_ACCESS_KEY_ID=AKIA******************
AWS_SECRET_ACCESS_KEY=****************************************
AWS_REGION=us-east-1
AWS_S3_BUCKET=enfoque-qr-files

# Feature flag para activar S3 (permite rollback fácil)
USE_S3_STORAGE=true

# Configuración de uploads
MAX_FILE_SIZE=10485760  # 10MB en bytes
ALLOWED_IMAGE_TYPES=image/jpeg,image/png,image/jpg
ALLOWED_DOCUMENT_TYPES=application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document
```

---

## 3️⃣ IMPLEMENTACIÓN - FASE 1: DEPENDENCIAS

### 3.1 Instalar AWS SDK

```bash
cd backend
npm install @aws-sdk/client-s3 @aws-sdk/lib-storage
npm install --save-dev @types/multer
```

### 3.2 Actualizar package.json

Agregar a `backend/package.json`:
```json
{
  "dependencies": {
    "@aws-sdk/client-s3": "^3.470.0",
    "@aws-sdk/lib-storage": "^3.470.0"
  }
}
```

---

## 4️⃣ IMPLEMENTACIÓN - FASE 2: SERVICIO S3

### 4.1 Crear Servicio S3

**Archivo:** `backend/src/core/services/s3.service.ts`

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { S3Client, PutObjectCommand, DeleteObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { Upload } from '@aws-sdk/lib-storage';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import * as fs from 'fs';
import * as path from 'path';

export interface S3UploadResult {
  key: string;
  url: string;
  bucket: string;
}

@Injectable()
export class S3Service {
  private readonly s3Client: S3Client;
  private readonly bucket: string;
  private readonly region: string;
  private readonly logger = new Logger(S3Service.name);
  private readonly useS3: boolean;

  constructor() {
    this.useS3 = process.env.USE_S3_STORAGE === 'true';
    this.bucket = process.env.AWS_S3_BUCKET || 'enfoque-qr-files';
    this.region = process.env.AWS_REGION || 'us-east-1';

    if (this.useS3) {
      this.s3Client = new S3Client({
        region: this.region,
        credentials: {
          accessKeyId: process.env.AWS_ACCESS_KEY_ID,
          secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
        },
      });
      this.logger.log(`S3 Service initialized - Bucket: ${this.bucket}, Region: ${this.region}`);
    } else {
      this.logger.warn('S3 Service disabled - Using local storage');
    }
  }

  /**
   * Verifica si S3 está activo
   */
  isS3Enabled(): boolean {
    return this.useS3;
  }

  /**
   * Sube un archivo desde buffer a S3
   */
  async uploadFromBuffer(
    buffer: Buffer,
    key: string,
    contentType: string,
  ): Promise<S3UploadResult> {
    if (!this.useS3) {
      throw new Error('S3 is disabled. Enable USE_S3_STORAGE in environment variables.');
    }

    try {
      const upload = new Upload({
        client: this.s3Client,
        params: {
          Bucket: this.bucket,
          Key: key,
          Body: buffer,
          ContentType: contentType,
        },
      });

      await upload.done();

      const url = await this.getSignedUrl(key, 3600); // 1 hora de expiración

      this.logger.log(`File uploaded: ${key}`);

      return {
        key,
        url,
        bucket: this.bucket,
      };
    } catch (error) {
      this.logger.error(`Error uploading file to S3: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * Sube un archivo desde disco local a S3
   */
  async uploadFromFile(
    filePath: string,
    key: string,
    contentType: string,
  ): Promise<S3UploadResult> {
    if (!this.useS3) {
      throw new Error('S3 is disabled. Enable USE_S3_STORAGE in environment variables.');
    }

    try {
      const fileStream = fs.createReadStream(filePath);
      const stats = fs.statSync(filePath);

      const upload = new Upload({
        client: this.s3Client,
        params: {
          Bucket: this.bucket,
          Key: key,
          Body: fileStream,
          ContentType: contentType,
          ContentLength: stats.size,
        },
      });

      await upload.done();

      const url = await this.getSignedUrl(key, 3600);

      this.logger.log(`File uploaded: ${key} (${stats.size} bytes)`);

      return {
        key,
        url,
        bucket: this.bucket,
      };
    } catch (error) {
      this.logger.error(`Error uploading file to S3: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * Elimina un archivo de S3
   */
  async deleteFile(key: string): Promise<void> {
    if (!this.useS3) {
      throw new Error('S3 is disabled.');
    }

    try {
      const command = new DeleteObjectCommand({
        Bucket: this.bucket,
        Key: key,
      });

      await this.s3Client.send(command);
      this.logger.log(`File deleted: ${key}`);
    } catch (error) {
      this.logger.error(`Error deleting file from S3: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * Genera URL firmada para acceso temporal a archivos
   * Todos los archivos usan pre-signed URLs (bucket privado)
   */
  async getSignedUrl(key: string, expiresIn: number = 3600): Promise<string> {
    if (!this.useS3) {
      throw new Error('S3 is disabled.');
    }

    try {
      const command = new GetObjectCommand({
        Bucket: this.bucket,
        Key: key,
      });

      return await getSignedUrl(this.s3Client, command, { expiresIn });
    } catch (error) {
      this.logger.error(`Error generating signed URL: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * Construye la key (path) para un archivo en S3
   */
  buildKey(category: string, ...parts: string[]): string {
    return path.posix.join(category, ...parts);
  }

}
```

### 4.2 Actualizar CoreModule

**Archivo:** `backend/src/core/core.module.ts`

```typescript
import { Module, Global } from '@nestjs/common';
import { LoggerService } from './services/logger.service';
import { SlugService } from './services/slug.service';
import { S3Service } from './services/s3.service';

@Global()
@Module({
  providers: [LoggerService, SlugService, S3Service],
  exports: [LoggerService, SlugService, S3Service],
})
export class CoreModule {}
```

---

## 5️⃣ IMPLEMENTACIÓN - FASE 3: MIGRAR SERVICIOS

### 5.1 Equipment Service

**Archivo:** `backend/src/equipment/equipment.service.ts`

**Cambios necesarios:**

1. **Inyectar S3Service:**
```typescript
constructor(
  @InjectRepository(Equipment)
  private readonly equipmentRepository: Repository<Equipment>,
  @InjectRepository(EquipmentDocument)
  private readonly documentRepository: Repository<EquipmentDocument>,
  @InjectRepository(EquipmentQrCode)
  private readonly equipmentQrCodeRepository: Repository<EquipmentQrCode>,
  @Inject(forwardRef(() => QrService))
  private readonly qrService: QrService,
  private readonly s3Service: S3Service, // NUEVO
) {}
```

2. **Modificar método `create()` para fotos:**
```typescript
// Reemplazar líneas 74-89
if (equipmentPhotoFile) {
  if (this.s3Service.isS3Enabled()) {
    // Subir a S3
    const key = this.s3Service.buildKey(
      'equipos',
      String(equipmentId),
      'foto_equipo',
      equipmentPhotoFile.filename
    );
    
    const result = await this.s3Service.uploadFromFile(
      equipmentPhotoFile.path,
      key,
      equipmentPhotoFile.mimetype,
    );
    
    savedEquipo.equipmentPhoto = result.key;
    
    // Eliminar archivo temporal
    fs.unlinkSync(equipmentPhotoFile.path);
  } else {
    // Lógica local existente
    const finalDir = path.join(process.cwd(), 'public', 'equipos', String(equipmentId), 'foto_equipo');
    if (!fs.existsSync(finalDir)) fs.mkdirSync(finalDir, { recursive: true });
    
    const finalPath = path.join(finalDir, equipmentPhotoFile.filename);
    const tempPath = equipmentPhotoFile.path;
    fs.renameSync(tempPath, finalPath);
    
    savedEquipo.equipmentPhoto = `/equipos/${equipmentId}/foto_equipo/${equipmentPhotoFile.filename}`;
  }
  
  await this.equipmentRepository.save(savedEquipo);
}
```

3. **Modificar método `addDocument()`:**
```typescript
// Reemplazar líneas 104-130
if (this.s3Service.isS3Enabled()) {
  // Subir a S3
  const key = this.s3Service.buildKey(
    'equipos',
    String(equipmentId),
    'documentos',
    file.filename
  );
  
  const result = await this.s3Service.uploadFromFile(
    file.path,
    key,
    file.mimetype,
  );
  
  // Eliminar archivo temporal
  fs.unlinkSync(file.path);
  
  const doc = this.documentRepository.create({
    equipmentId,
    name: body.name || file.originalname,
    originalName: file.originalname,
    type: body.type || file.mimetype,
    filePath: result.key, // Guardar la key de S3
    userId: body.userId,
    isPrivate: isPrivateValue,
  });
  
  return this.documentRepository.save(doc);
} else {
  // Lógica local existente
  const finalDir = path.join(process.cwd(), 'public', 'equipos', String(equipmentId), 'documentos');
  if (!fs.existsSync(finalDir)) fs.mkdirSync(finalDir, { recursive: true });
  
  const finalPath = path.join(finalDir, file.filename);
  fs.renameSync(file.path, finalPath);
  
  const relPath = `/equipos/${equipmentId}/documentos/${file.filename}`;
  const isPrivateValue = parseInt(String(body.isPrivate || '0'), 10);
  
  const doc = this.documentRepository.create({
    equipmentId,
    name: body.name || file.originalname,
    originalName: file.originalname,
    type: body.type || file.mimetype,
    filePath: relPath,
    userId: body.userId,
    isPrivate: isPrivateValue,
  });
  
  return this.documentRepository.save(doc);
}
```

### 5.2 Maintenances Service

**Archivo:** `backend/src/maintenances/maintenances.service.ts`

**Cambios necesarios:**

1. **Inyectar S3Service:**
```typescript
constructor(
  @InjectRepository(EquipmentMaintenance)
  private readonly maintenanceRepo: Repository<EquipmentMaintenance>,
  @InjectRepository(EquipmentMaintenancePhoto)
  private readonly photoRepo: Repository<EquipmentMaintenancePhoto>,
  @InjectRepository(EquipmentMaintenanceDocument)
  private readonly documentRepo: Repository<EquipmentMaintenanceDocument>,
  private readonly maintenanceLogService: MaintenanceLogService,
  private readonly logger: LoggerService,
  private readonly s3Service: S3Service, // NUEVO
) {}
```

2. **Modificar método `uploadPhotos()`:**
```typescript
// Reemplazar líneas 191-250 aproximadamente
async uploadPhotos(id: number, files: MulterFile[], userId?: string | number) {
  try {
    const maintenance = await this.maintenanceRepo.findOne({
      where: { id, deletedAt: IsNull() },
    });
    
    if (!maintenance) {
      throw new HttpException('Mantención no encontrada', HttpStatus.NOT_FOUND);
    }
    
    const equipmentId = maintenance.equipmentId;
    const photos = [];
    
    for (const file of files) {
      try {
        if (this.s3Service.isS3Enabled()) {
          // Subir a S3
          const key = this.s3Service.buildKey(
            'equipos',
            String(equipmentId),
            'mantenciones',
            String(id),
            'fotos',
            file.filename
          );
          
          const result = await this.s3Service.uploadFromFile(
            file.path,
            key,
            file.mimetype,
          );
          
          // Eliminar archivo temporal
          fs.unlinkSync(file.path);
          
          const photo = this.photoRepo.create({
            maintenanceId: id,
            filePath: result.key,
            uploadedAt: new Date(),
          });
          
          const saved = await this.photoRepo.save(photo);
          photos.push(saved);
        } else {
          // Lógica local existente
          const finalDir = path.join(
            process.cwd(),
            'public',
            'equipos',
            String(equipmentId),
            'mantenciones',
            String(id),
            'fotos'
          );
          
          if (!fs.existsSync(finalDir)) {
            fs.mkdirSync(finalDir, { recursive: true });
          }
          
          const finalPath = path.join(finalDir, file.filename);
          fs.renameSync(file.path, finalPath);
          
          const relativePath = `/equipos/${equipmentId}/mantenciones/${id}/fotos/${file.filename}`;
          
          const photo = this.photoRepo.create({
            maintenanceId: id,
            filePath: relativePath,
            uploadedAt: new Date(),
          });
          
          const saved = await this.photoRepo.save(photo);
          photos.push(saved);
        }
      } catch (fileError) {
        this.logger.error(
          `Error al procesar foto ${file.filename}: ${fileError.message}`,
          fileError.stack,
          'MaintenancesService'
        );
      }
    }
    
    // Registrar log
    if (photos.length > 0 && userId) {
      await this.maintenanceLogService.createLog(
        String(id),
        String(userId),
        'FOTO_AGREGADA',
        `Se agregaron ${photos.length} foto(s).`
      );
    }
    
    return photos;
  } catch (error) {
    this.logger.error(
      `Error al subir fotos: ${error.message}`,
      error.stack,
      'MaintenancesService'
    );
    throw error;
  }
}
```

3. **Modificar método `uploadDocuments()` de forma similar**

### 5.3 QR Service

**Archivo:** `backend/src/qr/qr.service.ts`

**Cambios necesarios:**

1. **Inyectar S3Service:**
```typescript
constructor(
  @InjectRepository(EquipmentQrCode)
  private qrRepository: Repository<EquipmentQrCode>,
  private readonly s3Service: S3Service, // NUEVO
) {}
```

2. **Modificar método `createWithImage()`:**
```typescript
// Reemplazar líneas 35-55 aproximadamente
async createWithImage(token: string, equipmentId: number): Promise<EquipmentQrCode> {
  const urlPublica = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/qr/${token}`;
  
  if (this.s3Service.isS3Enabled()) {
    // Generar QR en buffer
    const qrBuffer = await QRCode.toBuffer(urlPublica, { width: 400 });
    
    // Subir a S3
    const fileName = `qr_${token}.png`;
    const key = this.s3Service.buildKey('qr', fileName);
    
    const result = await this.s3Service.uploadFromBuffer(
      qrBuffer,
      key,
      'image/png',
    );
    
    const qrCode = this.qrRepository.create({
      token,
      equipmentId,
      imagenPath: result.key,
      createdAt: new Date(),
      enabled: 1,
    });
    
    return this.qrRepository.save(qrCode);
  } else {
    // Lógica local existente
    const qrDir = path.join(process.cwd(), 'public', 'equipos', String(equipmentId), 'qr');
    if (!fs.existsSync(qrDir)) fs.mkdirSync(qrDir, { recursive: true });
    
    const fileName = `qr_${token}.png`;
    const filePath = path.join(qrDir, fileName);
    await QRCode.toFile(filePath, urlPublica, { width: 400 });
    
    const imagenPath = `/equipos/${equipmentId}/qr/${fileName}`;
    
    const qrCode = this.qrRepository.create({
      token,
      equipmentId,
      imagenPath,
      createdAt: new Date(),
      enabled: 1,
    });
    
    return this.qrRepository.save(qrCode);
  }
}
```

---

## 6️⃣ IMPLEMENTACIÓN - FASE 4: CONTROLADORES

### 6.1 Equipment Controller

**Archivo:** `backend/src/equipment/equipment.controller.ts`

**Modificar método `downloadDocument()`:**

```typescript
@Get('documents/:docId/download')
@ApiOperation({ summary: 'Descargar documento de equipo' })
@ApiParam({ name: 'docId', description: 'ID del documento' })
@ApiResponse({ status: 200, description: 'Archivo descargado' })
@ApiResponse({ status: 404, description: 'Documento no encontrado' })
async downloadDocument(@Param('docId') docId: string, @Res() res: Response) {
  const numId = parseInt(docId, 10);
  if (isNaN(numId)) throw new NotFoundException('ID de documento inválido');
  
  const doc = await this.equipmentDocumentRepository.findOne({ 
    where: { id: numId, deletedAt: null } 
  });
  
  if (!doc) throw new NotFoundException('Documento no encontrado');
  
  // Verificar si es S3 o local
  if (doc.filePath.startsWith('equipos/')) {
    // Es una key de S3
    const s3Service = this.equipmentService['s3Service']; // Obtener del service
    
    // Generar URL firmada temporal (bucket privado, todo vía pre-signed URLs)
    const expiresIn = doc.isPrivate === 1 ? 300 : 3600; // 5 min privados, 1h no-privados
    const signedUrl = await s3Service.getSignedUrl(doc.filePath, expiresIn);
    return res.redirect(signedUrl);
  } else {
    // Es ruta local (backward compatibility)
    const path = require('path');
    const fs = require('fs');
    const filePath = path.join(process.cwd(), 'public', doc.filePath);
    
    if (fs.existsSync(filePath)) {
      res.download(filePath, doc.originalName || doc.name);
    } else {
      throw new NotFoundException('Archivo no encontrado en el servidor');
    }
  }
}
```

### 6.2 QR Controller

**Archivo:** `backend/src/qr/qr.controller.ts`

**Modificar método `downloadImage()`:**

```typescript
@Get(':token/image')
@ApiOperation({ summary: 'Descargar imagen del código QR (público)' })
@ApiParam({ name: 'token', description: 'Token del código QR' })
@ApiResponse({ status: 200, description: 'Imagen PNG del código QR' })
@ApiResponse({ status: 404, description: 'Imagen no encontrada' })
async downloadImage(@Param('token') token: string, @Res() res: Response) {
  const qr = await this.qrService.findByToken(token);
  
  if (!qr || !qr.imagenPath) {
    throw new NotFoundException('Imagen QR no encontrada');
  }
  
  // Verificar si es S3 o local
  if (qr.imagenPath.startsWith('qr/')) {
    // Es una key de S3 - generar URL firmada temporal (24h para QR)
    const s3Service = this.qrService['s3Service'];
    const signedUrl = await s3Service.getSignedUrl(qr.imagenPath, 86400);
    return res.redirect(signedUrl);
  } else {
    // Es ruta local (backward compatibility)
    const filePath = path.join(process.cwd(), 'public', qr.imagenPath);
    
    if (!fs.existsSync(filePath)) {
      throw new NotFoundException('Archivo de imagen no existe');
    }
    
    res.sendFile(filePath);
  }
}
```

---

## 7️⃣ SCRIPT DE MIGRACIÓN DE ARCHIVOS EXISTENTES

### 7.1 Script de Migración

**Archivo:** `backend/scripts/migrate-to-s3.ts`

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { S3Service } from '../src/core/services/s3.service';
import { Repository } from 'typeorm';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Equipment } from '../src/equipment/entities/equipment.entity';
import { EquipmentDocument } from '../src/equipment/entities/equipment-document.entity';
import { EquipmentQrCode } from '../src/qr/entities/equipment-qr-code.entity';
import { EquipmentMaintenancePhoto } from '../src/maintenances/entities/equipment-maintenance-photo.entity';
import { EquipmentMaintenanceDocument } from '../src/maintenances/entities/equipment-maintenance-document.entity';
import * as fs from 'fs';
import * as path from 'path';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const s3Service = app.get(S3Service);
  
  console.log('🚀 Iniciando migración a S3...\n');
  
  // 1. Migrar fotos de equipos
  console.log('📷 Migrando fotos de equipos...');
  const equipmentRepo = app.get<Repository<Equipment>>(getRepositoryToken(Equipment));
  const equipments = await equipmentRepo.find({ where: { deletedAt: null } });
  
  let migratedEquipmentPhotos = 0;
  for (const equipment of equipments) {
    if (equipment.equipmentPhoto && equipment.equipmentPhoto.startsWith('/')) {
      try {
        const localPath = path.join(process.cwd(), 'public', equipment.equipmentPhoto);
        
        if (fs.existsSync(localPath)) {
          const fileName = path.basename(equipment.equipmentPhoto);
          const key = s3Service.buildKey('equipos', String(equipment.id), 'foto_equipo', fileName);
          
          const result = await s3Service.uploadFromFile(
            localPath,
            key,
            'image/jpeg',
          );
          
          equipment.equipmentPhoto = result.key;
          await equipmentRepo.save(equipment);
          
          migratedEquipmentPhotos++;
          console.log(`  ✅ Equipo ${equipment.id}: ${fileName}`);
        }
      } catch (error) {
        console.error(`  ❌ Error en equipo ${equipment.id}: ${error.message}`);
      }
    }
  }
  console.log(`✅ Fotos de equipos migradas: ${migratedEquipmentPhotos}/${equipments.length}\n`);
  
  // 2. Migrar documentos de equipos
  console.log('📄 Migrando documentos de equipos...');
  const docRepo = app.get<Repository<EquipmentDocument>>(getRepositoryToken(EquipmentDocument));
  const documents = await docRepo.find({ where: { deletedAt: null } });
  
  let migratedDocs = 0;
  for (const doc of documents) {
    if (doc.filePath && doc.filePath.startsWith('/')) {
      try {
        const localPath = path.join(process.cwd(), 'public', doc.filePath);
        
        if (fs.existsSync(localPath)) {
          const fileName = path.basename(doc.filePath);
          const key = s3Service.buildKey('equipos', String(doc.equipmentId), 'documentos', fileName);
          
          const result = await s3Service.uploadFromFile(
            localPath,
            key,
            doc.type || 'application/pdf',
          );
          
          doc.filePath = result.key;
          await docRepo.save(doc);
          
          migratedDocs++;
          console.log(`  ✅ Documento ${doc.id}: ${fileName}`);
        }
      } catch (error) {
        console.error(`  ❌ Error en documento ${doc.id}: ${error.message}`);
      }
    }
  }
  console.log(`✅ Documentos de equipos migrados: ${migratedDocs}/${documents.length}\n`);
  
  // 3. Migrar imágenes QR
  console.log('🔲 Migrando códigos QR...');
  const qrRepo = app.get<Repository<EquipmentQrCode>>(getRepositoryToken(EquipmentQrCode));
  const qrCodes = await qrRepo.find({ where: { deletedAt: null } });
  
  let migratedQRs = 0;
  for (const qr of qrCodes) {
    if (qr.imagenPath && qr.imagenPath.startsWith('/')) {
      try {
        const localPath = path.join(process.cwd(), 'public', qr.imagenPath);
        
        if (fs.existsSync(localPath)) {
          const fileName = path.basename(qr.imagenPath);
          const key = s3Service.buildKey('qr', fileName);
          
          const result = await s3Service.uploadFromFile(
            localPath,
            key,
            'image/png',
          );
          
          qr.imagenPath = result.key;
          await qrRepo.save(qr);
          
          migratedQRs++;
          console.log(`  ✅ QR ${qr.id}: ${fileName}`);
        }
      } catch (error) {
        console.error(`  ❌ Error en QR ${qr.id}: ${error.message}`);
      }
    }
  }
  console.log(`✅ Códigos QR migrados: ${migratedQRs}/${qrCodes.length}\n`);
  
  // 4. Migrar fotos de mantenciones
  console.log('📸 Migrando fotos de mantenciones...');
  const photoRepo = app.get<Repository<EquipmentMaintenancePhoto>>(getRepositoryToken(EquipmentMaintenancePhoto));
  const photos = await photoRepo.find();
  
  let migratedPhotos = 0;
  for (const photo of photos) {
    if (photo.filePath && photo.filePath.startsWith('/')) {
      try {
        const localPath = path.join(process.cwd(), 'public', photo.filePath);
        
        if (fs.existsSync(localPath)) {
          const parts = photo.filePath.split('/');
          const equipmentId = parts[2];
          const maintenanceId = parts[4];
          const fileName = path.basename(photo.filePath);
          
          const key = s3Service.buildKey('equipos', equipmentId, 'mantenciones', maintenanceId, 'fotos', fileName);
          
          const result = await s3Service.uploadFromFile(
            localPath,
            key,
            'image/jpeg',
          );
          
          photo.filePath = result.key;
          await photoRepo.save(photo);
          
          migratedPhotos++;
          console.log(`  ✅ Foto mantención ${photo.id}: ${fileName}`);
        }
      } catch (error) {
        console.error(`  ❌ Error en foto mantención ${photo.id}: ${error.message}`);
      }
    }
  }
  console.log(`✅ Fotos de mantenciones migradas: ${migratedPhotos}/${photos.length}\n`);
  
  // 5. Migrar documentos de mantenciones
  console.log('📋 Migrando documentos de mantenciones...');
  const maintenanceDocRepo = app.get<Repository<EquipmentMaintenanceDocument>>(getRepositoryToken(EquipmentMaintenanceDocument));
  const maintenanceDocs = await maintenanceDocRepo.find();
  
  let migratedMaintenanceDocs = 0;
  for (const doc of maintenanceDocs) {
    if (doc.filePath && doc.filePath.startsWith('/')) {
      try {
        const localPath = path.join(process.cwd(), 'public', doc.filePath);
        
        if (fs.existsSync(localPath)) {
          const parts = doc.filePath.split('/');
          const equipmentId = parts[2];
          const maintenanceId = parts[4];
          const fileName = path.basename(doc.filePath);
          
          const key = s3Service.buildKey('equipos', equipmentId, 'mantenciones', maintenanceId, 'documentos', fileName);
          
          const result = await s3Service.uploadFromFile(
            localPath,
            key,
            'application/pdf',
          );
          
          doc.filePath = result.key;
          await maintenanceDocRepo.save(doc);
          
          migratedMaintenanceDocs++;
          console.log(`  ✅ Documento mantención ${doc.id}: ${fileName}`);
        }
      } catch (error) {
        console.error(`  ❌ Error en documento mantención ${doc.id}: ${error.message}`);
      }
    }
  }
  console.log(`✅ Documentos de mantenciones migrados: ${migratedMaintenanceDocs}/${maintenanceDocs.length}\n`);
  
  // Resumen
  console.log('📊 RESUMEN DE MIGRACIÓN:');
  console.log(`   Fotos de equipos: ${migratedEquipmentPhotos}`);
  console.log(`   Documentos de equipos: ${migratedDocs}`);
  console.log(`   Códigos QR: ${migratedQRs}`);
  console.log(`   Fotos de mantenciones: ${migratedPhotos}`);
  console.log(`   Documentos de mantenciones: ${migratedMaintenanceDocs}`);
  console.log(`\n✅ Migración completada!\n`);
  
  await app.close();
}

bootstrap().catch(error => {
  console.error('❌ Error en la migración:', error);
  process.exit(1);
});
```

### 7.2 Agregar script a package.json

```json
{
  "scripts": {
    "migrate:s3": "ts-node backend/scripts/migrate-to-s3.ts"
  }
}
```

---

## 8️⃣ PLAN DE EJECUCIÓN

### Fase 1: Preparación (1 día)
- [ ] Crear bucket S3 en AWS
- [ ] Configurar usuario IAM con permisos
- [ ] Agregar variables de entorno al `.env`
- [ ] Instalar dependencias AWS SDK
- [ ] Crear S3Service

### Fase 2: Desarrollo (2-3 días)
- [ ] Actualizar EquipmentService
- [ ] Actualizar MaintenancesService
- [ ] Actualizar QRService
- [ ] Actualizar controllers
- [ ] Testing en desarrollo

### Fase 3: Testing (1 día)
- [ ] Probar uploads con S3 habilitado
- [ ] Probar downloads con pre-signed URLs
- [ ] Probar descarga de QR vía pre-signed URL
- [ ] Verificar URLs firmadas con diferentes expiraciones
- [ ] Testing de rollback (desactivar S3)

### Fase 4: Migración de Datos (2-4 horas)
- [ ] Backup completo de la carpeta `public/`
- [ ] Backup de la base de datos
- [ ] Ejecutar script de migración en ambiente de prueba
- [ ] Verificar migración exitosa
- [ ] Ejecutar script en producción
- [ ] Verificar integridad de datos

### Fase 5: Despliegue (1 día)
- [ ] Activar `USE_S3_STORAGE=true` en producción
- [ ] Monitorear logs por 24h
- [ ] Verificar funcionalidad end-to-end
- [ ] Eliminar archivos locales antiguos (opcional)

---

## 9️⃣ TESTING

### 9.1 Test Cases

| Test Case | Descripción | Resultado Esperado |
|-----------|-------------|-------------------|
| TC-01 | Subir foto de equipo | Archivo en S3, key guardada en BD |
| TC-02 | Subir documento de equipo | Archivo en S3, key guardada en BD |
| TC-03 | Descargar documento | Pre-signed URL temporal funciona |
| TC-04 | Generar código QR | Imagen en S3, servida vía pre-signed URL (24h) |
| TC-05 | Escanear QR desde móvil | Imagen QR se carga correctamente vía URL firmada |
| TC-06 | Subir múltiples fotos mantención | Todas las fotos en S3 |
| TC-07 | Rollback S3 (USE_S3_STORAGE=false) | Sistema funciona con storage local |
| TC-08 | Eliminar equipo | Archivos NO se eliminan de S3 (soft delete) |
| TC-09 | URL firmada expirada | Retorna error 403, backend genera nueva URL |

### 9.2 Script de Testing

**Archivo:** `backend/test/s3-integration.test.ts`

```typescript
import { Test } from '@nestjs/testing';
import { S3Service } from '../src/core/services/s3.service';
import * as fs from 'fs';
import * as path from 'path';

describe('S3 Integration Tests', () => {
  let s3Service: S3Service;
  
  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      providers: [S3Service],
    }).compile();
    
    s3Service = moduleRef.get<S3Service>(S3Service);
  });
  
  it('should upload a file to S3', async () => {
    const testBuffer = Buffer.from('test file content');
    const key = 'test/test-file.txt';
    
    const result = await s3Service.uploadFromBuffer(
      testBuffer,
      key,
      'text/plain',
    );
    
    expect(result.key).toBe(key);
    expect(result.url).toContain('s3');
  });
  
  it('should generate signed URL for private files', async () => {
    const key = 'test/private-file.txt';
    const url = await s3Service.getSignedUrl(key, 300);
    
    expect(url).toContain('X-Amz-Signature');
    expect(url).toContain('X-Amz-Expires=300');
  });
  
  it('should delete a file from S3', async () => {
    const key = 'test/test-file.txt';
    
    await expect(s3Service.deleteFile(key)).resolves.not.toThrow();
  });
});
```

---

## 🔟 ROLLBACK PLAN

### Escenario 1: Problemas durante desarrollo
**Acción:** Simplemente no activar `USE_S3_STORAGE` en producción.

### Escenario 2: Problemas después de migración
**Pasos:**
1. Cambiar `.env`: `USE_S3_STORAGE=false`
2. Reiniciar aplicación
3. El sistema volverá a usar storage local
4. Los archivos locales aún existen (no se eliminaron)

### Escenario 3: Recuperación de archivos desde S3
```bash
# Descargar todo el bucket
aws s3 sync s3://enfoque-qr-files ./backup-s3 --region us-east-1

# Restaurar a carpeta public/
cp -r ./backup-s3/equipos ./public/
cp -r ./backup-s3/qr ./public/
```

---

## 1️⃣1️⃣ MONITOREO Y MÉTRICAS

### CloudWatch Metrics
- Número de requests a S3
- Bytes transferidos
- Latencia de uploads/downloads
- Errores 4xx y 5xx

### Application Logs
```typescript
// Agregar a LoggerService
logS3Operation(operation: string, key: string, duration: number, success: boolean) {
  const message = `S3 ${operation}: ${key} - ${duration}ms - ${success ? 'SUCCESS' : 'FAILED'}`;
  this.log(message, 'S3Service');
}
```

---

## 1️⃣2️⃣ COSTOS ESTIMADOS AWS S3

### Calculadora de Costos

**Asunciones:**
- 1000 equipos
- 5 fotos por equipo (2MB c/u) = 10GB
- 10 documentos por equipo (500KB c/u) = 5GB
- 1000 códigos QR (50KB c/u) = 50MB
- **Total almacenamiento:** ~15GB

**Costo mensual (us-east-1):**
- Almacenamiento: 15GB × $0.023/GB = **$0.35/mes**
- Requests GET: 10,000 × $0.0004/1000 = **$0.004/mes**
- Requests PUT: 1,000 × $0.005/1000 = **$0.005/mes**
- Transferencia datos: 5GB × $0 (primeros 100GB gratis) = **$0/mes**

**Total estimado: ~$0.36/mes** (primeros 12 meses en Free Tier = $0)

---

## 1️⃣3️⃣ OPTIMIZACIONES FUTURAS

### CDN con CloudFront
- Cachear archivos públicos (QR, fotos)
- Reducir latencia global
- Reducir costos de transferencia

### Compresión de Imágenes
- Implementar Sharp para redimensionar imágenes
- Generar thumbnails automáticamente
- Reducir uso de almacenamiento

### Lifecycle Policies
- Mover archivos antiguos a S3 Glacier (más barato)
- Eliminar archivos de equipos eliminados después de X días

### Pre-signed URLs con Caché
- Cachear URLs firmadas por 1 hora
- Reducir llamadas a AWS SDK

---

## 1️⃣4️⃣ CHECKLIST FINAL

### Pre-Deployment
- [ ] Bucket S3 creado y configurado
- [ ] Usuario IAM con permisos correctos
- [ ] Variables de entorno configuradas
- [ ] Código actualizado y testeado
- [ ] Script de migración probado en desarrollo
- [ ] Backup completo de `public/` y base de datos
- [ ] Documentación actualizada

### Deployment
- [ ] Deploy de código nuevo
- [ ] Ejecutar script de migración
- [ ] Activar `USE_S3_STORAGE=true`
- [ ] Verificar logs por errores
- [ ] Testing end-to-end

### Post-Deployment
- [ ] Monitorear métricas CloudWatch por 7 días
- [ ] Verificar costos AWS
- [ ] Solicitar feedback de usuarios
- [ ] Documentar lecciones aprendidas
- [ ] (Opcional) Eliminar archivos locales después de 30 días

---

## 📞 CONTACTOS Y RECURSOS

### AWS Support
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [AWS SDK for JavaScript v3](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/)
- [S3 Pricing Calculator](https://calculator.aws/)

### Interno
- DevOps: [contacto]
- Backend Lead: [contacto]
- AWS Account Owner: [contacto]

---

**Última actualización:** 9 de marzo de 2026  
**Versión:** 1.0  
**Autor:** GitHub Copilot
