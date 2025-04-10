module uart_tx #
(
  parameter CLK_FREQ  = 100_000_000,
  parameter BAUD_RATE = 9600
)
(
  input  wire      clk,
  input  wire      resetn,
  input  wire      tx_start,
  input  wire [7:0] tx_byte,
  output reg       tx_busy,
  output reg       tx
);

  localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
  localparam BIT_CNT_MAX  = 10;  // start + 8 data + stop

  reg [13:0] clk_cnt;
  reg [3:0]  bit_idx;
  reg [9:0]  shifter;

  always @(posedge clk) begin
    if (!resetn) begin
      tx       <= 1'b1;
      tx_busy  <= 1'b0;
      clk_cnt  <= 0;
      bit_idx  <= 0;
      shifter  <= 10'b1111111111;
    end else if (tx_start && !tx_busy) begin
      shifter <= {1'b1, tx_byte, 1'b0};
      tx_busy <= 1'b1;
      clk_cnt <= 0;
      bit_idx <= 0;
    end else if (tx_busy) begin
      if (clk_cnt < CLKS_PER_BIT-1) begin
        clk_cnt <= clk_cnt + 1;
      end else begin
        clk_cnt <= 0;
        tx      <= shifter[0];
        shifter <= {1'b1, shifter[9:1]};
        if (bit_idx < BIT_CNT_MAX-1)
          bit_idx <= bit_idx + 1;
        else
          tx_busy <= 1'b0;
      end
    end
  end

endmodule
