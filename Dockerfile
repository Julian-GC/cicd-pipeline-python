# Dockerfile
# Usa una imagen base oficial de Python. Elige una versión específica para consistencia.
FROM python:3.13-slim

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copia solo el archivo de requerimientos primero para aprovechar el cache de Docker
COPY requirements.txt .

# Instala solo las dependencias de ejecución (Flask y Gunicorn)
RUN pip install --no-cache-dir --only-binary :all: -r requirements.txt

# Copia el código de la aplicación (solo la carpeta app)
COPY app/ ./app/

# Crea un usuario sin privilegios para ejecutar la aplicación
RUN useradd --create-home --shell /usr/sbin/nologin appuser
USER appuser

# Expón el puerto en el que Gunicorn servirá la aplicación
EXPOSE 8000

# Comando para ejecutar la aplicación usando Gunicorn cuando el contenedor inicie
CMD ["gunicorn", "--workers=4", "--bind=0.0.0.0:8000", "app.app:app"]