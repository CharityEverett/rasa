# Define the base image for the builder stage
ARG RASA_VERSION=latest
ARG RASA_VERSION_HASH
ARG RASA_IMAGE_IMAGE_HASH

FROM rasa/rasa:${RASA_VERSION}-full as builder

# Copy project files into the image
COPY . /build/

# Set the working directory
WORKDIR /build

# install dependencies
RUN python -m venv /opt/venv && \
  . /opt/venv/bin/activate && \
  pip install --no-cache-dir -U "pip==22.*" -U "wheel>0.38.0" && \
  poetry install --no-dev --no-root --no-interaction && \
  poetry build -f wheel -n && \
  pip install --no-deps dist/*.whl && \
  rm -rf dist *.egg-info

# Define the base image for the runner stage
FROM rasa/rasa:${RASA_VERSION}-full as runner

# Copy the virtual environment from the builder stage
COPY --from=builder /opt/venv /opt/venv

# make sure we use the virtualenv
ENV PATH="/opt/venv/bin:$PATH"

# set HOME environment variable
ENV HOME=/app

# update permissions & change user to not run as root
WORKDIR /app
RUN chgrp -R 0 /app && chmod -R g=u /app && chmod o+wr /app
USER 1001

# change shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# the entry point
EXPOSE 5005
ENTRYPOINT ["rasa"]
CMD ["--help"]
