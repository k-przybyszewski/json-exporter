# Base build image
FROM golang:1.14-alpine AS build-base

WORKDIR /go/src/app

# Force the go compiler to use modules 
ENV GO111MODULE=on

# We want to populate the module cache based on the go.{mod,sum} files. 
COPY go.mod .
COPY go.sum .

#This is the ‘magic’ step that will download all the dependencies that are specified in 
# the go.mod and go.sum file.

# Because of how the layer caching system works in Docker, the go mod download 
# command will _ only_ be re-run when the go.mod or go.sum file change 
# (or when we add another docker instruction this line) 
RUN go mod download

# This image builds the weavaite server
FROM build-base AS build
# Here we copy the rest of the source code
COPY . .
# And compile the project
RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build -a -tags netgo -ldflags '-w -extldflags "-static"' -o /go/bin/app ./main.go

#In this last stage, we start from a fresh Alpine image, to reduce the image size and not ship the Go compiler in our production artifacts.
FROM alpine:latest AS app

# Finally we copy the statically compiled Go binary.
COPY --from=build /go/bin/app /bin/app

CMD ["/bin/app"]
