# Use the official lightweight Python image
FROM python:3.9-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the application code to the container
COPY Hello_World_web_app.py .

# Expose the application port
EXPOSE 5000

# Command to run the application
CMD ["python", "Hello_World_web_app.py"]
