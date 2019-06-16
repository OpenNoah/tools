#pragma once

#define ESC_FF		"\x0c"
#define ESC_CLEAR	"\033[2J\033[0;0H"

#define ESC_BLACK	"\033[30m"
#define ESC_RED		"\033[31m"
#define ESC_GREEN	"\033[32m"
#define ESC_YELLOW	"\033[33m"
#define ESC_BLUE	"\033[34m"
#define ESC_MAGENTA	"\033[35m"
#define ESC_CYAN	"\033[36m"
#define ESC_WHITE	"\033[37m"

#define ESC_BRIGHT_BLACK	"\033[90m"
#define ESC_BRIGHT_RED		"\033[91m"
#define ESC_BRIGHT_GREEN	"\033[92m"
#define ESC_BRIGHT_YELLOW	"\033[93m"
#define ESC_BRIGHT_BLUE		"\033[94m"
#define ESC_BRIGHT_MAGENTA	"\033[95m"
#define ESC_BRIGHT_CYAN		"\033[96m"
#define ESC_BRIGHT_WHITE	"\033[97m"

#define ESC_RGB(r, g, b)	"\033[38;2;" #r ";" #g ";" #b "m"

#define ESC_RESET	"\033[0m"
#define ESC_BOLD	"\033[1m"
#define ESC_FAINT	"\033[2m"
#define ESC_ITALIC	"\033[3m"
#define ESC_UNDERLINE	"\033[4m"

#define ESC_CURSOR_UP(n)	"\033[" #n "A"
#define ESC_CURSOR_DOWN(n)	"\033[" #n "B"
#define ESC_CURSOR_FORWARD(n)	"\033[" #n "C"
#define ESC_CURSOR_BACK(n)	"\033[" #n "D"
