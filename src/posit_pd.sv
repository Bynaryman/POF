import posit_defines::*;

interface pd #(
    parameter integer POSIT_WIDTH = 16,
    parameter integer POSIT_ES = 1,
    parameter pd_type PD_TYPE = NORMAL
);

    function integer get_scale_width(input pd_type pdt);
        case(pdt)
            AADD: begin
                return (`GET_SCALE_WIDTH(POSIT_WIDTH, POSIT_ES, 0));
            end
            AMULT: begin
                return (`GET_SCALE_WIDTH(POSIT_WIDTH, POSIT_ES, 1));
            end
   
            NORMAL: begin
                return (`GET_SCALE_WIDTH(POSIT_WIDTH, POSIT_ES, 0));
            end
            default: begin
                return 0;
            end  
        endcase
    endfunction
    
    function integer get_fraction_width(input pd_type pdt);
        case(pdt)
               AADD: begin
                   return (`GET_FRACTION_WIDTH(POSIT_WIDTH, POSIT_ES, 0)) + 3; // for the GRS, the last bit will contin information about all lost LSBs ("it sticks")
               end
               AMULT: begin
                   return (`GET_FRACTION_WIDTH(POSIT_WIDTH, POSIT_ES, 1));
               end
      
               NORMAL: begin
                   return (`GET_FRACTION_WIDTH(POSIT_WIDTH, POSIT_ES, 0));
               end
               default: begin
                   return 0;
               end  
           endcase
    endfunction
    


    localparam integer scale_width    = get_scale_width(PD_TYPE);
    localparam integer fraction_width = get_fraction_width(PD_TYPE);
    
    logic signed [scale_width-1:0]  scale;
    logic [fraction_width-1:0] fraction;
    logic NaR;
    logic sign;
    logic zero;
    // GRS
    logic guard;
    logic round;
    logic sticky;

    modport slave  ( input scale, input fraction, input NaR, input sign, input zero, input guard, input round, input sticky);
    modport master ( output scale, output fraction, output NaR, output sign, output zero, output guard, output round, output sticky);
endinterface
