FROM python:3.11-slim
WORKDIR /app

# Copy server sources
COPY server.py /app/server.py

ENV PORT=8080
ENV VALID_LICENSE_KEY=EXTRO-LIFE-ABC123

EXPOSE 8080

CMD ["python", "server.py"]
