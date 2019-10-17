interface pd_control_if #(
    parameter integer POSIT_WIDTH = 16,
    parameter integer POSIT_ES = 1,
    parameter pd_type PD_TYPE = NORMAL
)();

    localparam integer scale_width    = get_scale_width(POSIT_WIDTH, POSIT_ES, PD_TYPE);
    localparam integer fraction_width = get_fraction_width(POSIT_WIDTH, POSIT_ES, PD_TYPE);

    // Control
    logic rts;
    logic rtr;
    logic sow;
    logic eow;
    
    // Data
    logic signed [scale_width-1:0]  scale;
    logic [fraction_width-1:0] fraction;
    logic NaR;
    logic sign;
    logic zero;
    logic guard;
    logic round;
    logic sticky;   

    modport slave  (  input rts, output rtr, input sow, input eow, input scale,
                      input fraction, input NaR, input sign, input zero,
                      input guard, input round, input sticky );
    modport master (  output rts, input rtr, output sow, output eow,
                      output scale, output fraction, output NaR, output sign,
                      output zero, output guard, output round, output sticky);
endinterface
