// Módulo Principal - Ponte UART para GPIO
module top (
    input wire clk,       // Clock de 25MHz
    input wire uart_rx,   // Pino de entrada da UART (vem da BitDogLab #1)
    output wire led_out   // Pino de saída (vai para a BitDogLab #2)
);
    // Conexões "virtuais",  dentro do FPGA
    wire [7:0] received_data; // receber o byte do 'uart_rx'
    wire       data_ready;    // receber o sinal 'pronto' do 'uart_rx'

    // Registrador (Memória): Guarda o estado atual do LED (0=desligado, 1=ligado).
    // Isso é crucial! Sem um 'reg', o LED só acenderia por um
    // ciclo de clock. O 'reg' "segura" o valor.
    reg led_state = 0;

    // "Instanciação" do Módulo Receptor UART:
    // Estamos efetivamente "colando" o módulo uart_rx DENTRO do top.v
    // Damos a ele um nome (uart_receiver) e conectamos suas portas:
    uart_rx uart_receiver (
        .clk(clk),               // Conecta o clock principal ao .clk do receptor
        .rx_in(uart_rx),         // Conecta o pino uart_rx ao .rx_in do receptor
        .rx_data(received_data), // Conecta o .rx_data do receptor
        .rx_ready(data_ready)    // Conecta o .rx_ready do receptor
    );

    // Lógica de Controle
    // Ele roda em paralelo com o receptor UART.
    always @(posedge clk) begin
        
        // Estamos constantemente monitorando o 'data_ready'.
        // 99.99% do tempo, ele está em 0.
        // Quando o 'uart_rx' o coloca em 1 por um ciclo:
        if (data_ready) begin
            
            // UM NOVO DADO CHEGOU! Vamos ver o que é.
            // O dado está disponível no 'received_data'.
            
            // Verificamos se o dado recebido é o caractere "1"
            if (received_data == "1") begin // "1" em ASCII é 00110001
                led_state <= 1; // Se for, manda ligar o LED (muda a memória)
            
            // Verificamos se o dado recebido é o caractere "0"
            end else if (received_data == "0") begin // "0" em ASCII é 00110000
                led_state <= 0; // Se for, manda desligar o LED (muda a memória)
            end
            
            // Se for qualquer outro caractere, não fazemos nada.
            // O 'led_state' continua como estava.
        end
    end

    // Tarefa final: Conectar fisicamente o pino de SAÍDA 'led_out'
    // ao valor que está na nossa memória 'led_state'.
    // 'assign' significa uma conexão contínua, direta.
    assign led_out = led_state;

endmodule