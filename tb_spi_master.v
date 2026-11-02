`timescale 1ns / 1ps

module tb_spi_master();
    reg clk;
    reg rst;
    reg start;
    reg [7:0] data_in;
    reg miso;

    wire mosi;
    wire sck;
    wire ss;
    wire [7:0] data_out;
    wire done;

    spi_master uut (
        .clk(clk), .rst(rst), .start(start), .data_in(data_in),
        .miso(miso), .mosi(mosi), .sck(sck), .ss(ss),
        .data_out(data_out), .done(done)
    );

    always #5 clk = ~clk; // Генерація CLK

    initial begin
        clk = 0; rst = 1; start = 0; miso = 0;
        data_in = 8'b10100101; // Подача тестових даних на вхід передавача (Тх)
        
        #20 rst = 0;
        #20 start = 1;
        #10 start = 0;

        #30 miso = 1; // Імітація передачі даних від іншого пристрою (Rx)
        #40 miso = 0;
        #40 miso = 1;
        
        wait(done);
        #50 $stop;
    end
endmodule