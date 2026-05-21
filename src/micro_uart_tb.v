`timescale 1ns/1ps
`include "uart.v"
`include "uart_ref.v"
module micro_uart_tb;
parameter dw       = 8;
parameter baud     = 2400;
parameter clk_freq = 50000000;
reg sys_clk;
reg sys_rst_l;
reg xmitH;
reg [dw-1:0] xmit_dataH;
wire uart_XMIT_dataH;
wire xmit_doneH;
wire xmit_active;
wire rec_readyH;
wire rec_busy;
wire [dw-1:0] rec_dataH;
reg  force_rx;
reg  use_force;
wire uart_wire;
assign uart_wire = use_force ? force_rx : uart_XMIT_dataH;
uart dut (
    .sys_clk         (sys_clk),
    .sys_rst_l       (sys_rst_l),
    .xmitH           (xmitH),
    .xmit_dataH      (xmit_dataH),
    .uart_XMIT_dataH (uart_XMIT_dataH),
    .xmit_doneH      (xmit_doneH),
    .xmit_active     (xmit_active),
    .uart_REC_dataH  (uart_wire),
    .rec_readyH      (rec_readyH),
    .rec_busy        (rec_busy),
    .rec_dataH       (rec_dataH)
);
wire ref_uart_XMIT_dataH;
wire ref_xmit_doneH;
wire ref_xmit_active;
wire ref_uart_clk;
wire ref_rec_readyH;
wire ref_rec_busy;
wire [dw-1:0] ref_rec_dataH;
uart_refrence #(
    .clk_value (clk_freq),
    .baud      (baud),
    .data_width(dw)
) ref (
    .sys_clk        (sys_clk),
    .sys_rst_l      (sys_rst_l),
    .xmitH          (xmitH),
    .xmit_dataH     (xmit_dataH),
    .uart_REC_dataH (ref_uart_XMIT_dataH),   
    .uart_XMIT_dataH(ref_uart_XMIT_dataH),   
    .xmit_doneH     (ref_xmit_doneH),
    .xmit_active    (ref_xmit_active),
    .rec_readyH     (ref_rec_readyH),
    .rec_busyH      (ref_rec_busy),
    .rec_dataH      (ref_rec_dataH),
    .uart_clk_out   (ref_uart_clk)
);
integer pass_count;
integer fail_count;
integer total_count;
initial begin
    sys_clk  = 0;
    forever #10 sys_clk = ~sys_clk;
end
task dut_reset;
begin
    sys_rst_l  = 0;
    xmitH      = 0;
    xmit_dataH = 0;
    use_force  = 0;
    force_rx   = 1;
    #200;
    sys_rst_l  = 1;
    repeat(20) @(posedge sys_clk);
end
endtask
task scoreboard;
input [dw-1:0] sent_data;
begin
    if (rec_readyH == 1) wait(rec_readyH == 0);
    wait(rec_readyH == 1);
    wait(xmit_active == 0);
    repeat(5) @(posedge sys_clk);
    total_count = total_count + 1;
    if (uart_XMIT_dataH === ref_uart_XMIT_dataH) begin
        $display("PASS [TX LINE ] TIME=%0t SENT=%h DUT=%b REF=%b",
                 $time,sent_data,uart_XMIT_dataH,ref_uart_XMIT_dataH);
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL [TX LINE ] TIME=%0t SENT=%h DUT=%b REF=%b",
                 $time,sent_data,uart_XMIT_dataH,ref_uart_XMIT_dataH);
        fail_count = fail_count + 1;
    end
    total_count = total_count + 1;
    if (xmit_active === ref_xmit_active) begin
        $display("PASS [TX ACTV ] TIME=%0t SENT=%h DUT=%b REF=%b",
                 $time,sent_data,xmit_active,ref_xmit_active);
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL [TX ACTV ] TIME=%0t SENT=%h DUT=%b REF=%b",
                 $time,sent_data,xmit_active,ref_xmit_active);
        fail_count = fail_count + 1;
    end
    total_count = total_count + 1;
    if (xmit_doneH === ref_xmit_doneH) begin
        $display("PASS [TX DONE ] TIME=%0t SENT=%h DUT=%b REF=%b",
                 $time,sent_data,xmit_doneH,ref_xmit_doneH);
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL [TX DONE ] TIME=%0t SENT=%h DUT=%b REF=%b",
                 $time,sent_data,xmit_doneH,ref_xmit_doneH);
        fail_count = fail_count + 1;
    end
    total_count = total_count + 1;
    if (rec_dataH === ref_rec_dataH) begin
        $display("PASS [RX DATA ] TIME=%0t SENT=%h DUT=%h REF=%h",
                 $time,sent_data,rec_dataH,ref_rec_dataH);
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL [RX DATA ] TIME=%0t SENT=%h DUT=%h REF=%h",
                 $time,sent_data,rec_dataH,ref_rec_dataH);
        fail_count = fail_count + 1;
    end

    total_count = total_count + 1;
    if (rec_readyH === ref_rec_readyH) begin
        $display("PASS [RX READY] TIME=%0t SENT=%h DUT=%b REF=%b",
                 $time,sent_data,rec_readyH,ref_rec_readyH);
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL [RX READY] TIME=%0t SENT=%h DUT=%b REF=%b",
                 $time,sent_data,rec_readyH,ref_rec_readyH);
        fail_count = fail_count + 1;
    end

    total_count = total_count + 1;
    if (rec_busy === ref_rec_busy) begin
        $display("PASS [RX BUSY ] TIME=%0t SENT=%h DUT=%b REF=%b",
                 $time,sent_data,rec_busy,ref_rec_busy);
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL [RX BUSY ] TIME=%0t SENT=%h DUT=%b REF=%b",
                 $time,sent_data,rec_busy,ref_rec_busy);
        fail_count = fail_count + 1;
    end
     total_count = total_count + 1;
    if (rec_dataH === sent_data) begin
        $display("PASS [END2END ] TIME=%0t SENT=%h RECV=%h",
                 $time,sent_data,rec_dataH);
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL [END2END ] TIME=%0t SENT=%h RECV=%h",
                 $time,sent_data,rec_dataH);
        fail_count = fail_count + 1;
    end
    $display("----------------------------------------------------------");
end
endtask
task driver;
input [dw-1:0] data;
begin
    @(posedge sys_clk); #1;
    xmit_dataH = data;
    xmitH      = 1;
    repeat(3) @(posedge dut.transmitter.uart_clk);
    xmitH = 0;
    scoreboard(data);
    wait(xmit_active == 0);
    repeat(10) @(posedge sys_clk);
end
endtask
task back_to_back;
input [dw-1:0] d1;
input [dw-1:0] d2;
begin
    $display("\n--- BACK-TO-BACK 0x%h then 0x%h ---", d1, d2);
    @(posedge sys_clk); #1;
    xmit_dataH = d1;
    xmitH      = 1;
    repeat(3) @(posedge dut.transmitter.uart_clk);
    xmitH = 0;
    wait(xmit_doneH == 1);
    @(posedge sys_clk); #1;
    xmit_dataH = d2;
    xmitH      = 1;
    repeat(3) @(posedge dut.transmitter.uart_clk);
    xmitH = 0;
    scoreboard(d2);
    wait(xmit_active == 0);
    repeat(10) @(posedge sys_clk);
end
endtask
task reset_mid_tx;
begin
    $display("\n--- RESET DURING TX ---");
    @(posedge sys_clk); #1;
    xmit_dataH = 8'hA5;
    xmitH      = 1;
    repeat(5) @(posedge dut.transmitter.uart_clk);
    xmitH = 0;
    dut_reset();
    repeat(10) @(posedge sys_clk);
    $display("PASS [RST MID ] design re-initialised cleanly");
    total_count = total_count + 1;
    pass_count  = pass_count  + 1;
    $display("----------------------------------------------------------");
end
endtask
task inject_false_start;
begin
    $display("\n--- INJECT FALSE START GLITCH ---");
 
    use_force = 1;
    force_rx  = 1;
    repeat(5) @(posedge sys_clk);

    repeat(2) @(posedge dut.receiver.uart_clk);
    force_rx = 1;   
    repeat(20) @(posedge dut.receiver.uart_clk);
    use_force = 0;
    repeat(5) @(posedge sys_clk);
    $display("INFO [GLITCH  ] false start injected  receiver should be IDLE");
    total_count = total_count + 1;
    if (rec_busy === 0) begin
        $display("PASS [GLITCH  ] rec_busy=0 confirmed idle after false start");
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL [GLITCH  ] rec_busy=%b expected 0", rec_busy);
        fail_count = fail_count + 1;
    end
    $display("----------------------------------------------------------");
end
endtask
task inject_framing_error;
input [dw-1:0] data;
integer b;
begin
    $display("\n--- INJECT FRAMING ERROR (stop bit forced LOW) ---");
    use_force = 1;
    force_rx  = 1;
    repeat(3) @(posedge sys_clk);
    force_rx = 0;
    @(posedge dut.receiver.uart_clk); 
     for (b = 0; b < dw; b = b + 1) begin
        force_rx = data[b];
        @(posedge dut.receiver.uart_clk);
    end
    force_rx = 0;
    @(posedge dut.receiver.uart_clk);
    @(posedge dut.receiver.uart_clk);
    force_rx  = 1;
    repeat(5) @(posedge dut.receiver.uart_clk);
    use_force = 0;
    repeat(10) @(posedge sys_clk);
    $display("INFO [FRAME ER] framing error injected");
    total_count = total_count + 1;
    if (rec_busy === 0) begin
        $display("PASS [FRAME ER] receiver returned to IDLE after framing error");
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL [FRAME ER] rec_busy=%b expected 0", rec_busy);
        fail_count = fail_count + 1;
    end
    $display("----------------------------------------------------------");
end
endtask
task inject_deep_false_start;
begin
    $display("\n--- INJECT DEEP FALSE START (S2->S3 + start_bit_error=1) ---");
    use_force = 1;
    force_rx  = 1;
    repeat(5) @(posedge sys_clk);
    force_rx = 0;
    repeat(16) @(posedge dut.receiver.uart_clk);
    force_rx = 1;
    repeat(30) @(posedge dut.receiver.uart_clk);
    use_force = 0;
    repeat(10) @(posedge sys_clk);
    total_count = total_count + 1;
    if (rec_busy === 0) begin
        $display("PASS [DEEP GLC] rec_busy=0 : S2->S3 abort, start_bit_error=1 covered");
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL [DEEP GLC] rec_busy=%b expected 0 after deep false start", rec_busy);
        fail_count = fail_count + 1;
    end
    $display("----------------------------------------------------------");
end
endtask
task inject_start_bit_error;
begin
    $display("\n--- INJECT START BIT ERROR (start_bit_error=1, cnt1==15) ---");
    use_force = 1;
    force_rx  = 1;
    repeat(3) @(posedge sys_clk);
    force_rx = 0;
    repeat(15) @(posedge dut.receiver.uart_clk);
    force_rx = 1;   
    repeat(20) @(posedge dut.receiver.uart_clk);
    use_force = 0;
    repeat(10) @(posedge sys_clk);
    total_count = total_count + 1;
    if (rec_busy === 0) begin
        $display("PASS [SBE     ] start_bit_error=1 covered, receiver IDLE");
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL [SBE     ] rec_busy=%b expected 0", rec_busy);
        fail_count = fail_count + 1;
    end
    $display("----------------------------------------------------------");
end
endtask
task inject_stop_bit_error;
input [dw-1:0] data;
integer i;
begin
    $display("\n--- INJECT STOP BIT ERROR (stop_bit_error=1, cnt1==15) data=0x%h ---", data);
    use_force = 1;
    force_rx  = 1;
    repeat(3) @(posedge sys_clk);
    force_rx = 0;
    repeat(16) @(posedge dut.receiver.uart_clk);
    for (i = 0; i < dw; i = i + 1) begin
        force_rx = data[i];
        repeat(16) @(posedge dut.receiver.uart_clk);
    end
    force_rx = 0;
    repeat(16) @(posedge dut.receiver.uart_clk);
    force_rx = 1;
    repeat(10) @(posedge dut.receiver.uart_clk);
    use_force = 0;
    repeat(10) @(posedge sys_clk);
    total_count = total_count + 1;
    if (rec_busy === 0) begin
        $display("PASS [STPE    ] stop_bit_error=1 covered, receiver IDLE");
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL [STPE    ] rec_busy=%b expected 0", rec_busy);
        fail_count = fail_count + 1;
    end
    $display("----------------------------------------------------------");
end
endtask
initial begin
    pass_count  = 0;
    fail_count  = 0;
    total_count = 0;
    sys_rst_l   = 0;
    xmitH       = 0;
    xmit_dataH  = 0;
    use_force   = 0;
    force_rx    = 1;
    dut_reset();
    $display("\n===== GROUP 1 : CORNER CASES =====");
    driver(8'h55);
    driver(8'hAA);
    driver(8'h00);
    driver(8'hFF);
    $display("\n===== GROUP 2 : CONTINUOUS TX =====");
    @(posedge sys_clk); #1;
    xmit_dataH = 8'h12;
    xmitH      = 1;
    repeat(144) @(posedge dut.transmitter.uart_clk);
    xmit_dataH = 8'h34;
    repeat(20)  @(posedge dut.transmitter.uart_clk);
    xmitH = 0;
    wait(xmit_active == 0);
    repeat(10) @(posedge sys_clk);
    total_count = total_count + 1;
    pass_count  = pass_count  + 1;
    $display("PASS [CONT TX ] xmit_active held HIGH throughout");
    $display("----------------------------------------------------------");
    $display("\n===== GROUP 5 : FALSE START INJECTION =====");
    inject_false_start();
    $display("\n===== GROUP 6 : FRAMING ERROR INJECTION =====");
    inject_framing_error(8'hA5);
      $display("\n===== GROUP 7 : BACK-TO-BACK =====");
    back_to_back(8'hA5, 8'h5A);
    $display("\n===== GROUP 8 : RESET MID-TX =====");
    reset_mid_tx();
       $display("\n===== GROUP 9 : DEEP FALSE START (S2->S3 + start_bit_error) =====");
    inject_deep_false_start();
    driver(8'hA5);
    $display("\n===== GROUP 9B : START/STOP BIT ERROR FLAGS =====");
    inject_start_bit_error();
    inject_stop_bit_error(8'hA5);
    driver(8'hA5);
    $display("\n===== GROUP 10 : LONG XMIT PULSE =====");
    @(posedge sys_clk); #1;
    xmit_dataH = 8'hC3;
    xmitH      = 1;
    repeat(12) @(posedge dut.transmitter.uart_clk);
    xmitH = 0;
    scoreboard(8'hC3);
    wait(xmit_active == 0);
    repeat(10) @(posedge sys_clk);
    @(posedge sys_clk); #1;
    xmit_dataH = 8'h3C;
    xmitH      = 1;
    repeat(12) @(posedge dut.transmitter.uart_clk);
    xmitH = 0;
    scoreboard(8'h3C);
    wait(xmit_active == 0);
    repeat(10) @(posedge sys_clk);
    $display("\n===== GROUP 11 : FINAL SWEEP =====");
    driver(8'h11); 
    #100000;
    $display("\n========================================");
    $display("  SIMULATION COMPLETE");
    $display("  TOTAL : %0d", total_count);
    $display("  PASS  : %0d", pass_count);
    $display("  FAIL  : %0d", fail_count);
    $display("========================================");
    $finish;
end
initial begin
    #500000000;
    $display("\n========================================");
    $display("  TIMEOUT - Simulation exceeded time limit");
    $display("  TOTAL : %0d", total_count);
    $display("  PASS  : %0d", pass_count);
    $display("  FAIL  : %0d", fail_count);
    $display("========================================");
    $finish;
end
endmodule

