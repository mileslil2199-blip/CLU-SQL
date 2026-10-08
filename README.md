# CLU-SQL

Repositorio de utilidades, diagnósticos y automatizaciones SQL Server.

## Propósito

Mantener scripts reutilizables y versionados para administración, diagnóstico, rendimiento, alta disponibilidad, seguridad y reportería. Este repositorio no debe contener código de productos como CLUGESTOR.

## Estructura

- `sql/administration/` — administración y mantenimiento.
- `sql/performance/` — waits, bloqueos, CPU, memoria, I/O y tuning.
- `sql/always-on/` — Always On Availability Groups.
- `sql/security/` — seguridad, permisos y auditoría.
- `sql/reporting/` — consultas y utilidades de reportería.
- `scripts/` — PowerShell u otras automatizaciones DBA.
- `docs/` — documentación técnica y procedimientos.

## Flujo Git

- `main`: versión estable.
- `dev`: integración de cambios.
- `feature/*`: cambios puntuales.

No subir contraseñas, cadenas de conexión, secretos, respaldos, datos personales ni archivos de configuración sensibles.
