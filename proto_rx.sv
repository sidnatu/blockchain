// reciever protocol
// from the Python (<IQIB)
// [0...3] = last proof
// [4..11] = start nonce
// [12..15] = batch_size
// 16 zeros

module proto_rx (
    input logic clk,
    input logic rst_n,

    input logic rx_byte_valid,
    input logic [7:0] rx_byte,

    output logic cmd_valid,
    output logic [31:0] last_proof,
    output logic [63:0] start_nonce,
    output logic [31:0] batch_size,
    output logic [7:0] zeros
);

logic [4:0] idx_q, idx_d;

//temps
logic [31:0] lp_q, lp_d; //last proof
logic [63:0] sn_q, sn_d; //start_nonce
logic [31:0] bs_q, bs_d; //batch size
logic [7:0] z_q, z_d; //zeros

logic frame_done;

assign cmd_valid = frame_done;

// -----------
// Comb logic
// -----------
always_comb begin
    idx_d = idx_q;
    lp_d = lp_q;
    sn_d = sn_q;
    bs_d = bs_q;
    z_d = z_q;

    frame_done = 1'b0;

    if(rx_byte_valid) begin
        unique case (idx_q)
        5'd0: lp_d[7:0] = rx_byte;
        5'd1: lp_d[15:8] = rx_byte;
        5'd2: lp_d[23:16] = rx_byte;
        5'd3: lp_d[31:24] = rx_byte;

        5'd4: sn_d[7:0] = rx_byte;
        5'd5: sn_d[15:8] = rx_byte;
        5'd6: sn_d[23:16] = rx_byte;
        5'd7: sn_d[31:24] = rx_byte;
        5'd8: sn_d[39:32] = rx_byte;
        5'd9: sn_d[47:40] = rx_byte;
        5'd10: sn_d[55:48] = rx_byte;
        5'd11: sn_d[63:56] = rx_byte;

        5'd12: bs_d[7:0] = rx_byte;
        5'd13: bs_d[15:8] = rx_byte;
        5'd14: bs_d[23:16] = rx_byte;
        5'd15: bs_d[31:24] = rx_byte;
        
        5'd16: z_d = rx_byte;
        default: ;
        endcase
        if (idx_q == 5'd16)begin
            idx_d = 5'd0;
            frame_done = 1'b1;
        end else begin
            idx_d = idx_q + 5'd1;
        end
    end
end

// ----------------
// Sequential logic
// ----------------

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        idx_q <= '0;
        lp_q <= '0;
        sn_q <= '0;
        bs_q <= '0;
        z_q <= '0;
        last_proof <= '0;
        start_nonce <= '0;
        batch_size <= '0;
        zeros <= '0;
    end else begin
        idx_q <= idx_d;
        lp_q <= lp_d;
        sn_q <= sn_d;
        bs_q <= bs_d;
        z_q <= z_d;

        if (frame_done) begin
            last_proof <= lp_d;
            start_nonce <= sn_d;
            batch_size <= bs_d;
            zeros <= z_d;
        end
    end
end
endmodule