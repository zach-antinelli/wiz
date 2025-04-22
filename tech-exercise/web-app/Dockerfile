FROM python:3.13-alpine

ARG BUILD_DATE
ARG VERSION

LABEL maintainer="Zach Antinelli <zachantinelli@gmail.com>"
LABEL version="${VERSION}"
LABEL description="GenAI Sentry. FastAPI backend with JS frontend for security finding automation and MySQL result queries based on plain language."
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.title="gensen"

ENV GENSEN_HOST="0.0.0.0"
ENV GENSEN_PORT="8080"
EXPOSE $GENSEN_PORT

COPY gensen /app
COPY wizexercise.txt /

WORKDIR /app
RUN python3 -m pip install --upgrade pip -r requirements.txt

ENTRYPOINT ["python3"]
CMD ["app.py"]
