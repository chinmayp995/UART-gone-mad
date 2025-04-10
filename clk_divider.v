module clk_divider #(
  parameter CLK_IN       = 100_000_000,  // input clock freq (Hz)
  parameter CLK_OUT      = 1_000_000     // desired output clock freq (Hz)
)(
  input  wire clk_in,
  input  wire resetn,
  output reg  clk_out
);

  // calculate the divide ratio
  localparam integer DIVIDE = CLK_IN / (2 * CLK_OUT);
  integer counter = 0;

  always @(posedge clk_in) begin
    if (!resetn) begin
      counter <= 0;
      clk_out <= 0;
    end else if (counter == DIVIDE-1) begin
      counter <= 0;
      clk_out <= ~clk_out;
    end else begin
      counter <= counter + 1;
    end
  end

endmodule

