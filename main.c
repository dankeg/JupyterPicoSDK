#include <stdio.h>
#include "pico/stdlib.h"

int main() {
    stdio_init_all();

#ifndef PICO_DEFAULT_LED_PIN
#warning main.c requires a board with a regular LED
#else
    const uint LED_PIN = PICO_DEFAULT_LED_PIN;
    
    // Initialize the LED pin
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, GPIO_OUT);

    uint32_t counter = 0;

    while (true) {
        // Print a message to stdout
        printf("Hello from Pico! Counter = %lu\n", counter++);

        // Turn the LED on, wait 250 ms
        gpio_put(LED_PIN, 1);
        sleep_ms(250);

        // Turn the LED off, wait 250 ms
        gpio_put(LED_PIN, 0);
        sleep_ms(250);
    }
#endif
    return 0; // Should never get here
}
