# Define the base image for the builder stage
ARG RASA_VERSION=latest
FROM rasa/rasa:${RASA_VERSION}-full as builder

# Copy project files into the image
COPY . /build/

# Set the working directory
WORKDIR /build

# Create and activate a virtual environment
RUN python -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --no-cache-dir -U pip==22.* wheel>0.38.0 && \
    poetry install --no-dev --no-root --no-interaction && \
    poetry build -f wheel -n && \
    pip install --no-deps dist/*.whl && \
    rm -rf dist *.egg-info

# Define the base image for the runner stage
FROM rasa/rasa:${RASA_VERSION}-full as runner

# Copy the virtual environment from the builder stage
COPY --from=builder /opt/venv /opt/venv

# Set environment variables to ensure the virtualenv is activated
ENV PATH="/opt/venv/bin:$PATH"
ENV HOME=/app

# Set permissions and change user to enhance security
WORKDIR /app
RUN chgrp -R 0 /app && chmod -R g=u /app && chmod o+wr /app
USER 1001

# Change shell to handle pipefail
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Expose the port the app runs on
EXPOSE 5005

# Set the default command to run when starting the container
ENTRYPOINT ["rasa"]
CMD ["run"]
