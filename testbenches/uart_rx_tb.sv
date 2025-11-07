module uart_rx_tb();
//inputs
logic sim_clk, sim_rst, sim_rx_i;
//outputs
logic [7:0] sim_data;
logic sim_valid,sim_framing_err,sim_busy;

//instantiating the DUT

uart_rx #(50_000_000, 115_200, 16, 24) DUT (
    .clk(sim_clk),
    .rst(sim_rst),
    .rx_i(sim_rx_i),
    .data(sim_data),
    .valid(sim_valid),
    .framing_err(sim_framing_err),
    .busy(sim_busy)
);

localparam int unsigned CLK_HZ = 50_000_000;
localparam int unsigned BAUD = 115_200;

localparam int BAUD_TICKS = CLK_HZ/BAUD;

task automatic drive_bit (input logic b);
    begin
        sim_rx_i = b;
        repeat(BAUD_TICKS) @(posedge sim_clk);
    end
endtask

task automatic drive_byte(input logic [7:0] in_byte);
    int i;
    begin
        drive_bit(1'b0);
        for (i = 0; i < 8; i++) begin
            drive_bit(in_byte[i]);
        end
        drive_bit(1'b1);
        repeat (BAUD_TICKS) @(posedge sim_clk);
    end 
endtask

//starting the clock

initial begin
    sim_clk = 1'b0;
end

always #10 sim_clk = ~sim_clk; //50 Mhz;

// starting actual testing

initial begin
    $display("Testing if reset works. Data should always be zero.");
    sim_rx_i = 1'b1;
    sim_rst = 1'b1;

    repeat (100) @(posedge sim_clk);

    if (sim_data != 8'b0)
    $display("Error, data is being driven by something.");

    // now testing inputs

    sim_rst = 1'b0;
    repeat (50) @(posedge sim_clk);

    drive_byte(8'h0F);
    wait(sim_valid);
    @(posedge sim_clk);
    if (sim_framing_err != 1'b0)
    $display("Unexpected framing error.");
    if (sim_data !== 8'b0000_1111)
    $display("Data is not getting the output.");


end










endmodule


