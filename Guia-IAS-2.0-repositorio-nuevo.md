# Guía de IAS 2.0: usar Skills en un repositorio nuevo

IAS permite seleccionar y gestionar Skills por repositorio. La fuente de Skills son exclusivamente los plugins locales de:

```text
%USERPROFILE%\.ias\plugins
```

Cada repositorio mantiene su propia selección en `.ias\project.json`. IAS instala las Skills seleccionadas en las carpetas locales de Claude y Cursor del repositorio.

> **Importante:** ejecuta los comandos desde la raíz del repositorio que quieras gestionar. IAS utiliza el directorio actual como proyecto.

---

## 1. Comprobar que IAS está instalado

Abre Windows PowerShell 5.1 y ejecuta:

```powershell
Get-Command ias -All
ias
```

El comando `ias` debe resolverse como una aplicación `ias.cmd` ubicada en:

```text
%USERPROFILE%\.ias\bin\ias.cmd
```

Comprueba que IAS reconoce tus plugins:

```powershell
ias plugins
```

Para reconstruir el índice local de plugins:

```powershell
ias catalog update
```

Este comando vuelve a leer las carpetas de `%USERPROFILE%\.ias\plugins` y genera el índice local. **No descarga ni actualiza los plugins** y no utiliza el catálogo global de MobiAI como fuente de Skills.

Para ver todas las Skills:

```powershell
ias list
```

Para filtrar por plugin:

```powershell
ias list android
ias list general-mobile
ias list ios
```

---

## 2. Entrar en el repositorio nuevo

En PowerShell, cambia a la carpeta raíz del repositorio. Por ejemplo:

```powershell
cd "C:\ruta\de\tu\repositorio"
```

Comprueba que estás en el sitio correcto:

```powershell
Get-Location
```

Los archivos de configuración de IAS se crearán dentro de este repositorio, en `.ias`.

---

## 3. Revisar las Skills disponibles

Antes de seleccionar, puedes consultar el catálogo:

```powershell
ias list
```

Cada Skill se identifica con el formato:

```text
plugin/skill
```

Por ejemplo:

```text
android/adaptive
general-mobile/mobiai-brain
general-mobile/mobiai-graph
supabase/supabase
```

El identificador compuesto permite distinguir Skills que pudieran tener el mismo nombre en plugins diferentes.

---

## 4. Seleccionar las Skills para este repositorio

Ejecuta:

```powershell
ias select
```

IAS mostrará una lista numerada. Introduce los números separados por comas:

```text
1,3,7,12
```

También puedes escribir:

- `all`: seleccionar todas las Skills que aparecen en esa lista.
- `q`: cancelar sin guardar cambios.

Las Skills que ya estaban seleccionadas aparecen marcadas con `[x]`.

### Seleccionar un único plugin

También puedes limitar el selector a un plugin:

```powershell
ias select android
```

Cuando seleccionas por plugin, IAS conserva las selecciones de los demás plugins y sustituye la selección correspondiente al plugin indicado.

La selección se guarda en:

```text
.ias\project.json
```

**Nota:** al seleccionar sin indicar plugin, la selección introducida sustituye la selección completa del repositorio. Revisa los elementos marcados antes de guardar.

---

## 5. Instalar la selección en el repositorio

Una vez guardada la selección, ejecuta:

```powershell
ias install
```

IAS copia las Skills seleccionadas y no ignoradas a estas ubicaciones:

```text
.claude\skills\<nombre-de-skill>\
.cursor\skills\<nombre-de-skill>\
```

Por ejemplo:

```text
tu-repositorio\
├── .ias\
│   └── project.json
├── .claude\
│   └── skills\
│       ├── adaptive\
│       └── mobiai-brain\
└── .cursor\
    └── skills\
        ├── adaptive\
        └── mobiai-brain\
```

IAS mantiene un registro de las copias que gestiona en:

```text
.ias\managed.json
```

### Protección de carpetas existentes

Si ya existe una carpeta de Skill en el destino y no está registrada como gestionada por IAS, IAS la protege y no la sobrescribe.

Si necesitas incorporar una instalación anterior, consulta el apartado **Adoptar Skills existentes**.

---

## 6. Comprobar el estado del repositorio

Ejecuta:

```powershell
ias status
```

IAS muestra las Skills seleccionadas y si están registradas e instaladas en Claude y Cursor.

Para volver a consultar la selección y las etiquetas del catálogo:

```powershell
ias list
```

---

## 7. Adoptar Skills que ya estaban instaladas

Si antes de usar IAS ya tenías Skills en `.claude\skills` o `.cursor\skills`, puedes intentar registrarlas:

```powershell
ias adopt
```

IAS compara el contenido de cada carpeta existente con la Skill original del plugin mediante hashes SHA-256.

- Si el contenido es idéntico, la registra como gestionada.
- Si no coincide, no la adopta ni modifica la carpeta.
- No adopta Skills que no estén seleccionadas o que estén ignoradas.

Después puedes comprobar el resultado:

```powershell
ias status
```

---

## 8. Actualizar las Skills del repositorio

Cuando quieras actualizar el entorno del proyecto, ejecuta desde su raíz:

```powershell
ias update
```

IAS realiza dos fases:

1. Comprueba que `~\.mobiai\state\installed.json` existe y que no contiene packs globales registrados. Después ejecuta `mobiai update`. Si falla alguna comprobación o el comando devuelve un error, IAS detiene la operación.
2. Actualiza únicamente las Skills seleccionadas, no ignoradas y que IAS ya tenga registradas como gestionadas en el repositorio.

**`ias update` no instala por primera vez una Skill.** Para instalar una selección nueva utiliza `ias install`.

Antes de reemplazar una Skill gestionada, IAS guarda una copia de seguridad dentro de:

```text
.ias\backups\
```

Por tanto, el flujo habitual después de la configuración inicial es:

```powershell
ias update
ias status
```

---

## 9. Ignorar y restaurar Skills

Las exclusiones son globales para IAS, no solo para el repositorio actual.

### Ver las Skills ignoradas

```powershell
ias ignore
```

### Ignorar una Skill

Utiliza el identificador completo:

```powershell
ias ignore android/adaptive
```

Una Skill ignorada se omite en las selecciones disponibles y en las operaciones de instalación o actualización. Ignorarla **no borra las copias que ya existan** en los repositorios.

### Dejar de ignorar una Skill

```powershell
ias unignore android/adaptive
```

Después de quitar la exclusión, la Skill vuelve a estar disponible. Si todavía no está instalada en el repositorio, ejecuta `ias install`.

---

## 10. Archivos que IAS crea en cada repositorio

```text
tu-repositorio\
├── .ias\
│   ├── project.json    # Selección de Skills de este repositorio
│   ├── managed.json    # Registro de Skills gestionadas por IAS
│   └── backups\        # Copias previas a las actualizaciones
├── .claude\
│   └── skills\         # Skills instaladas para Claude en este repo
└── .cursor\
    └── skills\         # Skills instaladas para Cursor en este repo
```

La carpeta global `%USERPROFILE%\.ias\plugins` es la fuente original de los plugins. IAS no debe modificarla al instalar o actualizar Skills de un repositorio.

Si compartes el repositorio con otras personas, revisa qué elementos de `.ias`, `.claude` y `.cursor` quieres incluir en el control de versiones según las convenciones de tu equipo.

---

## 11. Flujo recomendado para un repositorio nuevo

Copia esta secuencia como referencia:

```powershell
# 1. Ir a la raíz del repositorio
cd "C:\ruta\de\tu\repositorio"

# 2. Ver las Skills disponibles
ias list

# 3. Seleccionar las Skills para este proyecto
ias select

# 4. Instalar la selección en Claude y Cursor
ias install

# 5. Comprobar el estado
ias status
```

En el trabajo diario:

```powershell
cd "C:\ruta\de\tu\repositorio"
ias update
ias status
```

---

## 12. Comandos de referencia

| Comando | Función |
|---|---|
| `ias` | Muestra la ayuda |
| `ias plugins` | Resume los plugins locales y el número de Skills |
| `ias list` | Lista las Skills disponibles y sus estados |
| `ias list <plugin>` | Lista las Skills de un plugin |
| `ias catalog update` | Reconstruye el índice local de plugins |
| `ias select` | Selecciona Skills para el repositorio actual |
| `ias select <plugin>` | Selecciona Skills de un plugin, conservando la selección de los demás |
| `ias install` | Instala la selección en Claude y Cursor del repositorio |
| `ias adopt` | Registra instalaciones existentes si su contenido coincide exactamente |
| `ias update` | Actualiza MobiAI y las Skills seleccionadas que IAS ya gestiona |
| `ias status` | Muestra el estado de la selección y de las instalaciones |
| `ias ignore` | Muestra las Skills ignoradas globalmente |
| `ias ignore <plugin/skill>` | Ignora una Skill globalmente |
| `ias unignore <plugin/skill>` | Quita la exclusión global de una Skill |

---

## 13. Precauciones

- Ejecuta `ias select`, `ias install`, `ias adopt`, `ias update` e `ias status` desde la raíz del repositorio correcto.
- Usa siempre identificadores `plugin/skill` al ignorar o restaurar Skills.
- Ejecuta `ias install` para una primera instalación; `ias update` está pensado para actualizar copias que IAS ya gestiona.
- No borres manualmente `.ias\managed.json` si quieres que IAS siga reconociendo qué carpetas administra.
- `ias ignore` no elimina copias existentes.
- `ias update` requiere que `mobiai update` pueda ejecutarse y que el estado de packs globales de MobiAI pase la comprobación de seguridad.
- Las copias de seguridad de las Skills actualizadas se guardan en `.ias\backups`.
