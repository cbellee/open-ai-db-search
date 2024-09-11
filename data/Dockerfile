# Use an official Python runtime as the base image
FROM python:3.12.5-slim-bookworm

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container
COPY requirement.txt .

# Install the Python dependencies
RUN pip install --no-cache-dir -r requirement.txt

# Copy the rest of the application code into the container, except .env file
COPY . .

# # Set the command to run the application
CMD ["./entrypoint.sh"]
