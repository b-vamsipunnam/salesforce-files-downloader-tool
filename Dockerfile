FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONPATH=/app/src/robot/libraries:/app

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gnupg \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
        > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN python -m pip install --upgrade pip \
    && python -m pip install -r requirements.txt \
    && python -m pip check

COPY src ./src
COPY ci ./ci
COPY docker ./docker

RUN useradd --create-home --uid 10001 downloader \
    && install -m 0755 docker/entrypoint.sh /usr/local/bin/downloader-entrypoint \
    && mkdir -p input downloads artifacts results \
    && chown -R downloader:downloader /app

USER downloader

ENTRYPOINT ["downloader-entrypoint"]
CMD ["robot", "--outputdir", "/app/results", "/app/src/robot/orchestrator/download.robot"]
