# Étape de build multi-arch
FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.19-alpine as gobuild

# Arguments pour la compilation croisée
ARG TARGETOS
ARG TARGETARCH
ARG TARGETPLATFORM

WORKDIR /build
ADD go.mod go.sum /build/
RUN go mod download -x
ADD cmd /build/cmd
ADD pkg /build/pkg

# Compilation croisée avec les arguments cibles
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -a -ldflags '-extldflags "-static"' -o ./s3driver ./cmd/s3driver

# Étape d'exécution
FROM alpine:3.17
LABEL maintainers="Vitaliy Filippov <vitalif@yourcmc.ru>"
LABEL description="csi-s3 slim image"

RUN apk add --no-cache fuse mailcap rclone
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/community s3fs-fuse

# Téléchargement dynamique de GeeseFS selon l'architecture
ARG TARGETARCH
ADD https://github.com/yandex-cloud/geesefs/releases/latest/download/geesefs-linux-${TARGETARCH} /usr/bin/geesefs
RUN chmod 755 /usr/bin/geesefs

COPY --from=gobuild /build/s3driver /s3driver
ENTRYPOINT ["/s3driver"]