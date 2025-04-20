FROM python:3.13-alpine

ARG BUILD_DATE
ARG FLASK_PORT
ARG VERSION

LABEL maintainer="Zach Antinelli <zachantinelli@gmail.com>"
LABEL version="${VERSION}"
LABEL description="GenAI Sentry. Flask webapp with GUI for security finding automation and MySQL result queries based on plain language."
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.title="gensen"

ENV FLASK_DEBUG="False"
ENV FLASK_HOST="0.0.0.0"
ENV FLASK_PORT="${FLASK_PORT}"

EXPOSE $FLASK_PORT

COPY gensen /app
COPY wizexercise.txt /

WORKDIR /app
RUN python3 -m pip install --upgrade pip -r requirements.txt

ENTRYPOINT ["python3"]
CMD ["app.py"]

