module padder (
    input logic [31:0] last_proof,
    input logic [63:0] nonce,

    output logic [511:0] padded_block
);

always_comb begin
  padded_block = '0; //initalizes output to zero

  //switches the padded block to LSByte first to allow the SHA-256 module to use this padded block

  padded_block[511:480] = { last_proof[7:0], last_proof[15:8], last_proof[23:16], last_proof[31:24] };

  padded_block[479:448] = { nonce[7:0], nonce[15:8], nonce[23:16], nonce[31:24] };

  padded_block[447:416] = { nonce[39:32], nonce[47:40], nonce[55:48], nonce[63:56] };

  padded_block[415:408] = 8'h80;

  padded_block[63:0] = 64'h0000000000000060;
end

endmodule