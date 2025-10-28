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
    input logic rst, //active-low i think?
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
//----------------------
//Fractional N-Baud Tick
//  Generates a tick at baud * oversample
//----------------------
localparam longint unsigned incr_num = baud * oversample;
localparam longint unsigned incr_den = clk_hz;
localparam int unsigned incr = int'(((incr_num << ACC_width) + (incr_den/2)) / incr_den);

logic [ACC_width:0] phase; // one extra bit for carry
logic os_tick; //oversample tick

always_ff @(posedge clk) begin
    if (rst) begin
        phase <= '0;
        os_tick <= 1'b0; 
    end else begin
        // accumulate; when most sig bit toggles, emit a tick
        logic [ACC_width:0] nextphase = phase + incr;
        os_tick <= nextphase[ACC_width]; //carry becomes the tick
        phase <= {1'b0, nextphase[ACC_width-1:0]}; //drop carry
    end
end
//----------------------
//RECIEVER STATE MACHINE (16x oversample)
//----------------------

typedef enum logic [2:0] {IDLE, START, DATA, STOP } state_t;

state_t state;

logic [$clog2(oversample)-1:0] sample_count; //counts 0->15
logic [2:0] bit_index;
logic [7:0] shreg;

//defaults

always_comb begin
    valid = 1'b0;
    framing_err = 1'b0;
    busy = (state != IDLE);
end

always_ff @(posedge clk) begin
    if(rst) begin
        state <= IDLE;
        sample_count <= '0;
        bit_index <= '0;
        shreg <= '0;
        data <= '0;
    end else begin
        if (os_tick) begin
            unique case (state)
                IDLE: begin
                    if (rx_sync == 1'b0) begin
                        state <= START;
                        sample_count = '0;
                    end
                end

                START: begin
                    if (sample_count == (oversample/2-1)) begin
                        if (rx_sync == 1'b0)begin
                            state <= DATA;
                            sample_count <= '0;
                            bit_index <= 3'd0;
                        end else begin
                            state <= IDLE;
                        end
                    end else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end

                DATA: begin
                    if (sample_count == (oversample - 1)) begin
                        sample_count <= '0;
                        shreg <= {rx_sync, shreg[7:1]};
                        if (bit_index == 3'd7)begin
                            state = STOP;
                        end else begin
                            bit_index <= bit_index + 3'd1;
                        end
                    end else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end


                STOP: begin
                    if (sample_count == (oversample - 1)) begin
                        sample_count <= '0;
                        data <= shreg;
                        valid <= 1'b1;
                        if (rx_sync == 1'b0) begin
                            framing_err <= 1'b1;
                        end
                        state <= IDLE;
                    end else begin
                        sample_count <= sample_count + 1'b1;
                    end
                end 
                endcase
        end
    end
end
endmodule
