# UART Protocol Bridge - FPGA Colorlight i9

## Descrição do Projeto

Este projeto implementa uma ponte de protocolo (Protocol Bridge) utilizando um FPGA Colorlight i9. O sistema é composto por três componentes principais:

- **Controle Remoto**: BitDogLab #1
- **Unidade de Processamento**: FPGA Colorlight i9
- **Atuador**: BitDogLab #2

## Como Funciona

1. A **BitDogLab #1** lê o estado de seus botões e envia comandos via protocolo UART
2. O **FPGA** recebe esses comandos e os traduz em tempo real
3. O FPGA controla um pino de saída GPIO (Alto/Baixo)
4. A **BitDogLab #2** lê esse pino GPIO e acende ou apaga seu LED de acordo

## Objetivo

Este projeto é um exemplo fundamental de como FPGAs podem ser usados para "traduzir" entre diferentes interfaces de comunicação em hardware.

## Arquivos do Projeto

- `top.v` - Módulo principal do projeto
- `uart_rx.v` - Módulo de recepção UART
- `bridge.lpf` - Arquivo de constraints do FPGA
- `readme` - Este arquivo

## Status Atual

**Parte 1 - Implementação UART**

Se der certo, então conseguimos "ensinar" o FPGA a entender o protocolo UART vindo da BitDogLab #1. Portanto, o FPGA agora possui uma interface de recepção UART funcional.

---

## Próximos Passos - Migração para I2C

### Arquitetura Proposta

```
[BitDogLab #1] --- (Protocolo I2C) ---> [FPGA] --- (Protocolo GPIO) ---> [BitDogLab #2]
```

### 1️⃣ BitDogLab #1 (O Transmissor)

**🔄 Novo Papel**: Mestre I2C (em vez de transmissor UART)

#### 📝 Mudanças Necessárias

| Aspecto | Detalhes |
|---------|----------|
| **💻 Novo Código** | Programa em C usando a biblioteca I2C do Pico SDK |
| **🔌 Novas Conexões** | • **SDA** (dados) → GP0 do conector I2C0<br>• **SCL** (clock) → GP1 do conector I2C0 |
| **📡 Novo Comando** | Em vez de enviar `'1'` via UART, envia comando I2C<br>📨 Exemplo: `"Dispositivo 0x42, receba: 0x01"` |

### 2. FPGA (A Ponte)

**Novo Papel**: Escravo I2C (em vez de receptor UART)

**Mudanças Necessárias**:
- **Substituir**: `uart_rx.v` → criar `i2c_slave.v`
- **Novo Código Verilog**: Módulo I2C slave com as seguintes funcionalidades:
  - Monitorar pinos SDA e SCL para detectar "start" e "stop bits"
  - Ouvir o barramento e reconhecer o endereço do FPGA (ex: 0x42)
  - Enviar "acknowledge bit" (ACK) de volta ao mestre no tempo exato
  - Receber byte de dados (0x01) após o endereço
- **Lógica de Saída**: Similar ao atual
  - Se dado recebido = 0x01 → Liga LED
  - Se dado recebido = 0x00 → Desliga LED

### 3. BitDogLab #2 (O Receptor)

Sem alterações necessárias

A BitDogLab #2 não se importa com a origem do sinal GPIO (ponte UART ou I2C). O código permanece o mesmo.