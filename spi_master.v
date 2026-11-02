module spi_master (
    input wire clk,           // Системний тактовий сигнал
    input wire rst,           // Сигнал скидання (асинхронний, активний 1)
    input wire start,         // Сигнал початку передачі даних
    input wire [7:0] data_in, // Дані для передачі (Tx)
    input wire miso,          // Лінія прийому від Slave (Master In Slave Out)
    
    output reg mosi,          // Лінія передачі до Slave (Master Out Slave In)
    output reg sck,           // Тактовий сигнал SPI
    output reg ss,            // Сигнал вибору Slave (Slave Select, активний 0)
    output reg [7:0] data_out,// Прийняті дані (Rx)
    output reg done           // Прапорець завершення операції
);

    // Стани кінцевого автомата (FSM)
    localparam IDLE     = 2'b00; // Очікування
    localparam START    = 2'b01; // Ініціалізація передачі
    localparam TRANSFER = 2'b10; // Передача бітів
    localparam DONE     = 2'b11; // Завершення

    reg [1:0] state;      // Регістр поточного стану
    reg [2:0] bit_cnt;    // Лічильник бітів (від 7 до 0)
    reg [7:0] shift_reg;  // Зсувний регістр для прийому/передачі

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Скидання всіх регістрів у початковий стан
            state <= IDLE;
            mosi <= 1'b0;
            sck <= 1'b0;
            ss <= 1'b1; // Неактивний стан (високий рівень)
            done <= 1'b0;
            bit_cnt <= 3'd7;
            shift_reg <= 8'd0;
            data_out <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    ss <= 1'b1;
                    sck <= 1'b0;
                    done <= 1'b0;
                    if (start) begin
                        state <= START;
                        shift_reg <= data_in; // Завантажуємо дані для передачі
                        bit_cnt <= 3'd7;       // Починаємо зі старшого біта
                    end
                end
                
                START: begin
                    ss <= 1'b0; // Опускаємо SS в нуль (активуємо Slave)
                    sck <= 1'b0;
                    state <= TRANSFER;
                end
                
                TRANSFER: begin
                    sck <= ~sck; // Генеруємо тактовий імпульс (перемикаємо SCK)
                    
                    if (sck == 1'b0) begin
                        // Передній фронт (SCK йде в 1): видаємо біт на лінію MOSI
                        mosi <= shift_reg[bit_cnt];
                    end else begin
                        // Задній фронт (SCK йде в 0): зчитуємо біт з лінії MISO
                        shift_reg[bit_cnt] <= miso;
                        
                        if (bit_cnt == 3'd0) begin
                            state <= DONE; // Якщо передали всі 8 біт - завершуємо
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1; // Перехід до наступного біта
                        end
                    end
                end
                
                DONE: begin
                    ss <= 1'b1; // Деактивуємо Slave
                    sck <= 1'b0;
                    done <= 1'b1; // Сигналізуємо про завершення
                    data_out <= shift_reg; // Видаємо прийнятий байт на вихід
                    state <= IDLE; // Повертаємось в очікування
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule