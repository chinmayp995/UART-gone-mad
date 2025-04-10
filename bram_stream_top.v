module bram_stream_top #
(
  parameter ADDR_WIDTH = 10,
  parameter DATA_WIDTH = 32,
  parameter CLK_FREQ   = 100_000_000,  // still needed for uart_tx
  parameter BAUD_RATE  = 9600
)
(
  input  wire                   clk,       // 100 MHz
  input  wire                   resetn,
  output wire                   uart_tx
);

  // 1) Generate a 1 MHz clock for the FSM
  wire clk_1MHz;
  clk_divider #(
    .CLK_IN (CLK_FREQ),
    .CLK_OUT(1_000_000)
  ) cd (
    .clk_in (clk),
    .resetn (resetn),
    .clk_out(clk_1MHz)
  );

  // 2) Your BRAM instance (unchanged)
  wire [ADDR_WIDTH-1:0] bram_addr;
  wire [DATA_WIDTH-1:0] bram_data;

  my_bram u_bram (
    .clka   (clk),
    .ena    (1'b1),
    .wea    (1'b0),
    .addra  (bram_addr),
    .dina   ({DATA_WIDTH{1'b0}}),
    .douta  (bram_data)
  );

  // 3) FSM + UART streamer, clocked by clk_1MHz
  bram_to_uart #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .CLK_FREQ   (CLK_FREQ),   // still 100 MHz for UART inside
    .BAUD_RATE  (BAUD_RATE)
  ) streamer (
    .clk       (clk_1MHz),    // <--- slower FSM clock
    .resetn    (resetn),
    .bram_addr (bram_addr),
    .bram_data (bram_data),
    .uart_tx   (uart_tx)
  );

endmodule
