USE AdministracionBD;
GO
/***********************************************************************************************
AUTOR:          Camilo Davila González
FECHA:          2025-10-24
MODO:           SQL EXPERTO SINARE
CASO/TICKET:    #017535
DESCRIPCIÓN:    Actualiza el correo asociado a una cuenta existente en Seguridad.Cuenta
                 y su contacto vinculado en Persona.PersonaContacto.
DEPENDENCIAS:   Seguridad.Cuenta, Persona.PersonaContacto
REGLAS:
 - La cuenta actual (origen) debe existir y estar activa.
 - La cuenta nueva (destino) NO debe existir activa.
 - Si ambas validaciones son correctas, se actualizan los registros de correo.
 - Si alguna falla, se detiene el proceso y se revierte la transacción.
***********************************************************************************************/

SET NOCOUNT ON;  
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

DECLARE 
    @IdCuentaOrigen INT,
    @IdCuentaDestino INT,
    @CuentaActual VARCHAR(150) = 'ariel-1296@homail.com',
    @CuentaNueva  VARCHAR(150) = 'abogadoarielgonzalez@gmail.com',
    @Tiquete INT = 17535;

BEGIN TRY
    BEGIN TRAN;
    -------------------------------------------------------------------------------------------
    -- 1 VALIDAR EXISTENCIA DE LA CUENTA ACTUAL (ORIGEN)
    -------------------------------------------------------------------------------------------
    SELECT @IdCuentaOrigen = IdCuenta
    FROM Seguridad.Cuenta WITH (ROWLOCK, UPDLOCK)
    WHERE Nombre = @CuentaActual
      --AND EstaActivo = 1;

    IF @IdCuentaOrigen IS NULL
    BEGIN
        RAISERROR('No se encontró la cuenta original activa: %s', 16, 1, @CuentaActual);
        ROLLBACK TRAN;
        RETURN;
    END;

    -------------------------------------------------------------------------------------------
    -- 2 VALIDAR QUE LA CUENTA NUEVA (DESTINO) NO EXISTA ACTIVA
    -------------------------------------------------------------------------------------------
    SELECT @IdCuentaDestino = IdCuenta
    FROM Seguridad.Cuenta WITH (ROWLOCK, UPDLOCK)
    WHERE Nombre = @CuentaNueva
      AND EstaActivo = 1;

    IF @IdCuentaDestino IS NOT NULL
    BEGIN
        RAISERROR('No se puede proceder: ya existe una cuenta activa con el nuevo correo: %s', 16, 1, @CuentaNueva);
        ROLLBACK TRAN;
        RETURN;
    END;

    -------------------------------------------------------------------------------------------
    -- 3 ACTUALIZAR CORREO EN SEGURIDAD.CUENTA
    -------------------------------------------------------------------------------------------
    UPDATE Seguridad.Cuenta WITH (ROWLOCK)
    SET Nombre = @CuentaNueva,
        IdUsuarioModificacion = 0,
        FechaModificacion = GETDATE(),
        Descripcion = CONCAT(
            ISNULL(Descripcion, ''),
            ' | Cambio correo tck:', @Tiquete, 
            ' [', @CuentaActual, ' -> ', @CuentaNueva, ']'
        )
    WHERE IdCuenta = @IdCuentaOrigen;

    -------------------------------------------------------------------------------------------
    -- 4 ACTUALIZAR CORREO EN PERSONA.PERSONACONTACTO
    -------------------------------------------------------------------------------------------
    UPDATE Persona.PersonaContacto WITH (ROWLOCK)
    SET ValorContacto = @CuentaNueva,
        Observacion = CONCAT(
            ISNULL(Observacion, ''),
            ' | Cambio correo tck:', @Tiquete, 
            ' [', @CuentaActual, ' -> ', @CuentaNueva, ']'
        ),
        IdUsuarioModificacion = 0,
        FechaModificacion = GETDATE()
    WHERE IdCuentaVinculada = @IdCuentaOrigen
      AND IdNivelContacto = 20
      AND EstaActivo = 1;

    -------------------------------------------------------------------------------------------
    -- 5 CONFIRMAR CAMBIOS
    -------------------------------------------------------------------------------------------
    COMMIT TRAN;

    PRINT 'CAMBIO EXITOSO';
    PRINT '   Cuenta original: ' + @CuentaActual;
    PRINT '   Nuevo correo:    ' + @CuentaNueva;
    PRINT '   Ticket:          ' + CAST(@Tiquete AS VARCHAR(10));
    PRINT '   Fecha ejecución: ' + CONVERT(VARCHAR(19), GETDATE(), 120);

END TRY
BEGIN CATCH
    -------------------------------------------------------------------------------------------
    -- 6 CONTROL DE ERRORES Y REVERSIÓN SEGURA
    -------------------------------------------------------------------------------------------
    DECLARE 
        @CodigoError INT = ERROR_NUMBER(),
        @MensajeError NVARCHAR(2050) = ERROR_MESSAGE();

    IF @@TRANCOUNT > 0 ROLLBACK TRAN;

    PRINT 'ERROR DURANTE LA EJECUCIÓN';
    PRINT CONCAT('Código: ', @CodigoError, ' - Mensaje: ', @MensajeError);

    -- Registro opcional en bitácora de errores centralizada
    -- EXEC pa_LogError 'AdministracionBD', 'Actualizar correo cuenta SINARE', @MensajeError, @CodigoError;
END CATCH;
GO

SET NOCOUNT OFF;  
