# cicd-pipeline-python
Taller 2

# CI Pipeline: calculadora web con Flask

Calculadora web en Flask con un pipeline de Integración Continua en GitHub Actions: formato (Black), linters (Pylint y Flake8), pruebas unitarias, de componente y de aceptación (Selenium), análisis en SonarCloud y publicación de la imagen Docker en Docker Hub.

## Integrantes

- Julian Giraldo, usuario de GitHub: `Julian-GC` (propietario del repositorio)

## Evidencias

- Pull Request de la sección 9: PEGA_AQUI_LA_URL_DEL_PR
- Ejecución fallida por el error intencional: PEGA_AQUI_LA_URL_DE_LA_EJECUCION_FALLIDA

## Respuestas

### 1. Ventajas de un pipeline de CI

1. **Detección temprana de errores.** Cada cambio se prueba apenas se sube. Un error se encuentra en minutos, cuando es barato de corregir, y no semanas después.
2. **Calidad consistente y automática.** El formato, los linters, la cobertura mínima del 80% y el Quality Gate se aplican siempre y a todos, sin depender de que alguien se acuerde de revisarlos.
3. **Integración segura y frecuente.** Con la rama `main` protegida, nada se integra si el pipeline no pasa. Eso mantiene `main` siempre en un estado funcional.
4. **Entregas repetibles.** La imagen que se publica es construida y probada por el mismo proceso cada vez, así que no depende de la máquina de una persona.

### 2. Prueba unitaria, de componente y de aceptación

- **Unitaria:** prueba una pieza aislada. Ejemplo en esta app: `sumar(2, 3)` devuelve `5`, sin servidor ni navegador.
- **De componente:** prueba un componente completo sin servidor real ni navegador. Ejemplo: enviar un POST con `2`, `3` y `sumar` al cliente de pruebas de Flask y verificar que la respuesta contiene `Resultado: 5.0`.
- **De aceptación:** prueba la aplicación como la usaría una persona. Ejemplo: Selenium abre Chrome, escribe los números, elige la operación, hace clic en Calcular y lee el resultado en pantalla.

Una diferencia práctica: si alguien borrara el botón Calcular del HTML, la prueba de componente seguiría pasando, pero la de aceptación fallaría, porque no podría hacer clic.

### 3. Pasos del workflow

- **Checkout:** descarga el código del repositorio, con historial completo para que SonarCloud identifique el código nuevo.
- **Set up Python:** instala Python 3.13, la misma versión del Dockerfile.
- **Install dependencies:** instala las herramientas de `requirements-dev.txt`.
- **Run Black:** verifica el formato; si no está formateado, detiene el pipeline.
- **Run Pylint y Run Flake8:** generan reportes sin detener el pipeline por los hallazgos, para que SonarCloud los consolide.
- **Run Unit and Component Tests:** ejecuta las pruebas y falla si alguna no pasa o si la cobertura es menor al 80%.
- **Build Docker image:** construye la imagen y la etiqueta con el SHA del commit.
- **Start container:** enciende el contenedor y espera a que la app responda.
- **Run Acceptance Tests:** Selenium prueba la aplicación empaquetada en el contenedor.
- **Show container logs on failure:** si algo falló, muestra los registros del contenedor para diagnosticar.
- **Upload Test Reports Artifacts:** guarda los reportes aunque el pipeline haya fallado.
- **SonarCloud Scan:** envía código y reportes a SonarCloud y falla si el Quality Gate no pasa.
- **Login to Docker Hub y Push Docker image:** solo en un push a `main`, inicia sesión y publica la misma imagen ya probada con las etiquetas `latest` y el SHA.

### 4. Dificultades y aprendizajes

**Julian Giraldo:**

- El archivo `ci.yml` se subió vacío porque no lo había guardado en el editor antes del commit; GitHub respondió "No event triggers defined in `on`". Aprendí que Git solo sube lo que está guardado en disco.
- Creé los secretos y las variables en un lugar equivocado, y el pipeline falló al construir la imagen porque el nombre quedó sin usuario (`/cicd-pipeline-python`). Los recreé en el repositorio correcto. Aprendí a leer el nombre que construye el error para deducir qué valor llegó vacío.
- Mi entorno virtual se llamaba `.venv` y el `.gitignore` solo ignoraba `venv/`, así que agregué `.venv/` para no subir las librerías.
- SonarCloud reportó 17 issues aunque el Quality Gate pasara. Corregí 15 y acepté 2 (CSRF y dependencias sin bloquear), porque no aplicaban a una calculadora sin sesiones.

### 5. Ventajas de construir, probar y publicar la misma imagen

- Se prueba lo que realmente se entrega. Una prueba sobre el código no detecta fallos del empaquetado (dependencias faltantes, puerto mal configurado, usuario sin permisos).
- No hay diferencias entre lo probado y lo publicado: se construye una sola vez y se publica la misma imagen, identificada por el SHA del commit.
- Reproducibilidad: la imagen funciona igual en cualquier entorno donde se despliegue.
- Trazabilidad: la etiqueta con el SHA permite saber exactamente qué código contiene cada imagen.

### 6. El Pull Request de la sección 9

**Pruebas agregadas:**

- `test_sumar_decimales`: detectaría un error si `sumar` truncara o redondeara los decimales.
- `test_multiplicar_dos_negativos`: detectaría un error de signos en la multiplicación.
- `test_index_post_un_numero_invalido`: detectaría que la app se rompa o acepte datos cuando solo uno de los dos números es inválido.

**Error intencional:** hice que `restar` sumara. Este error no lo detectaron las pruebas nuevas, sino las que ya existían (`test_restar` y `test_index_post_restar`), lo que muestra el valor de tener varias pruebas.

**Qué pasó en el pipeline:** falló en el paso **Run Unit and Component Tests**. Los pasos siguientes (construcción de la imagen, arranque del contenedor, pruebas de aceptación, SonarCloud y publicación en Docker Hub) no se ejecutaron. Solo corrieron los pasos de diagnóstico y subida de reportes por sus condiciones `failure()` y `always()`.

**Cómo se evitó que llegara a `main` y a Docker Hub:** el check `build-and-test` es obligatorio en la regla de protección de `main`, así que GitHub bloqueó el merge mientras estaba en rojo. Además, la publicación en Docker Hub solo corre en un push a `main`, que nunca ocurrió con el error. Una vez corregido, el pipeline quedó en verde y se pudo integrar.