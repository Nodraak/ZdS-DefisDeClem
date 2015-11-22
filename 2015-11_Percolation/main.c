
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#define BOARD_WIDTH     100
#define BOARD_HEIGHT    100
#define PROBA           0.50

typedef enum _e_cell
{
    CELL_TREE,
    CELL_FIRE,
    CELL_ASHES,
    CELL_EMPTY,
    CELL_LAST
}           e_cell;

int board_is_simulaton_finished(e_cell board[BOARD_HEIGHT][BOARD_WIDTH])
{
    int i = 0, j = 0;

    for (j = 0; j < BOARD_HEIGHT; ++j)
    {
        for (i = 0; i < BOARD_WIDTH; ++i)
        {
            if (board[j][i] == CELL_FIRE)
                return 0;
        }
    }
    return 1;
}

void board_burn(e_cell board[BOARD_HEIGHT][BOARD_WIDTH], int j, int i)
{
    if (j >= 0 && j < BOARD_HEIGHT && i >= 0 && i < BOARD_WIDTH)
    {
        if (board[j][i] == CELL_TREE)
        {
            if (rand() < PROBA*RAND_MAX)
            board[j][i] = CELL_FIRE;
        }
    }
}

void board_simulate(e_cell board[BOARD_HEIGHT][BOARD_WIDTH])
{
    int i = 0, j = 0;
    e_cell tmp[BOARD_HEIGHT][BOARD_WIDTH];

    memcpy(tmp, board, sizeof(e_cell)*BOARD_WIDTH*BOARD_HEIGHT);

    for (j = 0; j < BOARD_HEIGHT; ++j)
    {
        for (i = 0; i < BOARD_WIDTH; ++i)
        {
            if (board[j][i] == CELL_FIRE)
            {
                tmp[j][i] = CELL_ASHES;
                board_burn(tmp, j, i-1);
                board_burn(tmp, j, i+1);
                board_burn(tmp, j-1, i);
                board_burn(tmp, j+1, i);
            }
        }
    }

    memcpy(board, tmp, sizeof(e_cell)*BOARD_WIDTH*BOARD_HEIGHT);
}

void board_print_stats(e_cell board[BOARD_HEIGHT][BOARD_WIDTH])
{
    int i = 0, j = 0;
    int stats[CELL_LAST];
    memset(stats, 0, sizeof(int)*CELL_LAST);
    char *labels[CELL_LAST] = {
        "Tree",
        "Fire",
        "Ashes",
        "Empty"
    };

    for (j = 0; j < BOARD_HEIGHT; ++j)
    {
        for (i = 0; i < BOARD_WIDTH; ++i)
            stats[board[j][i]] ++;
    }

    for (i = 0; i < CELL_LAST; ++i)
        printf("\t%-5s %d\n", labels[i], stats[i]);
    printf("\t->    %d\n", 100*stats[CELL_ASHES]/(stats[CELL_TREE]+stats[CELL_ASHES]));
}

int main(void)
{
    e_cell board[BOARD_HEIGHT][BOARD_WIDTH];
    int step = 1;

    srand(42);
    memset(board, CELL_TREE, sizeof(e_cell)*BOARD_WIDTH*BOARD_HEIGHT);
    board[50][50] = CELL_FIRE;

    /* main loop */
    while (!board_is_simulaton_finished(board))
    {
        printf("\n%d\n", step);
        board_simulate(board);
        board_print_stats(board);
        step ++;
    }

    return EXIT_SUCCESS;
}
