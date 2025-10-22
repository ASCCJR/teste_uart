/**
 * @file main.c
 * @brief BitDogLab #2 - Receptor GPIO (Atuador)
 *
 * Fase 3 do projeto Ponte de Protocolo.
 * - Lê um pino de entrada digital (GP4).
 * - Espelha o estado lido no pino de saída do LED azul (GP12).
 */

#include "pico/stdlib.h"

int main() {
    // Pino do LED azul na BitDogLab
    const uint PIN_LED_AZUL = 12;
    // Pino que receberá o sinal do FPGA
    const uint PIN_ENTRADA  = 4; 

    // Inicializa o pino do LED como uma saída
    gpio_init(PIN_LED_AZUL);
    gpio_set_dir(PIN_LED_AZUL, GPIO_OUT);

    // Inicializa o pino de entrada
    gpio_init(PIN_ENTRADA);
    gpio_set_dir(PIN_ENTRADA, GPIO_IN);

    // Loop infinito
    while (true) {
        // A saída do LED espelha diretamente a entrada
        gpio_put(PIN_LED_AZUL, gpio_get(PIN_ENTRADA));
    }
}