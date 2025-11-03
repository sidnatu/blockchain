//uart transmitter

module uart_tx #(
    parameter bit LSB_FIRST = 1'b1,
    parameter int unsigned DATA_BITS = 8
)  (
    input logic clk,
    input logic rst_n,
    input logic tick_baud,
    
    input logic in_valid,
    input logic [7:0] in_data, 

    output logic in_ready,
    output logic tx,
    output logic busy
);

// -------------
// STATE MACHINE
// -------------

typedef enum logic [1:0] {S_IDLE, S_START, S_DATA, S_STOP  } state_t;
state_t st_q, st_d;

localparam int BIT_CNT_W = (DATA_BITS <= 1) ? 1 : $clog2(DATA_BITS);
logic [DATA_BITS-1:0] sh_q, sh_d;
logic [BIT_CNT_W-1:0] bit_cnt_q,bit_cnt_d;
logic loadbyte;

assign in_ready = (st_q == S_IDLE);
assign busy = (st_q != S_IDLE);

always_comb begin
    st_d = st_q;
    sh_d = sh_q;
    bit_cnt_d = bit_cnt_q;

    loadbyte = 1'b0;

    case (st_q)
     default: ;
    endcase

    if (st_q == S_IDLE && in_valid) begin
        loadbyte = 1'b1;
        st_d = S_START;
    end

    if (tick_baud) begin
        unique case (st_q)

         S_IDLE: begin
            
         end

         S_START: begin
            st_d = S_DATA;
            bit_cnt_d = 3'd0;
         end

         S_DATA: begin
            if (bit_cnt_q == DATA_BITS-1) begin
                st_d = S_STOP;
            end else begin
                bit_cnt_d = bit_cnt_q + 3'd1;
            end
            if (LSB_FIRST) sh_d = {1'b0, sh_q[DATA_BITS-1:1]};
            else sh_d = {sh_q[DATA_BITS-2:0], 1'b0};
         end
         
         S_STOP: begin
            st_d = S_IDLE;
         end
        endcase
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        st_q <= S_IDLE;
        sh_q <= '0;
        bit_cnt_q <= '0;
        tx <= 1'b1;
    end else begin
        if (loadbyte) begin
            sh_q <= in_data;
        end else begin
            sh_q <= sh_d;
        end
        st_q <= st_d;
        bit_cnt_q <= bit_cnt_d;

        if (tick_baud) begin
            unique case (st_q)
             S_IDLE: tx <= 1'b1;
             S_START: tx <= 1'b0;
             S_DATA: tx <= LSB_FIRST ? sh_q[0] : sh_q[DATA_BITS-1];
             S_STOP: tx <= 1'b1;
            endcase
        end
    end
end
endmodule