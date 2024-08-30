FROM golang:1.16-alpine
WORKDIR /app
COPY . .
RUN go build -o go_chat_service
CMD ["./go_chat_service"]
