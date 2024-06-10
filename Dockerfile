FROM node:12.21.0-buster-slim as base
LABEL maintainer="Eero Ruohola <eero.ruohola@shuup.com>"


#HDUISA
# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libpangocairo-1.0-0 \
        python3 \
        python3-dev \
        python3-pip \
        libffi-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy project files
COPY . /app
WORKDIR /app

# Install Python dependencies
ARG editable=0
RUN if [ "$editable" -eq 1 ]; then \
        pip3 install --upgrade pip && \
        pip3 install -r requirements-tests.txt && \
        python3 setup.py build_resources; \
    else \
        pip3 install --upgrade pip && \
        pip3 install shuup; \
    fi

# Run migrations and setup
RUN python3 -m shuup_workbench migrate
RUN python3 -m shuup_workbench shuup_init

# Create superuser (if not exists)
RUN echo '\
from django.contrib.auth import get_user_model\n\
from django.db import IntegrityError\n\
try:\n\
    get_user_model().objects.create_superuser("admin", "admin@admin.com", "admin")\n\
except IntegrityError:\n\
    pass\n'\
| python3 -m shuup_workbench shell

# Set the command to run the development server
CMD ["python3", "-m", "shuup_workbench", "runserver", "0.0.0.0:8000"]
