#include "print.h"
#include "keyboard.h"

#define MAX_COMMAND_LENGTH 100

void process_command(char* command) {
  if (strcmp(command, "clear") == 0) {
    print_clear();
  } else {
    print_str("Unknown command: ");
    print_str(command);
    print_char('\n');
  }
}

void kernel_main() {
  print_clear();
  print_set_color(PRINT_COLOR_YELLOW, PRINT_COLOR_BLACK);
  print_str("Welcome to Camp Half-Blood!!!\n");

  char command[MAX_COMMAND_LENGTH];
  int command_length = 0;

  while (1) {
    char ch = keyboard_read();

    if (ch == '\n') {
      command[command_length] = '\0';
      process_command(command);
      command_length = 0;
    } else if (command_length < MAX_COMMAND_LENGTH - 1) {
      command[command_length++] = ch;
    }
  }
}