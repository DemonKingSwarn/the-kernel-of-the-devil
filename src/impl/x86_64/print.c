#include "print.h"

const static size_t NUM_COLS = 80;
const static size_t NUM_ROWS = 25;

struct Char {
    uint8_t character;
    uint8_t color;
};

struct Char* buffer = (struct Char*) 0xb8000;
size_t col = 0;
size_t row = 0;
uint8_t color = PRINT_COLOR_WHITE | PRINT_COLOR_BLACK << 4;

void clear_row(size_t row) {
    struct Char empty = (struct Char) {
        character: ' ',
        color: color,
    };

    for (size_t col = 0; col < NUM_COLS; col++) {
        buffer[col + NUM_COLS * row] = empty;
    }
}

void print_clear() {
    for (size_t i = 0; i < NUM_ROWS; i++) {
        clear_row(i);
    }
}

void print_newline() {
    col = 0;

    if (row < NUM_ROWS - 1) {
        row++;
        return;
    }

    for (size_t row = 1; row < NUM_ROWS; row++) {
        for (size_t col = 0; col < NUM_COLS; col++) {
            struct Char character = buffer[col + NUM_COLS * row];
            buffer[col + NUM_COLS * (row - 1)] = character;
        }
    }

    clear_row(NUM_COLS - 1);
}

void print_char(char character) {
    if (character == '\n') {
        print_newline();
        return;
    }

    if (col > NUM_COLS) {
        print_newline();
    }

    buffer[col + NUM_COLS * row] = (struct Char) {
        character: (uint8_t) character,
        color: color,
    };

    col++;
}

void print_str(char* str) {
    if (str == NULL) {
        return;
    }

    for (size_t i = 0; 1; i++) {
        char character = (uint8_t) str[i];

        if (character == '\0') {
            return;
        }

        print_char(character);
    }
}

void print_set_color(uint8_t foreground, uint8_t background) {
    color = foreground + (background << 4);
}

void print_int(int num) {
  if (num == 0) {
    print_char('0');
    return;
  }

  int abs_num = num > 0 ? num : -num;
  char buffer[10];
  int i = 0;

  while (abs_num > 0) {
    buffer[i++] = (abs_num % 10) + '0';
    abs_num /= 10;
  }

  if (num < 0) {
    print_char('-');
  }

  while (--i >= 0) {
    print_char(buffer[i]);
  }
}

void print_float(float num) {
    int integer_part = (int)num;
    print_int(integer_part);

    print_char('.');

    float fractional_part = num - integer_part;
    for (int i = 0; i < 6; ++i) {  // print up to 6 decimal places
        fractional_part *= 10;
        int digit = (int)fractional_part;
        print_char('0' + digit);
        fractional_part -= digit;
    }
}

void print_hex(uint32_t num) {
    print_str("0x");

    char hex_digits[] = "0123456789ABCDEF";
    for (int i = 28; i >= 0; i -= 4) {
        uint8_t digit = (num >> i) & 0xF;
        print_char(hex_digits[digit]);
    }
}%