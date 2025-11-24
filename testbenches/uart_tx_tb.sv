`timescale 1ns/10ps

module uart_tx_tb();

  parameter c_CLOCK_PERIOD_NS = 20;
  parameter c_CLKS_PER_BIT    = 434;
  parameter c_BIT_PERIOD      = 8680;

  reg r_Clock = 0;
  reg r_TX_DV = 0;
  wire w_TX_Active, w_UART_Line;
  wire w_TX_Serial;
  reg [7:0] r_TX_Byte = 0;
  wire [7:0] w_RX_Byte;

  reg prev;

  UART_TX #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_TX_INST (
    .i_Clock(r_Clock),
    .i_TX_DV(r_TX_DV),
    .i_TX_Byte(r_TX_Byte),
    .o_TX_Active(w_TX_Active),
    .o_TX_Serial(w_TX_Serial),
    .o_TX_Done()
  );

  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;

  initial begin

    prev = w_TX_Serial;

    @(posedge r_Clock);
    r_TX_Byte <= 8'b0000_1111;
    @(posedge r_Clock);

    r_TX_DV <= 1'b1;
    @(posedge r_Clock);
    r_TX_DV <= 1'b0;

    wait(w_TX_Active);

    while (w_TX_Active) begin
        @(posedge r_Clock);
        if (w_TX_Serial != 0) begin
        $display("Serial output: %b", w_TX_Serial);
        end
        prev = w_TX_Serial;
    end
    @(posedge r_Clock);
    @(posedge r_Clock);
  end





endmodule