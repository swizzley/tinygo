# TinyGo base stage just installs LLVM 7 and the TinyGo compiler itself.
FROM golang:latest AS tinygo-base

RUN wget -O- https://apt.llvm.org/llvm-snapshot.gpg.key| apt-key add - && \
    echo "deb http://apt.llvm.org/stretch/ llvm-toolchain-stretch-7 main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y llvm-7-dev libclang-7-dev git

RUN wget -O- https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

COPY . /go/src/github.com/tinygo-org/tinygo

RUN cd /go/src/github.com/tinygo-org/tinygo/ && \
    git submodule update --init

RUN cd /go/src/github.com/tinygo-org/tinygo/ && \
    dep ensure --vendor-only && \
    go install /go/src/github.com/tinygo-org/tinygo/

# tinygo-wasm stage installs the needed dependencies to compile TinyGo programs for WASM.
FROM tinygo-base AS tinygo-wasm

COPY --from=tinygo-base /go/bin/tinygo /go/bin/tinygo
COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/src /go/src/github.com/tinygo-org/tinygo/src
COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/targets /go/src/github.com/tinygo-org/tinygo/targets

RUN wget -O- https://apt.llvm.org/llvm-snapshot.gpg.key| apt-key add - && \
    echo "deb http://apt.llvm.org/stretch/ llvm-toolchain-stretch-7 main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y libllvm7 lld-7

# tinygo-avr stage installs the needed dependencies to compile TinyGo programs for AVR microcontrollers.
FROM tinygo-base AS tinygo-avr

COPY --from=tinygo-base /go/bin/tinygo /go/bin/tinygo
COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/src /go/src/github.com/tinygo-org/tinygo/src
COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/targets /go/src/github.com/tinygo-org/tinygo/targets
COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/Makefile /go/src/github.com/tinygo-org/tinygo/
COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/tools /go/src/github.com/tinygo-org/tinygo/tools
COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/lib /go/src/github.com/tinygo-org/tinygo/lib

RUN cd /go/src/github.com/tinygo-org/tinygo/ && \
    apt-get update && \
    apt-get install -y apt-utils python3 make binutils-avr gcc-avr avr-libc && \
    make gen-device-avr && \
    apt-get remove -y python3 make && \
    apt-get autoremove -y && \
    apt-get clean

# tinygo-arm stage installs the needed dependencies to compile TinyGo programs for ARM microcontrollers.
FROM tinygo-base AS tinygo-arm

COPY --from=tinygo-base /go/bin/tinygo /go/bin/tinygo
COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/src /go/src/github.com/tinygo-org/tinygo/src
COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/targets /go/src/github.com/tinygo-org/tinygo/targets
COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/Makefile /go/src/github.com/tinygo-org/tinygo/
COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/tools /go/src/github.com/tinygo-org/tinygo/tools
COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/lib /go/src/github.com/tinygo-org/tinygo/lib

RUN cd /go/src/github.com/tinygo-org/tinygo/ && \
    apt-get update && \
    apt-get install -y apt-utils python3 make binutils-arm-none-eabi clang-7 && \
    make gen-device-nrf && make gen-device-stm32 && \
    apt-get remove -y python3 make && \
    apt-get autoremove -y && \
    apt-get clean

# tinygo-all stage installs the needed dependencies to compile TinyGo programs for all platforms.
FROM tinygo-wasm AS tinygo-all

COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/Makefile /go/src/github.com/tinygo-org/tinygo/
COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/tools /go/src/github.com/tinygo-org/tinygo/tools
COPY --from=tinygo-base /go/src/github.com/tinygo-org/tinygo/lib /go/src/github.com/tinygo-org/tinygo/lib

RUN cd /go/src/github.com/tinygo-org/tinygo/ && \
    apt-get update && \
    apt-get install -y apt-utils python3 make binutils-arm-none-eabi clang-7 binutils-avr gcc-avr avr-libc && \
    make gen-device && \
    apt-get remove -y python3 make && \
    apt-get autoremove -y && \
    apt-get clean

CMD ["tinygo"]
