
FROM node:lts-alpine AS builder

WORKDIR /app


COPY package*.json ./
RUN npm install


COPY . .


FROM node:lts-alpine AS runner

WORKDIR /app


RUN addgroup -S appgroup && adduser -S appuser -G appgroup


COPY --from=builder /app .

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

CMD ["node", "server.js"] 