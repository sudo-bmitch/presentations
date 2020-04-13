FROM python:3

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 80

ENV NAME=Docker User
CMD [ "gunicorn", "app:app", "-b", "0.0.0.0:80", "--log-file", "-", "--access-logfile", "-", "--workers", "4", "--reload", "--keep-alive", "0" ]

ARG image_name=flask-demo
LABEL \
    org.label-schema.docker.cmd="docker run -d -p 8080:80 ${image_name}" \
    org.label-schema.description="Flask demo image" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.version="0.1"


