/* Source file : main.c
 * MUNOZ Melvyn, CAUSSE Raphael
 * CY TECH PREING 2 MI
**/
 
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    /* Convert string argv[1] to a long integer. */
    unsigned long Uo = strtol(argv[1], NULL, 10);
    unsigned long value = Uo, altitude_max = Uo, flight_time = 0, altitude_time = 0, in_altitude = 1;
    FILE *file = fopen(argv[2], "w");
    if (!file) {
        fprintf(stderr, "\033[31m\x1b[1mError:\x1b[0m\033[0m \x1b[1m%s:\x1b[0m failed to open the file.\n\n", argv[2]);
        exit(1);
    }
    fprintf(file, "n Un\n0 %lu\n", Uo);
    while (value != 1) {
        /* Syracuse sequence calculation. */
        value = (value%2 == 0) ? (value/2) : (1+value*3);
        flight_time++;
        fprintf(file, "%lu %lu\n", flight_time, value);
        if (value > altitude_max) altitude_max = value;
        if (value < Uo) in_altitude = 0;
        if (value > Uo) altitude_time += in_altitude;
    }
    fprintf(file, "altitude_max=%lu\nflight_time=%lu\naltitude_time=%lu", altitude_max, flight_time, altitude_time);
    fclose(file);
    return 0;
}