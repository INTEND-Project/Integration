FROM python:3.14-slim

LABEL maintainer="INTEND Project"
LABEL description="inGraph image"

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    FLASK_APP=inGraphApp.py \
    FLASK_ENV=production \
    PORT=5000 \
    GRAPHDB_BASE_URL=http://graphdb:7200

WORKDIR /app

RUN groupadd -r ingraph && useradd -r -g ingraph ingraph
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/INTEND-Project/inGraph.git . && \
    chown -R ingraph:ingraph /app
RUN pip install --no-cache-dir -r requirements.txt
RUN mkdir -p uploads && chown ingraph:ingraph uploads

USER ingraph
EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -sf http://localhost:5000/health || exit 1

CMD ["python", "inGraphApp.py"]
