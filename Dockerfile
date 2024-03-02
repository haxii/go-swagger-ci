FROM golang:alpine as build

RUN apk --no-cache add ca-certificates shared-mime-info mailcap git build-base binutils-gold upx

# go-swagger
WORKDIR /build/go-swagger
RUN git clone https://github.com/go-swagger/go-swagger.git .

RUN git checkout v0.30.4
RUN VERSION=$(git describe --abbrev=0 --tags) &&\
     COMMIT_HASH=$(git rev-parse HEAD) &&\
    LDFLAGS="$LDFLAGS -X github.com/go-swagger/go-swagger/cmd/swagger/commands.Commit=$COMMIT_HASH" &&\
    LDFLAGS="$LDFLAGS -X github.com/go-swagger/go-swagger/cmd/swagger/commands.Version=$VERSION" &&\
    CGO_ENABLED=0 go build -tags osusergo,netgo -o /bin/swagger-$VERSION -ldflags "$LDFLAGS" -a ./cmd/swagger

RUN git checkout v0.28.0
RUN VERSION=$(git describe --abbrev=0 --tags) && \
    COMMIT_HASH=$(git rev-parse HEAD) &&\
    LDFLAGS="-linkmode external -extldflags \"-static\"" &&\
    LDFLAGS="$LDFLAGS -X github.com/go-swagger/go-swagger/cmd/swagger/commands.Commit=$COMMIT_HASH" &&\
    LDFLAGS="$LDFLAGS -X github.com/go-swagger/go-swagger/cmd/swagger/commands.Version=$VERSION" &&\
    go build -o /bin/swagger-$VERSION -ldflags "$LDFLAGS" -a ./cmd/swagger

# swag
WORKDIR /build/swag
RUN git clone https://github.com/swaggo/swag.git .

RUN LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
RUN git checkout $LATEST_TAG
RUN CGO_ENABLED=0 go build -a -o /bin/swag cmd/swag/main.go

# swagger-sdk-gen
WORKDIR /build/js-swagger-sdk-gen
RUN git clone https://github.com/haxii/js-swagger-sdk-gen.git .
RUN VERSION=$(git describe --abbrev=0 --tags) &&\
    BUILD=$(git rev-parse --short HEAD) &&\
    go build -o /bin/swagger-sdk-gen -ldflags "-X main.Build=$BUILD -X main.Version=$VERSION" ./cmd/js-swagger-sdk-gen/*

# compress
RUN upx --best /bin/swagger-0.28.0
RUN upx --best /bin/swagger-0.30.4
RUN upx --best /bin/swagger-sdk-gen
RUN upx --best /bin/swag

FROM golang:alpine

RUN apk --no-cache add git

COPY --from=build /bin/swagger-v0.28.0 /bin/swagger-0.28.0
COPY --from=build /bin/swagger-v0.30.4 /bin/swagger-0.30.4
COPY --from=build /bin/swagger-sdk-gen /bin/
COPY --from=build /bin/swag /bin/
