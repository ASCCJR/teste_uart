// Módulo Genérico de Receptor UART (RX)
module uart_rx #(
    // Parâmetros
    parameter CLK_FREQ = 25_000_000, // A velocidade do clock principal do FPGA
    parameter BAUD_RATE = 9600      // A "velocidade" da comunicação UART que
                                    // esperamos. DEVE ser igual à da BitDogLab #1.
)(
    // Portas (Pinos de entrada e saída do módulo)
    input wire clk,       // Entrada: O clock de 25MHz do FPGA
    input wire rx_in,     // Entrada: O pino que recebe os dados da BitDogLab #1
    output reg [7:0] rx_data, // Saída: Onde o byte de 8 bits recebido será colocado
    output reg rx_ready    // Saída: Um pulso rápido para avisar que um novo
                           //        dado está pronto em 'rx_data'
);

    // Constante local: Calcula quantos ciclos de clock do nosso FPGA
    // cabem dentro da duração de UM ÚNICO bit da UART.
    // Ex: 25.000.000 / 9600 = ~2604. 
    // Isso é crucial. Usaremos esse número para saber quanto tempo esperar.
    localparam DIVISOR = CLK_FREQ / BAUD_RATE;
    
    // Registradores (Memória interna do módulo)
    reg [1:0] state = 0;       // Guarda o estado atual da "Máquina de Estados"
                               // 0=IDLE, 1=START, 2=DATA, 3=STOP
    reg [3:0] bit_count = 0;   // Conta qual bit (de 0 a 7) estamos lendo
    reg [15:0] clk_count = 0;  // Conta os ciclos de clock (de 0 a 2603) para
                               // medir o tempo de um bit.
    reg [7:0] data_reg = 0;    // Um registrador temporário para "montar"
                               // o byte bit a bit.

    // O "Coração" do módulo: Este bloco é executado em CADA
    // pulso de subida (posedge) do clock de 25MHz.
    always @(posedge clk) begin
        // Regra padrão: Mantemos o sinal 'rx_ready' em 0.
        // Ele só ficará em 1 por um único ciclo, lá no final.
        rx_ready <= 0;

        // Máquina de Estados: O cérebro que controla o processo.
        case(state)
            // ESTADO 0: "IDLE" (Ocioso)
            // A linha UART fica em 1 (ALTA) quando nada é enviado.
            0: begin 
                // Estamos monitorando 'rx_in'. Se ela cair para 0...
                if (rx_in == 0) begin
                    // ...significa que um "Start Bit" começou!
                    clk_count <= 0; // Zera o contador de tempo
                    state <= 1;     // Vai para o próximo estado
                end
            end
            
            // ESTADO 1: "START"
            // O "Start Bit" chegou. Queremos ler o sinal bem no MEIO
            // do bit, não na borda (para evitar erros).
            1: begin 
                // Espera METADE do tempo de um bit (DIVISOR/2)
                if (clk_count == DIVISOR/2) begin
                    clk_count <= 0; // Zera o contador de tempo
                    bit_count <= 0; // Prepara para ler o primeiro bit (bit 0)
                    state <= 2;     // Vai para o estado de leitura de dados
                end else begin
                    clk_count <= clk_count + 1; // Continua contando...
                end
            end
            
            // ESTADO 2: "DATA"
            // O estado mais importante. Lê os 8 bits de dados, um por um.
            2: begin 
                // Espera um tempo de bit COMPLETO (DIVISOR - 1)
                // Isso nos coloca no MEIO do próximo bit de dado.
                if (clk_count == DIVISOR - 1) begin
                    clk_count <= 0; // Zera o contador de tempo
                    
                    // Lê o pino 'rx_in' e armazena o valor (0 ou 1)
                    // na posição correta do nosso registrador temporário.
                    data_reg[bit_count] <= rx_in;
                    
                    // Verifica se já lemos todos os 8 bits
                    if (bit_count == 7) begin
                        state <= 3; // Sim! Vai para o estado "STOP"
                    end else begin
                        // Não, ainda faltam bits.
                        bit_count <= bit_count + 1; // Incrementa o contador de bits
                    end
                end else begin
                    clk_count <= clk_count + 1; // Continua contando...
                end
            end
            
            // ESTADO 3: "STOP"
            // Já lemos os 8 bits. Agora só precisamos esperar
            // o "Stop Bit" passar (que é sempre 1).
            3: begin 
                // Espera mais um tempo de bit completo
                if (clk_count == DIVISOR - 1) begin
                    // TAREFA CUMPRIDA!
                    // 1. Coloca o byte montado na saída do módulo
                    rx_data <= data_reg;
                    // 2. Levanta a bandeira 'rx_ready' por UM ciclo!
                    rx_ready <= 1; 
                    // 3. Volta ao estado inicial para esperar o próximo byte
                    state <= 0; 
                end else begin
                    clk_count <= clk_count + 1; // Continua contando...
                end
            end
        endcase
    end
endmodule