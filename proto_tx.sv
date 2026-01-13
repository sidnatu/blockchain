//transmitter protocol
// needs to package output of miner into something the computer expects


module proto_tx (

    input logic clk,
    input logic rst_n,

    input logic result_valid,
    input logic result_found,
    input logic [63:0] result_nonce,
    input logic tx_busy,

    output logic result_ready,
    output logic send,
    output logic [7:0] tx_data
);

    typedef enum logic {
        S_IDLE,
        S_SEND_STATUS,
        S_WAIT_STATUS,
        S_SEND_NONCE,
        S_WAIT_NONCE
    } state_t;

    state_t state, next_state;

    logic [63:0] nonce_reg;
    logic [2:0] byte_idx;

     always_comb begin
        send = 1'b0;
        tx_data = 8'h00;
        result_ready = 1'b0;

        next_state = state;

        case(state)

            S_IDLE: begin
                result_ready = 1'b1;
                if (result_valid) begin
                    next_state = S_SEND_STATUS;
                end
            end

            S_SEND_STATUS: begin
                if(!tx_busy) begin
                    tx_data = result_found ? 8'h01 : 8'h00;
                    send = 1'b1;
                    next_state = S_WAIT_STATUS;
                end
            end

            S_WAIT_STATUS: begin
                if(!tx_busy) begin
                    if (result_found)
                        next_state = S_SEND_NONCE;
                    else
                        next_state = S_IDLE;
                end
            end

            S_SEND_NONCE: begin
                if (!tx_busy) begin
                    tx_data = nonce_reg[7:0];
                    send = 1'b1;
                    next_state = S_WAIT_NONCE;
                end
            end

            S_WAIT_NONCE: begin
                if (!tx_busy) begin
                    if (byte_idx == 3'd7)
                        next_state = S_IDLE;
                    else
                        next_state = S_SEND_NONCE;
                end
            end

            default: next_state = S_IDLE;
        endcase        
     end

     always_ff @(posedge clk) begin
        state <= next_state;

        if (state == S_IDLE && result_valid) begin
            nonce_reg <= result_nonce;
            byte_idx <= 3'd0;
        end

        if (state == S_WAIT_NONCE && !tx_busy)begin
            nonce_reg <= {8'h00, nonce_reg[63:8]};
            byte_idx <= byte_idx + 3'd1;
        end        
     end
endmodule