
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define SIZE 9
typedef int cell;


void grille_print(cell **grille)
{
    int i = 0, j = 0;

    printf("---------\n");
    for (j = 0; j < SIZE; ++j)
    {
        for (i = 0; i < SIZE; ++i)
        {
            if (grille[j][i] != 0)
                printf("%d", grille[j][i]);
            else
                printf(" ");
        }
        printf("\n");
    }
    printf("---------\n");
}


cell **grille_read(int ac, char *av[])
{
    cell **ret = NULL, i = 0, j = 0;

    if (ac != 2)
    {
        char *example = "1234567894567891237891.345623456789156789123489123456734.678912678912345912345678";
        fprintf(stderr, "Usage: %s \"%s\"\n", av[0], example);
        exit(1);
    }

    ret = malloc(SIZE*sizeof(cell*));
    if (ret == NULL)
    {
        fprintf(stderr, "Error: malloc()\n");
        exit(1);
    }

    for (j = 0; j < SIZE; ++j)
    {
        ret[j] = malloc(SIZE*sizeof(cell));
        if (ret[j] == NULL)
        {
            fprintf(stderr, "Error: malloc()\n");
            exit(1);
        }

        for (i = 0; i < SIZE; ++i)
        {
            char c = av[1][j*SIZE + i];

            if (c >= '0' && c <= '9')
                ret[j][i] = av[1][j*SIZE + i] - '0';
            else
                ret[j][i] = 0;
        }
    }

    return ret;
}


int grille_is_valid(int **grille)
{
    int i = 0, j = 0;
    cell n[SIZE+1];

    // check lines
    for (j = 0; j < SIZE; ++j)
    {
        memset(n, 0, (SIZE+1)*sizeof(cell));

        for (i = 0; i < SIZE; ++i)
            n[grille[j][i]] ++;

        for (i = 1; i <= 9; ++i) // skip empty cells
        {
            if (n[i] > 1)
                return 0;
        }
    }

    // check columns
    for (i = 0; i < SIZE; ++i)
    {
        memset(n, 0, (SIZE+1)*sizeof(cell));

        for (j = 0; j < SIZE; ++j)
            n[grille[j][i]] ++;

        for (j = 1; j <= 9; ++j) // skip empty cells
        {
            if (n[j] > 1)
                return 0;
        }
    }

    // check blocks
    for (i = 0; i < SIZE; ++i)
    {
        int block_x = i % 3, block_y = i / 3;

        memset(n, 0, (SIZE+1)*sizeof(cell));

        for (j = 0; j < SIZE; ++j)
        {
            int cell_x = j % 3, cell_y = j / 3;

            cell c = grille[block_y*3 + cell_y][block_x*3 + cell_x];
            n[c] ++;
        }

        for (j = 1; j <= 9; ++j) // skip empty cells
        {
            if (n[j] > 1)
                return 0;
        }
    }

    return 1;
}


void grille_fill_one(cell **grille, int current)
{
    cell saved = 0;
    int cur_y = current / SIZE, cur_x = current % SIZE;
    int i = 0;

    if (current == SIZE*SIZE)
    {
        if (grille_is_valid(grille))
        {
            printf("Success:\n");
            grille_print(grille);
            printf("-> %d\n", grille_is_valid(grille));
            exit(0);
        }
        else
        {
            printf("Grid has no solution :(\n");
            grille_print(grille);
            return;
        }
    }

    if (grille[cur_y][cur_x] != 0)
    {
        grille_fill_one(grille, current+1);
    }
    else
    {
        for (i = 1; i <= 9; ++i)
        {
            grille[cur_y][cur_x] = i;
            if (grille_is_valid(grille))
                grille_fill_one(grille, current+1);
        }

        grille[cur_y][cur_x] = 0;
    }
}


int main(int ac, char *av[])
{
    cell **grille = NULL;

    grille = grille_read(ac, av);
    grille_print(grille);

    grille_fill_one(grille, 0);

    printf("-> %d\n", grille_is_valid(grille));

    return 0;
}
