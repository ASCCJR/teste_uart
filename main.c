/**
 * @file main.c
 * @brief BitDogLab #1 - Transmissor UART (Controle Remoto)
 *
 * Fase 1 do projeto Ponte de Protocolo.
 * - Lê os botões A (GPIO5) e B (GPIO6).
 * - Se o Botão A for pressionado, envia o caractere '1' via UART.
 * - Se o Botão B for pressionado, envia o caractere '0' via UART.
 * - A transmissão UART (TX) é feita pelo pino GP0.
 */

#include "pico/stdlib.h"
#include "hardware/uart.h"
#include "hardware/gpio.h"

// --- Configurações da UART ---
#define UART_ID      uart0
#define BAUD_RATE    9600
#define UART_TX_PIN  0 // No Conector I2C0: Este é um conector de 4 pinos.
// O GPIO0 é o pino rotulado como SDA neste conector. 
// Embora o rótulo seja "SDA" (usado para o protocolo I2C), o pino é fisicamente o GPIO0, e nós o configuramos 
// em nosso código C para funcionar como uma saída UART.
#define UART_RX_PIN  1 // Não usado, mas bom definir

// --- Configurações dos Botões ---
#define BUTTON_A_PIN 5
#define BUTTON_B_PIN 6

int main() {
    // Inicializa o stdio, útil para debug via USB se necessário
    stdio_init_all();

    // --- Configuração da UART ---
    // Inicializa a UART com a velocidade definida
    uart_init(UART_ID, BAUD_RATE);
    // Mapeia os pinos GPIO para a função UART
    gpio_set_function(UART_TX_PIN, GPIO_FUNC_UART);
    gpio_set_function(UART_RX_PIN, GPIO_FUNC_UART);

    // --- Configuração dos Botões ---
    // Botão A
    gpio_init(BUTTON_A_PIN);
    gpio_set_dir(BUTTON_A_PIN, GPIO_IN);
    gpio_pull_up(BUTTON_A_PIN); // Essencial! O botão é ativo baixo

    // Botão B
    gpio_init(BUTTON_B_PIN);
    gpio_set_dir(BUTTON_B_PIN, GPIO_IN);
    gpio_pull_up(BUTTON_B_PIN); // Essencial! O botão é ativo baixo


    // Loop principal para sempre
    while (true) {
        // Verifica o Botão A
        // gpio_get retorna 'false' (0) quando o botão é pressionado (ativo baixo)
        if (gpio_get(BUTTON_A_PIN) == false) {
            if (uart_is_writable(UART_ID)) {
                uart_putc_raw(UART_ID, '1');
                // Imprime no terminal USB para sabermos que funcionou
                printf("Botao A pressionado, enviando '1'\n");
            }
        }

        // Verifica o Botão B
        if (gpio_get(BUTTON_B_PIN) == false) {
             if (uart_is_writable(UART_ID)) {
                uart_putc_raw(UART_ID, '0');
                // Imprime no terminal USB para sabermos que funcionou
                printf("Botao B pressionado, enviando '0'\n");
            }
        }

        // Uma pequena pausa para evitar "spam" de caracteres e debounce
        sleep_ms(100);
    }
}