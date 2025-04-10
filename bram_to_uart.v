module bram_to_uart #
(
  parameter ADDR_WIDTH = 10,
  parameter DATA_WIDTH = 32,
  parameter CLK_FREQ   = 100_000_000,
  parameter BAUD_RATE  = 9600
)
(
  input  wire                   clk,
  input  wire                   resetn,    // active-low
  output reg  [ADDR_WIDTH-1:0]  bram_addr,
  input  wire [DATA_WIDTH-1:0]  bram_data,
  output wire                   uart_tx
);

  // UART TX instance
  reg        tx_start;
  reg [7:0]  tx_byte;
  wire       tx_busy;

  uart_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
  ) uart_inst (
    .clk      (clk),
    .resetn   (resetn),
    .tx_start (tx_start),
    .tx_byte  (tx_byte),
    .tx_busy  (tx_busy),
    .tx       (uart_tx)
  );

  // FSM states
  localparam IDLE   = 3'd0,
           ADDR   = 3'd1,  // present address
           WAIT   = 3'd2,  // wait one cycle for bram_data
           SEND   = 3'd3,
           FINISH = 3'd4;

reg [2:0] state, next_state;
reg resetn_d, start_pulse;
reg [ADDR_WIDTH-1:0] addr_cnt;
reg [1:0] byte_cnt;
reg [DATA_WIDTH-1:0] data_reg;

// generate start pulse on resetn rising edge
always @(posedge clk) begin
  resetn_d    <= resetn;
  start_pulse <= resetn & ~resetn_d;
end

// sequential
always @(posedge clk) begin
  if (!resetn) begin
    state     <= IDLE;
    addr_cnt  <= 0;
    bram_addr <= 0;
  end else begin
    state <= next_state;
    if (state == IDLE && start_pulse) begin
      addr_cnt <= 0;
    end
    if (state == ADDR) begin
      bram_addr <= addr_cnt;
    end
    if (state == WAIT) begin
      data_reg <= bram_data;
    end
  end
end

// combinational
always @(*) begin
  next_state = state;
  tx_start   = 1'b0;
  tx_byte    = 8'h00;

  case (state)
    IDLE:
      if (start_pulse) next_state = ADDR;

    ADDR:
      next_state = WAIT;

    WAIT:
      next_state = SEND;

    SEND:
      if (!tx_busy) begin
        // pick byte, start TX
        case (byte_cnt)
          2'd0: tx_byte = data_reg[7:0];
          2'd1: tx_byte = data_reg[15:8];
          2'd2: tx_byte = data_reg[23:16];
          2'd3: tx_byte = data_reg[31:24];
        endcase
        tx_start = 1'b1;
        if (byte_cnt == 2'd3) begin
          if (addr_cnt == {ADDR_WIDTH{1'b1}})
            next_state = FINISH;
          else begin
            addr_cnt   = addr_cnt + 1;
            byte_cnt   = 0;
            next_state = ADDR;
          end
        end else begin
          byte_cnt   = byte_cnt + 1;
          next_state = SEND;
        end
      end

    FINISH:
      next_state = FINISH;
  endcase
end

endmodule
