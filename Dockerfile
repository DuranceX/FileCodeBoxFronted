# 第一阶段：构建前端主题
FROM node:20 AS frontend-builder

RUN apt-get update && apt-get install -y git python3 make g++ && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# 克隆并构建 2024 主题（你的仓库）
RUN git clone --depth 1 https://github.com/DuranceX/FileCodeBoxFronted.git /build/fronted-2024 && \
    cd /build/fronted-2024 && \
    npm install && \
    npm run build

# 克隆并构建 2023 主题
RUN git clone --depth 1 https://github.com/vastsa/FileCodeBoxFronted2023.git /build/fronted-2023 && \
    cd /build/fronted-2023 && \
    npm install --legacy-peer-deps && \
    npm run build

# 第二阶段：构建最终镜像
FROM python:3.12-slim-bookworm
LABEL author="Lan"
LABEL email="xzu@live.com"

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 克隆后端代码
RUN git clone --depth 1 https://github.com/vastsa/FileCodeBox.git .

# 设置时区
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'Asia/Shanghai' > /etc/timezone

# 从构建阶段复制编译好的前端主题
COPY --from=frontend-builder /build/fronted-2024/dist ./themes/2024
COPY --from=frontend-builder /build/fronted-2023/dist ./themes/2023

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

ENV HOST="0.0.0.0" \
    PORT=12345 \
    WORKERS=1 \
    LOG_LEVEL="info"

EXPOSE 12345

CMD uvicorn main:app \
    --host $HOST \
    --port $PORT \
    --workers $WORKERS \
    --log-level $LOG_LEVEL \
    --proxy-headers \
    --forwarded-allow-ips "*"
