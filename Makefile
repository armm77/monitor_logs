CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -std=c11 -D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=700
LDFLAGS ?=

SRC = src/main.c src/config.c src/watcher.c src/output.c src/logging.c
OBJ = $(SRC:.c=.o)

BIN = monitor_logs

all: $(BIN)

$(BIN): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $(OBJ) $(LDFLAGS)

clean:
	rm -f $(OBJ) $(BIN)

