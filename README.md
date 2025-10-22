# UART Protocol Bridge - FPGA Colorlight i9

![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)
![FPGA](https://img.shields.io/badge/FPGA-Colorlight%20i9-blue)
![Protocolo](https://img.shields.io/badge/Protocolo-UART-green)

## Sobre o Projeto

Este projeto demonstra a implementação de uma ponte de protocolo (*Protocol Bridge*) utilizando um FPGA Colorlight i9. O objetivo é servir como um exemplo fundamental de como FPGAs podem ser usados para "traduzir" sinais entre diferentes interfaces de comunicação em hardware.

O sistema é composto por três componentes principais:
- **Controle Remoto**: BitDogLab #1
- **Unidade de Processamento**: FPGA Colorlight i9
- **Atuador**: BitDogLab #2

---

## Como Funciona

O fluxo de comunicação ocorre da seguinte maneira:

```
[BitDogLab #1] --(UART)--> [FPGA Colorlight i9] --(GPIO)--> [BitDogLab #2]
```

1.  A **BitDogLab #1** lê o estado de seus botões e envia comandos via protocolo UART.
2.  O **FPGA** recebe esses comandos e os traduz em tempo real.
3.  Com base no comando recebido, o FPGA controla um pino de saída GPIO (nível lógico alto ou baixo).
4.  A **BitDogLab #2** lê o estado desse pino GPIO e acende ou apaga seu LED correspondente.

---

## Estrutura do Projeto

```
.
├── top.v            # Módulo principal do projeto Verilog
├── uart_rx.v        # Módulo de recepção UART em Verilog
├── bridge.lpf       # Arquivo de constraints do FPGA (pinagem, clocks)
├── main.c           # Código para a BitDogLab #1 (transmissor)
├── main2.c          # Código para a BitDogLab #2 (receptor)
└── README.md        # Documentação do projeto
```

---

## Status Atual

** Parte 1 - Implementação UART**

A implementação atual permite que o FPGA compreenda o protocolo UART enviado pela **BitDogLab #1**. Com isso, o FPGA agora possui uma interface de recepção UART funcional.

---

## 🗺️ Roadmap - Próximos Passos

O próximo grande passo é migrar a comunicação de UART para I2C.

### Arquitetura Proposta

```
[BitDogLab #1] --(I2C)--> [FPGA] --(GPIO)--> [BitDogLab #2]
```

### 1. BitDogLab #1 (O Transmissor)

**Novo Papel**: Mestre I2C (em vez de transmissor UART).

| Aspecto | Detalhes |
| :--- | :--- |
| **Novo Código** | Programa em C usando a biblioteca I2C do Pico SDK. |
| **Novas Conexões** | • **SDA** (dados) → GP0 do conector I2C0<br>• **SCL** (clock) → GP1 do conector I2C0 |
| **Novo Comando** | Em vez de enviar '''1''' via UART, enviará um comando I2C.<br>📨 Exemplo: `"Dispositivo 0x42, receba: 0x01"` |

### 2. FPGA (A Ponte)

**Novo Papel**: Escravo I2C (em vez de receptor UART).

**Mudanças Necessárias**:
- **Substituir**: O módulo `uart_rx.v` será substituído por um novo `i2c_slave.v`.
- **Novo Código Verilog**: O módulo `i2c_slave.v` deverá ter as seguintes funcionalidades:
  - Monitorar os pinos SDA e SCL para detectar condições de *start* e *stop*.
  - Reconhecer o endereço do FPGA no barramento (ex: `0x42`).
  - Enviar um *acknowledge bit* (ACK) de volta ao mestre no tempo correto.
  - Receber o byte de dados (ex: `0x01`) após o endereço.
- **Lógica de Saída**: A lógica de controle do LED permanecerá a mesma:
  - Se o dado recebido for `0x01` → Liga o LED.
  - Se o dado recebido for `0x00` → Desliga o LED.

### 3. BitDogLab #2 (O Receptor)

**Nenhuma alteração necessária.**

A BitDogLab #2 é agnóstica à origem do sinal GPIO. Seu código e funcionamento permanecem os mesmos.

---