FROM golang:alpine as swagger
WORKDIR /go-swagger
RUN apk --no-cache add ca-certificates shared-mime-info mailcap git build-base binutils-gold
RUN git clone https://github.com/go-swagger/go-swagger.git

WORKDIR /go-swagger/go-swagger

RUN git checkout tags/v0.30.4
RUN CGO_ENABLED=0 go build -tags osusergo,netgo -o /bin/swagger-0.30.4 -a ./cmd/swagger

RUN git checkout tags/v0.28.0
RUN go build -o /bin/swagger-0.28.0 -ldflags "-linkmode external -extldflags \"-static\"" -a ./cmd/swagger

FROM golang:alpine
RUN apk --no-cache add git

COPY --from=swagger /bin/swagger-0.28.0 /bin/
COPY --from=swagger /bin/swagger-0.30.4 /bin/
