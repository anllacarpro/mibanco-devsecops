FROM python:3.12-slim
WORKDIR /app
RUN pip install flask gunicorn
COPY server.py .
EXPOSE 8080
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:8080", "server:app"]
