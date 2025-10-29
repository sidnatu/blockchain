// baud_generator
//works for 50 MHz -> 115200 baud with 16X oversample (RX) and precise transmitter 1X.

module baud_generator #(
    parameter int unsigned CLK_HZ = 50_000_000,
    parameter int unsigned BAUD = 115_200,
    parameter int unsigned OVERSAMPLE = 16,
    parameter int unsigned ACC_WIDTH = 24
) (
    input logic clk,
    input logic rst_n,

    //One-clock strobes
    output logic tick_oversample, //fires at BAUD * OVERSAMPLE
    output logic tick_baud //fires at BAUD
    output logic tick_sample //fires mid-bit
);

// -------------------
// Compile-time checks
// -------------------

initial begin
    if (OVERSAMPLE < 2 || (OVERSAMPLE % 2) != 0)
        $error("baud_gen: OVERSAMPLE must be even and greater= 2");
    if (CLK_HZ == 0 || BAUD == 0)
        $error("baud_gen: CLK_HZ and BAUD must be nonzero");
    if (ACC_WIDTH < 8)
        $error("baud_gen: ACC_WIDTH too small")
end

// ---------------------------------
// Fixed-point increment calculation:
// ---------------------------------

localparam longint unsigned INC_NUM = longint'(BAUD) * longint'(OVERSAMPLE) * (1ULL << ACC_WIDTH);
localparam longint unsigned INC = (INC_NUM + (CLK_HZ/2)) / longint'(CLK_HZ);

initial begin
    if (INC == 0 )
        $error("baud_gen: computed INC=0;");
    if (INC >= (1ULL << ACC_WIDTH))
        $error("baud_gen: computed increment overflows")
end

//----------------
// NCO Accumulator
//----------------

logic [ACC_WIDTH-1:0] acc_q, acc_d;
logic carry;

always_comb begin
    // add the fixed increment
    logic [ACC_WIDTH:0] sum;
    sum = {1'b0, acc_q} + INC[ACC_WIDTH-1:0];
    acc_d = sum[ACC_WIDTH-1:0];
    carry = sum[ACC_WIDTH];
end

localparam int unsigned OS_W = $clog2(OVERSAMPLE);
logic [OS_W-1:0] os_cnt_q;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        acc_q <= '0;
        tick_oversample <= 1'b0;
        tick_baud <= 1'b0;
        tick_sample <= 1'b0;
        os_cnt_q <= '0;
    end else begin
        tick_oversample <= 1'b0;
        tick_baud <= 1'b0;
        tick_sample <= 1'b0;

        acc_q <= acc_d;

        if (carry) begin
            tick_oversample <= 1'b1;

            if (os_cnt_q == OVERSAMPLE - 1) begin
                os_cnt_q <= '0;
                tick_baud <= 1'b1;
            end else begin
                os_cnt_q <= os_cnt_q + 1'b1;
            end

            if (os_cnt_q == (OVERSAMPLE/2 - 1)) begin
                tick_sample <= 1'b1;
            end
        end
    end
end
endmodule