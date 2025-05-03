#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE_LENGTH 256
#define MAX_LINES 255

int main(int argc, char *argv[]) {
    /* Объявляем ВСЕ переменные в начале! */
    int N, K;
    FILE *file;
    char lines[MAX_LINES][MAX_LINE_LENGTH];
    int line_count = 0;
    int i;
    char *program;
    char command[MAX_LINE_LENGTH + 6];

    /* Проверка аргументов */
    if (argc != 3) {
        printf("Usage: %s <N> <K>\n", argv[0]);
        return 1;
    }

    N = atoi(argv[1]);
    K = atoi(argv[2]);

    if (N < 1 || N > 255 || K < 1 || K > 255) {
        printf("N and K must be in range [1, 255]\n");
        return 1;
    }

    /* Открытие файла */
    file = fopen("files.txt", "r");
    if (!file) {
        printf("Could not open files.txt\n");
        return 1;
    }

    /* Чтение строк */
    while (line_count < MAX_LINES && fgets(lines[line_count], MAX_LINE_LENGTH, file)) {
        lines[line_count][strcspn(lines[line_count], "\n")] = '\0';
        line_count++;
    }

    fclose(file);

    if (K > line_count) {
        printf("K is greater than number of lines in file\n");
        return 1;
    }

    program = lines[K - 1];

    /* Запуск программы N раз */
    for (i = 0; i < N; i++) {
        sprintf(command, "start %s", program);
        system(command);
    }

    return 0;
}