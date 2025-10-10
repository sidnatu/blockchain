// uart_reciever - 8-N-1 (8 data bits, no parity, one stop bit) 16x oversampling
// inputs: clk_hz, baud, oversample
//outputs: valid pulse with data and set flags

module uart_rx # (
    parameter int unsigned clk_hz = 50_000_000,
    parameter int unsigned baud = 115_200,
    parameter int unsigned oversample = 16,
    parameter int unsigned ACC_width = 24 //width for nco phase accumulator

)(
    input logic clk,
    input logic reset, //active-low i think?
    input logic rx_i, //async input from python code

    output logic [7:0] data,
    output logic valid, //1 clk pulse when data is fresh
    output logic framing_err, //stop bit was not high
    output logic busy //high while recieving frame

);

//SYNCHRONIZING RX to the clock

logic rx_meta, rx_sync;
always_ff @(posedge clk) begin
    
    if rst begin
        rx_meta <= 1'b1;
        rx_sync <= 1'b1;
    end else begin
        rx_meta <= rx_i;
        rx_sync <= rx_meta;
    end
end

//Fractional N-Baud Tick
//  Generates a tick at baud * oversample

localparam longint unsigned incr_num = baud * oversample;
localparam longint unsigned incr_den = clk_hz;
localparam int unsigned incr = int'(((incr_num << ACC_width) + (incr_den/2)) / incr_den);

logic [ACC_width:0] phase // one extra bit for carry
logic os_tick; //oversample tick

always_ff @(posedge clk) begin
    if (rst) begin
        phase <= `0;
        os_tick <= 1'b0;
    end else begin
        // accumulate; when most sig bit toggles, emit a tick
        logic [ACC_width:0] nextphase = phase + incr;
        os_tick = <= nextphase[ACC_width]; //carry becomes the tick
        phase <= {1'b0, nextphase[ACC_width:0]}; //drop carry
    end
end



endmodule
