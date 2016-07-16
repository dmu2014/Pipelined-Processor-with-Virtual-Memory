# Pipelined-Processor-with-Virtual-Memory
Simple Pipelined processor with precise interrupts in Verilog

A simple instruction set pipelined processor with handlers for exceptions and interrupts in verilog.
A virtual memory mapping is done and a TLB module is also added for enabling fast access.
User and kernel modes were well defined and the handler code exploited this feature to enable nested interrupts.
