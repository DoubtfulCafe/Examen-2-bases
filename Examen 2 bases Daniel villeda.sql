--Desarrolle un trigger que se active antes de eliminar un artista de la tabla artistas. Este trigger debe eliminar
--automáticamente todas las canciones asociadas con ese artista en la tabla canciones. Además, debe ajustar
--cualquier otra tabla relacionada según sea necesario para mantener la integridad referencial de los datos

CREATE OR REPLACE TRIGGER eliminar_canciones_artista
BEFORE DELETE ON artistas
FOR EACH ROW
BEGIN
    DELETE FROM canciones
    WHERE id_artista = :OLD.id_artista;
END;
/




-- artista de prueba
INSERT INTO artistas (id_artista, nombre, nacionalidad, fecha_nacimiento)
VALUES (66, 'Artista de Prueba', 'Nacionalidad de Prueba', TO_DATE('2000-10-06', 'YYYY-MM-DD'));

-- Canciones del artista


INSERT INTO canciones (
    id_cancion,
    id_artista,
    id_grupo,
    id_genero,
    titulo,
    duracion_segundos,
    genero,
    letra,
    cantidad_reproducciones
) VALUES (
    57,
    66,
    2,
    2,
    'Canción 2 prueba',
    180,
    null,
    'una letra mouy hermosa',
    0
);

INSERT INTO canciones (
    id_cancion,
    id_artista,
    id_grupo,
    id_genero,
    titulo,
    duracion_segundos,
    genero,
    letra,
    cantidad_reproducciones
) VALUES (
    59,
    66,
    2,
    4,
    'Canción 2 prueba',
    180,
    null,
    'una letra mouy muyyyhermosa',
    0
);



-- Verificamos canciones
SELECT * FROM canciones WHERE id_artista = 66;

-- Eliminamos
DELETE FROM artistas WHERE id_artista = 66;

-- Verificamos si se eliminaron las cacniones tambien
SELECT * FROM canciones WHERE id_artista = 66;


--Desarrollar un trigger que se ejecute despues de insertar en la tabla de Reproducciones, en base a la
--información insertada debe insertar o actualizar la tabla de Estadisticas. En caso de que en la tabla de
--estadisticas no exista un registro de la canción y el usuario correspondiente deberá agregar el registro con
--el conteo de reproducciones en 1 y los minutos de reproducción de la canción. En caso de que ya exista
--deberá hacer un update en la tabla de estadisticas e incrementar en 1 la cantidad de reproducciones y
--acumular la cantidad de minutos de reproducción. Además deberá actualizar la tabla de canciones para
--incrementar en 1 la cantidad de reproducciones de la canción indicada.

--Mas que todo para quitar el  null que tiene por defecto
UPDATE canciones
    SET cantidad_reproducciones = 0;

CREATE OR REPLACE TRIGGER actualizar_estadisticas_reproduccion
AFTER INSERT ON reproducciones
FOR EACH ROW
BEGIN
    -- Verificar si ya existe un registro en estadisticas para esta canción y usuario
    DECLARE
        v_contador NUMBER;
        v_duracion_reproduccion_minutos NUMBER;
    BEGIN
         v_duracion_reproduccion_minutos := (:NEW.duracion_reproduccion_segundos/60);
         
        SELECT COUNT(*) 
        INTO v_contador
        FROM estadisticas
        WHERE id_usuario = :NEW.id_usuario
        AND id_cancion = :NEW.id_cancion;
        
        IF v_contador = 0 THEN
            -- en dado caso sea 0 el contador pues insertaremos los datos como nuevos
            INSERT INTO estadisticas (id_usuario, id_cancion, cantidad_reproducciones, fecha_ultima_reproduccion, cantidad_minutos_reproduccion)
            VALUES (:NEW.id_usuario, :NEW.id_cancion, 1, :NEW.fecha_reproduccion,  v_duracion_reproduccion_minutos );
        ELSE
            -- pero si el contador es distinto de 0 solo actializaremos el registro
            UPDATE estadisticas
            SET cantidad_reproducciones = cantidad_reproducciones + 1,
                fecha_ultima_reproduccion = :NEW.fecha_reproduccion,
                cantidad_minutos_reproduccion = cantidad_minutos_reproduccion + ( v_duracion_reproduccion_minutos )
            WHERE id_usuario = :NEW.id_usuario
            AND id_cancion = :NEW.id_cancion;
        END IF;
    END;
    
    -- creo que asi se actualizaria directamente 
    UPDATE canciones
    SET cantidad_reproducciones = cantidad_reproducciones + 1
    WHERE id_cancion = :NEW.id_cancion;
END;
/


-- Prueba 1  crucemos los dedos
INSERT INTO reproducciones (id_reproduccion, id_usuario, id_cancion, fecha_reproduccion, duracion_reproduccion_segundos)
VALUES (5, 7, 34, SYSDATE, 200);

-- Verificamosc estadísticas 
SELECT * FROM estadisticas;
SELECT * FROM canciones where id_cancion = 34;

INSERT INTO reproducciones (id_reproduccion, id_usuario, id_cancion, fecha_reproduccion, duracion_reproduccion_segundos)
VALUES (6, 7, 34, SYSDATE, 150);

-- Verificamos aver
SELECT * FROM estadisticas;
SELECT * FROM canciones where id_cancion = 34; 



--Crea un trigger que se active después de actualizar un registro en la tabla listas_reproduccion. Este trigger
--debe verificar si el usuario que creó la lista de reproducción tiene un plan de suscripción activo en la tabla
--usuarios. Si el usuario no tiene un plan de suscripción activo, el trigger debe revertir la actualización y
--generar un mensaje de error indicando que se requiere un plan de suscripción activo para crear una lista de
--reproducción. De igual manera debe crear otro trigger sobre la tabla de listas_x_caciones para verificar si el
--usuario tiene un plan activo y evitar que pueda agregar un registro en dicha tabla en caso de que no tenga
--plan.

CREATE OR REPLACE TRIGGER verificacion_plan_lista_reproduccion
AFTER INSERT OR UPDATE ON listas_reproduccion
FOR EACH ROW
DECLARE
    v_plan_activo NUMBER;
BEGIN
    -- Verificacion
    SELECT id_plan INTO v_plan_activo
    FROM usuarios 
    WHERE id_usuario = :NEW.id_usuario;
  
    
    -- reversion
    IF v_plan_activo = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Se requiere un plan de suscripción activo para crear o actualizar una lista de reproducción.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER verificacion_plan_listas_x_canciones
BEFORE INSERT ON listas_x_canciones
FOR EACH ROW
DECLARE
    v_plan_activo NUMBER;
BEGIN
    -- siendole sincero no pense que funcionaria esta consulta
    SELECT DISTINCT a.id_plan
    INTO v_plan_activo
    FROM usuarios a
    INNER JOIN listas_reproduccion b ON a.id_usuario = b.id_usuario
    WHERE b.id_lista = :NEW.id_lista;
    
    
    IF v_plan_activo IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'Se requiere un plan de suscripción activo para agregar canciones a una lista de reproducción.');
    END IF;
END;
/


-- usuario de prueba
INSERT INTO usuarios (
    id_usuario,
    id_plan,
    nombre_usuario,
    correo,
    fecha_registro
) VALUES (1,0, 'Usuario Sin Plan','Pruebausuario@gmail.com', TO_DATE('2000-10-06', 'YYYY-MM-DD'));


