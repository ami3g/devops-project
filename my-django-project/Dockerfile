# Use the official Python image with a version that supports Django 5+
FROM python:3.10-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set the working directory
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt /app/
RUN pip install uv
RUN uv pip install --no-cache-dir -r requirements.txt

# RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the code
COPY . /app

# Expose the port
EXPOSE 8000

# Run the application with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "ecommerce_project.wsgi:application", "--timeout", "120"]