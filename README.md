# UART Commander

**UART Commander** é um projeto de controle de hardware embarcado que utiliza comunicação serial UART para enviar comandos que acionam diferentes funcionalidades de um sistema baseado em processador NIOS II. O projeto integra controle de LEDs, lógica de rotação de dados e operações matemáticas, tudo orquestrado através de uma interface de linha de comando.

## Introdução

O **UART Commander** é um sistema de controle embarcado desenvolvido em linguagem assembly NIOS II que implementa um conjunto de funcionalidades acionáveis via comunicação serial (UART). O projeto demonstra conceitos fundamentais de programação em assembly para microcontroladores, incluindo:

### Funcionalidades Principais

1. **LED Control (Comando 00)**
   - Acumula valores de alavancas (switches) de entrada
   - Exibe o valor acumulado nos LEDs verdes
   - Permite reinicialização via botões de controle
   - Exibição simultânea em displays de 7 segmentos

2. **Triangular (Comando 01)**
   - Implementa lógica de processamento numérico
   - Realiza operações trigonométricas ou sequenciais
   - Exibe resultados em displays de 7 segmentos

3. **Número Triangular (Comando 10)**
   - Lê o conteúdo das chaves (8 bits – SW7-SW0)
   - Calcula o respectivo número triangular (1+2+3+...+n)
   - Exibe o resultado nos displays de 7 segmentos em formato decimal

4. **Rotate (Comando 20)**
   - Exibe a frase "Oi 2026" nos displays de 7 segmentos
   - Rotaciona o texto a cada 200ms
   - Alteração de sentido de rotação (KEY1)
   - Pausa/Retomada da rotação (KEY2)

5. **Cancelar Rotação (Comando 21)**
   - Cancela a rotação da palavra
   - Retorna ao estado inicial e pausa a execução

### Objetivo do Projeto

Desenvolver uma aplicação embarcada robusta que demonstra a integração de múltiplos periféricos através de um sistema de fila de comandos UART, com tratamento de interrupções e sincronização de eventos em tempo real.

## Cronograma de Desenvolvimento

TBD

## Arquitetura do Aplicativo

O projeto segue uma arquitetura modular onde cada conjunto de funcionalidades é implementado em um arquivo assembly separado. Isso facilita a manutenção, testes e reutilização do código.

### Estrutura de Arquivos

```
UART_commander/
├── main.s              # Arquivo principal - Orquestração de comandos
├── led.s               # Controle de LEDs e lógica de acumulação
├── triangular.s        # Cálculo de números triangulares
├── rotate.s            # Rotação de texto nos displays
```

### Descrição dos Módulos

#### **main.s** (Arquivo Principal)
- **Responsabilidade**: Orquestração central do sistema
- **Funcionalidades**:
  - Inicializa a UART para comunicação serial
  - Exibe prompt de comando na serial
  - Lê e interpreta comandos do usuário
  - Roteia para os módulos correspondentes através de `call`
  - Implementa o loop principal de polling

#### **led.s** (Controle de LEDs)
- **Responsabilidade**: Gerenciar operações com LEDs e alavancas
- **Comandos Implementados**:
  - `COMM_00`: Acumula valores das alavancas (switches) nos LEDs verdes e displays
  - `COMM_01`: Operações adicionais com LEDs
- **Periféricos Utilizados**:
  - Switches (leitura de entrada)
  - LEDs verdes (saída visual)
  - Displays de 7 segmentos (exibição de valores)

#### **triangular.s** (Números Triangulares)
- **Responsabilidade**: Cálculo de números triangulares
- **Comando Implementado**:
  - `COMM_10`: Lê chaves (SW7-SW0) e calcula o número triangular correspondente
- **Fórmula**: T(n) = 1 + 2 + 3 + ... + n = n×(n+1)/2
- **Saída**: Resultado em decimal nos displays de 7 segmentos

#### **rotate.s** (Rotação de Texto)
- **Responsabilidade**: Controlar rotação de mensagens nos displays
- **Comandos Implementados**:
  - `COMM_20`: Exibe e rotaciona "Oi 2026" a cada 200ms
  - `COMM_21`: Cancela a rotação
- **Controles Dinâmicos**:
  - KEY1: Alterna sentido de rotação (direita ↔ esquerda)
  - KEY2: Pausa/Retoma a rotação
- **Tabela de Dados**: Contém as 4 posições de rotação da mensagem

### Fluxo de Execução

```
UART Commander (main.s)
    │
    ├─→ [Comando "00"] → led.s (COMM_00)
    │                      └─→ Acumula e exibe nos LEDs
    │
    ├─→ [Comando "01"] → led.s (COMM_01)
    │                      └─→ Operações adicionais com LEDs
    │
    ├─→ [Comando "10"] → triangular.s (COMM_10)
    │                      └─→ Calcula e exibe número triangular
    │
    ├─→ [Comando "20"] → rotate.s (COMM_20)
    │                      └─→ Rotaciona "Oi 2026" + controles de botões
    │
    └─→ [Comando "21"] → rotate.s (COMM_21)
                           └─→ Cancela rotação
```

### Integração com Hardware

- **UART**: Comunicação serial para entrada de comandos
- **Switches**: Leitura de valores de entrada (8 bits)
- **LEDs**: Saída visual de status e resultados
- **Botões (KEY1, KEY2)**: Controles dinâmicos durante execução
- **Displays 7-seg**: Exibição de valores em formato visual
- **Timer/Interrupções**: Sincronização de eventos e delays (200ms para rotação)

## Desenvolvimento do Aplicativo

TBD

## Links

Relatório: https://docs.google.com/document/d/1StY9M0XvJlAyz381Gy_JC2evbZyrFpxo1QgINj96hIs/edit?usp=sharing

Cronograma: https://docs.google.com/spreadsheets/d/1FzR0vg-QmrNAaIQtij9g-IKhSwcWRL2wnVDP1aYRW18/edit?usp=sharing