# Build stage
FROM swift:6.0-jammy AS builder
WORKDIR /build
COPY . .
RUN swift build -c release --static-swift-stdlib

# Runtime stage
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /build/.build/release/iFoundation /usr/local/bin/swiftanvil
ENTRYPOINT ["swiftanvil"]
