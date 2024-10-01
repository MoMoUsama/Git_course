// Code your design here
interface intf( input clk);
  
  logic [7:0] data;
  logic [7:0] addr;
  logic en,wr;
  
  clocking tb_cb @(posedge clk);
    
    default input #5ns output #2ns ;
    input data;
    output en,wr,addr;
  endclocking
  
  // Explicitly include signals in modports
  modport test_bench (clocking tb_cb);  // Testbench modport
  modport dut (input en, wr, addr,clk, output data);      // DUT modport 

  
endinterface

    
//===============================================================//
    
module mem(intf.dut abc);
  
  reg [7:0] arr [255:0];
  
  initial begin
    foreach(arr[i])
      arr[i]=i;
  end
  
  
  always@(*)
    begin
      
      if(abc.en && abc.wr)
        abc.data = arr[abc.addr];
    end
endmodule

//===============================================================//


module tb(intf.test_bench xyz);
  
  initial begin
  #1
  xyz.tb_cb.en <= 1'b1;
  xyz.tb_cb.wr <= 1'b1;
  xyz.tb_cb.addr <= 8'd3;
  
  
  #3
  xyz.tb_cb.addr <= 8'd15;
  #7
  xyz.tb_cb.addr <= 8'd20;
  #5
  xyz.tb_cb.addr <= 8'd22;
  #10
  $finish;
  end
endmodule

//===============================================================//
module top();
  bit clk;
  always #5 clk = !clk;
  
  intf mem_intf (clk);
  mem mem0 (mem_intf.dut);
  tb tb0 (mem_intf.test_bench);
  initial begin
    clk=0;
    $dumpfile("tb.vcd");
    $dumpvars;
  end
endmodule
